# Internship Hours Log

**Intern:** Ian
**Organization:** Cascade STEAM Service Corps
**Role:** Technology Intern
**Course:** CIS190 6001, Summer 2026 (5 credits, 165 hours)
**Supervisor:** Garth Johnson
**Placement approved:** 2026-07-30
**Completion deadline:** week of 2026-08-19

## How to use this file

Add one row per work session, same day it happens. Keep rows in date order.

- **Date** — ISO format (`2026-08-03`) so rows sort correctly
- **Start / End** — 24h local time (`13:00`, `17:30`). Leave blank only if genuinely unknown
- **Hrs** — decimal, quarter-hour granularity (`1.0`, `2.25`, `3.5`)
- **Category** — one of: `Onboarding`, `Workstation`, `Backup`, `Infrastructure`, `HelpDesk`, `Documentation`, `Meeting`, `OnSite`, `Admin`
- **Outcome** — which learning outcome this supports (1–5), or `-` if none
- **Activity** — what you did and what came out of it. Name the system, the fault, and the result. "Troubleshot printer" is weak; "Traced P1S dropped-print status to MQTT session contention, moved Bambuddy to Print Queue mode, verified clean captures" is evidence

### Learning outcome reference

| # | Outcome |
|---|---------|
| 1 | Help Desk and Client Support |
| 2 | Cybersecurity |
| 3 | Systems and Infrastructure Deployment |
| 4 | Networking and Hardware Troubleshooting |
| 5 | Technical Documentation |

---

## Running total

| | Hours |
|---|---|
| Logged to date | 43.05 |
| Rows pending hours (onboarding, interview, OS install, pre-migration backup, meetings) | TBD |
| **Total** | **TBD** |
| Target | 165.00 |
| **Remaining** | **TBD** |

Update this block whenever you add rows.

---

## June 2026

| Date | Start | End | Hrs | Category | Outcome | Activity |
|------|-------|-----|-----|----------|---------|----------|
| | | | | Onboarding | - | Internship interview with Cascade STEAM: role scope, expectations, project areas |
| | | | | Onboarding | - | Organization orientation, introduction to community groups and project areas, access and account provisioning |

## July 2026

