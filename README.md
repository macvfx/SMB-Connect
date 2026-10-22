# SMB Connect

`v0.7.8` current beta · `macOS 14+` · `SwiftUI` · `Menu Bar + Dock Utility`

SMB Connect mounts SMB shares on macOS with awareness of preferred, fallback, and remote-reachability network paths such as `10GbE`, `1GbE`, `25GbE`, `100GbE`, and VPN/custom endpoints.



| | |
|---|---|
| **SMB Connect** | Mount authority; menu bar by default, with optional Dock icon and resizable window |


Same shares and settings. When both are installed, Desktop asks the original SMB Connect app to mount shares, so the original app remains the only Keychain and mounting authority.

## Release Highlights

Newest first. SMB Connect is designed for environments where users regularly connect to
multiple storage targets, and each release works towards that.


- *NEW* v0.7.8 beta (build 35) -- FIXED: Connect All button works now. 


## Documentation

- **[Quick Start](SMB-CONNECT-QUICK-START.md)** — a concise three-page setup and daily-use guide
- **[Quick Start (PDF)](SMB-CONNECT-QUICK-START.pdf)** — printable three-page edition
- **[User Guide](USER-GUIDE.md)** — setup, getting started, every feature, and troubleshooting
- **[User Guide (PDF)](USER-GUIDE.pdf)** — the same guide as a printable download
- **[CopyTrust two-volume MDM workflow](COPYTRUST-TWO-VOLUME-MDM-WORKFLOW.md)** — generate, validate, deploy, and test required destinations
- **[CopyTrust integration contract](COPYTRUST-SMB-CONNECT-INTEGRATION.md)** — separation of responsibilities and tested Swift client

Help is built in as well: press `?` in the menu bar popup, use **Help** in SMB
Connect Desktop's menu bar, or open **Settings → Help → Getting Started**, for a
Quick Start and an Advanced section.

## What The App Does

- Configures shares by alias, share name, mount name, and one or more IP-based network paths
- Detects active local networks and selects the best reachable configured path, including endpoints reachable only over a VPN or routed network (tagged `(via VPN)`)
- Mounts SMB shares through macOS using stored user credentials
- Shows connection state in the menu bar popover with per-share status cards, or in SMB Connect Desktop's window with a share list beside a full detail pane
- Warns when the Mac is on Wi-Fi with no wired path, since shares mount over Wi-Fi perfectly well and simply run far slower than the wired path they are configured for
- Connects all ready shares in one click (`Connect All`, `⌘K`) or automatically on app start
- Auto-reconnects dropped shares when the server is still reachable, with stale mount cleanup and a 60-second cooldown; a share is never disconnected until a saved password and a reachable path are both in hand, so a reconnect that cannot succeed leaves the working mount alone
- Moves a share back onto its preferred network with `Switch to Preferred`, which disconnects it and mounts it once — offered only when the preferred path really is the one that will be used, and always after confirmation
- Records what it does to the macOS system log: connection state changes, the network path chosen for each share, and every mount and unmount along with what asked for it — including the ones macOS performs itself, which is what distinguishes the app disconnecting a share from the network dropping it
- Exports a diagnostics report from Settings — the recent log with the configured shares, live network interfaces and current mount table in one file, containing no passwords and no account names
- Detects duplicate mounts such as `Video` and `Video-1`
- Reads mount ownership from the system mount table, so a share held by another logged-in user is named rather than mistaken for a stale folder or for one of your own mounts
- Recognises when one server has been mounted through two different addresses — its IP and its Bonjour `.local` name — which macOS treats as two separate volumes
- Limits mount detection to genuine network shares under `/Volumes`, so macOS system and autofs volumes (for example the `auto_home` map named `home`) no longer trigger a false "Mounted Wrong" / duplicate state
- Posts a quiet macOS notification when a share newly needs attention, instead of relying on the popup alone
- Detects `/Volumes` name conflicts before mounting and blocks risky connects
- Marks each share with a status icon — connected, ready, unreachable, needs credentials, needs repair, or blocked — with the wording on hover and for VoiceOver
- Provides in-app help (`?` in the menu, or Settings → Help) with a Quick Start and an Advanced section
- Checks GitHub for newer releases on demand and quietly once a day; it compares version numbers only, installs nothing itself, and sends no device or share information
- Exports and imports JSON configuration files
- Reads managed share definitions from an MDM profile

## Configuration Priority

Configuration is layered in this order:

1. MDM-managed share definitions
2. Setup JSON files in `~/Library/Application Support/SMBConnect/Setup/`
3. Imported JSON files from the app UI
4. User-edited local settings
5. User-specific credentials in Keychain

MDM and JSON can preload share names, IPs, preferred network order, and default usernames.
Passwords are intentionally user-local and are not stored in JSON or MDM.


## Included Example Configuration

This repo includes public sample inputs and a generator for creating valid SMB Connect setup JSON and matching `.mobileconfig` profiles.

The generator script is here:

- [generate_smbconnect_config.sh](generate_smbconnect_config.sh)
- [mount_to_smbconnect_config.sh](mount_to_smbconnect_config.sh)
- [json_to_mobileconfig.sh](json_to_mobileconfig.sh) — convert an existing setup JSON into an MDM `.mobileconfig`
- [validate_copytrust_mdm_profile.sh](validate_copytrust_mdm_profile.sh) — require exact, unique, opted-in CopyTrust Mount Names
- [test_copytrust_mdm_tooling.sh](test_copytrust_mdm_tooling.sh) — regression-test the public generators and validator

Generator usage is documented here:

- [README-config-generator.md](README-config-generator.md)
- [README-mount-import.md](README-mount-import.md)
- [README-json-to-mobileconfig.md](README-json-to-mobileconfig.md)
- [CopyTrust MDM deployment plan](COPYTRUST-MDM-DEPLOYMENT-PLAN.md)

*EXTRA:* a small macOS SwiftUI companion app named **Mount Import Assistant** for the same mounted-share import workflow. Use the app or the portable shell scripts.

The tested CopyTrust reference client is in [examples/CopyTrustSMBConnectClient](examples/CopyTrustSMBConnectClient).

For endpoint planning, use the FASTEST local path first: prefer the fastest reachable local network such as `10GbE`, fall back to slower local paths such as `1GbE`, and use VPN/WireGuard/Tailscale addresses as remote reachability or fallback paths unless a device is intentionally VPN-only.

External inventory handoff files are here:

- [DEVICE-INVENTORY-TEMPLATE.md](DEVICE-INVENTORY-TEMPLATE.md)
- [device-inventory-template.csv](examples/device-inventory-template.csv)
- [device-inventory-example.csv](examples/device-inventory-example.csv)
- [SITE-DEVICE-LIST-TEMPLATE.md](SITE-DEVICE-LIST-TEMPLATE.md)
- [site-device-list-template.csv](examples/site-device-list-template.csv)
- [site-device-list-example.csv](examples/site-device-list-example.csv)

Additional sample inputs are here:

- [server-shares-example.csv](examples/server-shares-example.csv)
- [server-shares-example.txt](examples/server-shares-example.txt)
- [mount-output-example.txt](examples/mount-output-example.txt)

## License

Free to use for your own business or work, including on client jobs. You may not sell,
redistribute or sublicense the software. The terms are the
[PolyForm Internal Use License 1.0.0](LICENSE). Copies obtained earlier under Apache-2.0 keep that license.
