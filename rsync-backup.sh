#!/bin/bash
set -euo pipefail

# --- config ---
SRC="/home /etc /root"
LAN_IP="192.168.20.11"
NETBIRD_IP="100.72.245.239"   # N100's Netbird IP
SSH_USER="ian"
IDENTITY="/home/ian/.ssh/id_restic"
DEST_BASE="/mnt/backups/rsync-laptop"
EXCLUDE_FILE="/etc/rsync-backup-excludes.txt"
LOGFILE="/var/log/rsync-backup.log"
LOCKFILE="/var/lock/rsync-backup.lock"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# --- GFS retention tiers ---
KEEP_ALL_HOURS=48        # keep every 3-hourly run within this window
KEEP_DAILY_DAYS=10       # one per day out to here
KEEP_WEEKLY_WEEKS=6      # one per ISO week out to here
KEEP_MONTHLY_MONTHS=6    # one per month out to here; older is deleted

# --- logging helper ---
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOGFILE"; }

# --- single-instance lock: bail if another run holds it ---
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    log "another backup is already running, exiting"
    exit 1
fi

START_EPOCH=$(date +%s)
COMPLETED=""
NEW_SNAP=""
DEST_HOST=""
SSH_OPTS=""

# --- cleanup trap: remove a partial snapshot if we exit before finishing ---
cleanup() {
    local rc=$?
    if [ -n "$NEW_SNAP" ] && [ -z "$COMPLETED" ] && [ -n "$DEST_HOST" ]; then
        log "interrupted or failed (rc=${rc}) — removing partial snapshot ${NEW_SNAP}"
        ssh $SSH_OPTS "$DEST_HOST" "rm -rf ${NEW_SNAP}" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# --- pick fastest available path to the N100 ---
if ssh -o ConnectTimeout=2 -o BatchMode=yes -i "$IDENTITY" "${SSH_USER}@${LAN_IP}" true 2>/dev/null; then
    DEST_IP="$LAN_IP"
    log "on LAN, using direct IP ${LAN_IP}"
else
    DEST_IP="$NETBIRD_IP"
    log "not on LAN, using Netbird IP ${NETBIRD_IP}"
fi
DEST_HOST="${SSH_USER}@${DEST_IP}"
SSH_OPTS="-i ${IDENTITY}"

NEW_SNAP="${DEST_BASE}/${TIMESTAMP}"
LATEST_LINK="${DEST_BASE}/latest"

# --- skip-if-unchanged check ---
if ssh $SSH_OPTS "$DEST_HOST" "[ -e ${LATEST_LINK} ]"; then
    LAST_RUN_EPOCH=$(ssh $SSH_OPTS "$DEST_HOST" "stat -c %Y ${LATEST_LINK}")
    CHANGED=$(find $SRC -type f -newermt "@${LAST_RUN_EPOCH}" 2>/dev/null | head -1 || true)
    if [ -z "$CHANGED" ]; then
        log "no changes since last snapshot, skipping run"
        COMPLETED=1   # a skip is a clean exit, don't trigger partial cleanup
        exit 0
    fi
fi

# --- find previous snapshot to hard-link against ---
PREV_SNAP=""
if ssh $SSH_OPTS "$DEST_HOST" "[ -e ${LATEST_LINK} ]"; then
    PREV_SNAP=$(ssh $SSH_OPTS "$DEST_HOST" "readlink -f ${LATEST_LINK}")
fi

# --- build rsync args ---
RSYNC_ARGS=(-az --delete --stats --info=progress2 -e "ssh $SSH_OPTS")
[ -f "$EXCLUDE_FILE" ] && RSYNC_ARGS+=(--exclude-from="$EXCLUDE_FILE")
[ -n "$PREV_SNAP" ] && RSYNC_ARGS+=(--link-dest="$PREV_SNAP")

# --- ensure destination base exists, run backup ---
log "starting backup of ${SRC} -> ${DEST_IP}:${NEW_SNAP}"
ssh $SSH_OPTS "$DEST_HOST" "mkdir -p ${NEW_SNAP}"
rsync "${RSYNC_ARGS[@]}" $SRC "${DEST_HOST}:${NEW_SNAP}/" 2>&1 | tee -a "$LOGFILE"

# --- copy finished cleanly: mark complete so trap won't wipe it ---
COMPLETED=1

# --- update 'latest' pointer (atomic) ---
ssh $SSH_OPTS "$DEST_HOST" "ln -sfn ${NEW_SNAP} ${LATEST_LINK}"
log "updated 'latest' -> ${NEW_SNAP}"

# --- GFS prune ---
PRUNED=$(ssh $SSH_OPTS "$DEST_HOST" \
    "KEEP_ALL_HOURS=${KEEP_ALL_HOURS} KEEP_DAILY_DAYS=${KEEP_DAILY_DAYS} KEEP_WEEKLY_WEEKS=${KEEP_WEEKLY_WEEKS} KEEP_MONTHLY_MONTHS=${KEEP_MONTHLY_MONTHS} DEST_BASE=${DEST_BASE} bash -s" <<'INNEREOF'
cd "$DEST_BASE"
now=$(date +%s)
deleted=0
mapfile -t snaps < <(ls -1d */ 2>/dev/null | sed 's:/$::' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}_' | sort -r)
declare -A seen_day seen_week seen_month
for d in "${snaps[@]}"; do
    [ "$d" = "latest" ] && continue
    ts=$(date -d "${d:0:10} ${d:11:2}:${d:14:2}:${d:17:2}" +%s 2>/dev/null) || continue
    age_h=$(( (now - ts) / 3600 )); age_d=$(( age_h / 24 ))
    if [ "$age_h" -le "$KEEP_ALL_HOURS" ]; then continue; fi
    if [ "$age_d" -le "$KEEP_DAILY_DAYS" ]; then
        key="${d:0:10}"; if [ -n "${seen_day[$key]:-}" ]; then rm -rf "$d"; deleted=$((deleted+1)); else seen_day[$key]=1; fi; continue; fi
    if [ "$age_d" -le $((KEEP_WEEKLY_WEEKS * 7)) ]; then
        key=$(date -d "${d:0:10}" +%G-%V 2>/dev/null); if [ -n "${seen_week[$key]:-}" ]; then rm -rf "$d"; deleted=$((deleted+1)); else seen_week[$key]=1; fi; continue; fi
    if [ "$age_d" -le $((KEEP_MONTHLY_MONTHS * 31)) ]; then
        key="${d:0:7}"; if [ -n "${seen_month[$key]:-}" ]; then rm -rf "$d"; deleted=$((deleted+1)); else seen_month[$key]=1; fi; continue; fi
    rm -rf "$d"; deleted=$((deleted+1))
done
echo "$deleted"
INNEREOF
)
log "prune complete: ${PRUNED} old snapshot(s) removed"

# --- summary ---
SNAP_SIZE=$(ssh $SSH_OPTS "$DEST_HOST" "du -sh ${NEW_SNAP} | cut -f1")
TOTAL_SIZE=$(ssh $SSH_OPTS "$DEST_HOST" "du -sh ${DEST_BASE} | cut -f1")
END_EPOCH=$(date +%s)
ELAPSED=$(( END_EPOCH - START_EPOCH ))
log "backup complete: snapshot ${TIMESTAMP}, this-snap ${SNAP_SIZE}, total-set ${TOTAL_SIZE}, elapsed ${ELAPSED}s"