| Date | Start | End | Hrs | Category | Outcome | Activity |
|------|-------|-----|-----|----------|---------|----------|
| | | | | Workstation | 3 | Pre-migration backup: backed up existing system and personal files off the Fedora installation prior to wiping the workstation |
| | | | | Workstation | 3 | Ubuntu (Lubuntu) acquisition and installation: downloaded ISO, verified and wrote installation media, partitioned, installed the OS |
| 2026-07-09 | | | 0.50 | Workstation | 3 | Installed Obsidian (non-snap .deb), WireGuard tools, cloned CascadeSTEAM/csdocs documentation repository |
| 2026-07-11 | | | 4.00 | Workstation | 3, 4 | Application stack reinstall (VS Code, Bitwarden client, RustDesk, Docker, LibreOffice, Wireshark, fish, CIFS mounts). Diagnosed Vaultwarden inaccessibility across firewall, certificate trust, and three separate Ubuntu trust stores (system, NSS, Firefox snap sandbox); root cause was a Bitwarden client/server version incompatibility, resolved by updating Vaultwarden. Identified and worked around VLAN 25 LXC DNS misconfiguration during the update |
| 2026-07-13 | | | 0.50 | Infrastructure | 4 | RustDesk self-hosted server key mismatch: retrieved server public key from inside the LXC, identified dropped base64 padding character from GUI paste, corrected client config via sed |
| 2026-07-13 | | | 0.25 | Admin | - | Professional introduction and bio for internship onboarding |
| 2026-07-14 | | | 1.00 | Admin | - | Career Connect application revisions: adjusted scheduled hours to 165 for 5 credits, drafted five learning outcomes scoped to nonprofit MSP client-facing work |
| 2026-07-17 | | | 1.50 | Workstation | 3 | Development environment: VS Code from Microsoft apt repo, Python 3 with pip and venv, Arduino IDE with dialout group config, Git with global identity and SSH keys, GitHub CLI, OpenCode CLI |
| 2026-07-20 | | | 2.50 | Backup | 3, 5 | RESEARCH: backup tooling evaluation. Compared rsync, dd, tar+gzip, restic, and Proxmox Backup Server against the requirement for automated off-site-capable laptop backup. Studied 3-2-1 strategy, append-only repository design, deduplication and snapshot models, and why image-level tools create temp files that can worsen a failure. Ruled out PBS (Debian-only server, NAS runs Ubuntu 24.04); selected restic rest-server with the repo local to the RAID1 array |
| 2026-07-20 | | | 3.00 | Backup | 3, 4 | RESEARCH: overlay VPN and mesh networking. Studied mesh vs hub-and-spoke topologies, compared Netbird against Tailscale and plain WireGuard, learned Netbird's model of routing peers, network resources, access policies, and setup keys. Established why inbound WireGuard on the router is unreliable here (double-NAT with dynamic WAN address behind an upstream device) and why an outbound-brokered overlay solves it |
| 2026-07-21 | | | 0.50 | Admin | - | Task planning and prioritization for the week's placement work |
| 2026-07-20/24 | | | 8.00 | Backup | 3, 4 | IMPLEMENTATION: deployed restic rest-server on the N100 NAS, repo on the 14TB RAID1. Enrolled Netbird agents on NAS and laptop. Rebuilt LXC 110 on pve-svc as the Netbird routing peer, replacing the Tailscale subnet router; retired CT 200 on pve-lab to keep the adversary-simulation host off the production mesh. Configured Gitea SSH on port 2222 with a dedicated ed25519 key. Root-caused a week-long remote access failure to a RouterOS IPv6 neighbor-discovery entry advertising the router as an IPv6 gateway with no IPv6 upstream, causing clients to install default v6 routes into a black hole; fix applied and verified. Configured Netbird Networks to expose internal services remotely; verified backup from two foreign networks (26.9 GiB, exit 0) |
| 2026-07-26 | | | 0.50 | Infrastructure | 2, 3 | Vaultwarden remote access: Netbird policy port additions for LXC 101 |
| 2026-07-28 | | | 1.50 | Workstation | 3, 5 | Rebuild strategy: captured apt, snap, and flatpak package manifests; audited a 1,400-line dpkg selections dump to separate user-installed packages from desktop metapackage dependencies; identified deinstall tombstones and dual HWE kernel stacks that must not transfer; built a curated reinstall set with third-party repo and keyring re-adds for a restore-as-VM sequence |
| 2026-07-28 | | | 2.00 | Documentation | 5 | Backup playbook: wrote the restore procedure, manifest capture steps, and verification diff process |
| 2026-07-28 | | | 3.00 | Infrastructure | 4, 5 | Jellyfin outage triage: ruled out Jellyfin, DNS, and Caddy config before root-causing asymmetric routing on the NAS, where an advertised Netbird network route sent reply traffic into the tunnel while the request arrived over the LAN; applied an ip rule fix. Separately found and closed a MikroTik forward chain gap where the Infrastructure VLAN had no accept rule. Updated Vaultwarden past a version mismatch, working around the VLAN 25 DNS timeout. Wrote and pushed the July infrastructure changelog to Gitea |
| 2026-07-29 | 23:00 | 23:55 | 0.90 | Infrastructure | 2, 3 | Wildcard certificate planning: researched ACME DNS-01, Cloudflare API token scoping, and the Caddy cloudflare DNS provider module. Registered spills.beer, configured the Cloudflare zone, created a token scoped to Zone.DNS.Edit and Zone.Zone.Read for a single zone |
| 2026-07-30 | 00:00 | 02:30 | 2.50 | Infrastructure | 2, 3, 5 | Wildcard certificate implementation: built a custom Caddy binary with the cloudflare module via xcaddy (required manual Go 1.23 install over Bookworm's 1.19 and an LXC disk resize from 4G to 8G), rewrote the Caddyfile migrating 18 services from .lan to .spills.beer under one wildcard block, moved the API token to a mode-600 systemd environment file, added a MikroTik regexp static DNS entry, verified a valid Let's Encrypt certificate end to end, removed the 18 obsolete .lan DNS entries. Produced the migration report, sanitized config files, and build script for version control |
| 2026-07-30 | 01:00 | 01:52 | 0.90 | Infrastructure | 2, 3, 4, 5 | Off-network DNS troubleshooting for *.spills.beer over Netbird. Traced two stacked root causes: (1) the Netbird DNS Nameserver pointed at 192.168.10.1 with no advertised route, so tunneled queries had no path — fixed by adding 192.168.10.1/32 as a routed network resource via netbird-gw with a matching access policy; (2) the MikroTik input chain only accepted DNS on `in-interface-list=LAN`, silently dropping tunneled queries from the Infrastructure VLAN — fixed with explicit accept rules for 192.168.25.0/24 on UDP/TCP 53. Verified `resolvectl query` resolving via wt0 and `curl -I` returning HTTP/2 200 from two unrelated off-network WiFi networks. Wrote the addendum documenting both root causes |
| | | | | Meeting | - | In-person meeting (location, attendees, topics) |
| | | | | Meeting | - | Virtual meeting (platform, attendees, topics) |
| | | | | OnSite | - | On-site work session, Bellingham Makerspace (project and deliverable) |

## August 2026

| Date | Start | End | Hrs | Category | Outcome | Activity |
|------|-------|-----|-----|----------|---------|----------|
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |
| | | | | | | |

---

## Notes

- July entries were reconstructed from terminal session logs and infrastructure changelogs after the fact. Hours for those rows are estimates except where start and end times are recorded. August entries onward are logged same-day.
- Research rows are logged separately from implementation rows. Time spent studying tooling and architecture before building is placement work and is not folded into the deployment hours.
- The homelab is the placement work environment, so Proxmox, LXC, container, and network work counts as placement work rather than personal projects.
