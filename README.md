# SMB Connect

`v0.7.5` current beta · `v0.5.5` previous stable · `macOS 14+` · `SwiftUI` · `Menu Bar + Dock Utility`

SMB Connect mounts SMB shares on macOS with awareness of preferred, fallback, and remote-reachability network paths such as `10GbE`, `1GbE`, `25GbE`, `100GbE`, and VPN/custom endpoints.

From v0.7.0 it comes as **two apps**. Download either on its own, or both together:

| | |
|---|---|
| **SMB Connect** | Mount authority; menu bar by default, with optional Dock icon and resizable window |
| **SMB Connect Desktop** | Compatibility client with a Dock icon and resizable window |

Same shares and settings. When both are installed, Desktop asks the original SMB Connect app to mount shares, so the original app remains the only Keychain and mounting authority.

## Download

- **[SMB Connect 0.7.5 (build 28) beta](https://github.com/macvfx/SMB-Connect/releases/tag/0.7.5%2B28)** — current prerelease, three downloads:

| Download | Contains |
|---|---|
| [`SMBConnect.dmg`](https://github.com/macvfx/SMB-Connect/releases/download/0.7.5%2B28/SMBConnect.dmg) | **SMB Connect** — mount authority; menu bar by default, optional Dock icon/window |
| [`SMBConnectDesktop.dmg`](https://github.com/macvfx/SMB-Connect/releases/download/0.7.5%2B28/SMBConnectDesktop.dmg) | **SMB Connect Desktop** — compatibility client with Dock icon and window |
| [`SMBConnect-Both-Apps.dmg`](https://github.com/macvfx/SMB-Connect/releases/download/0.7.5%2B28/SMBConnect-Both-Apps.dmg) | Both, in one image |

Take whichever you want — either app works on its own, and the two are built to
run side by side over one configuration.

Every build is signed with a Developer ID certificate and notarized by Apple. Each
download has a matching `.sha256.txt` in the release you can check it against:

```bash
shasum -a 256 SMBConnect.dmg
```

0.7.5 is newer than the long-standing
[0.5.5](https://github.com/macvfx/SMB-Connect/releases/tag/0.5.5) and has had
less time in daily use, so 0.5.5 remains available if you would rather stay on
it.

## Release Highlights

Newest first. SMB Connect is designed for environments where users regularly connect to
multiple storage targets, and each release works towards that.

- *NEW* v0.7.5 beta (build 28) adds fleet tooling for CopyTrust volume requests. The CSV generator and JSON-to-profile converter preserve each share's default-off approval, and the validator refuses a profile when a required Mount Name is absent, duplicated, or not explicitly enabled.
- *NEW* v0.7.5 beta updates Mount Import Assistant to export the approval in its JSON, CSV, and review report, and includes a tested Swift reference client showing how CopyTrust requests a volume and checks its own folder without receiving credentials or endpoint details.
- *NEW* v0.7.4 beta (build 27) lets another app request a required volume through a versioned `smbconnect://v1/mount` URL using the share's unique **Mount Name**. The request carries no server address, username, or password: SMB Connect resolves the configured share and chooses the best reachable preferred or fallback network path. Each share must explicitly allow requests from other apps.
- *NEW* v0.7.4 beta makes the original SMB Connect app the mounting and Keychain authority. SMB Connect Desktop delegates mount requests to it when available, avoiding a second app asking users to grant or re-enter the same saved passwords. The original app can now optionally show a Dock icon and full window for laptop users who prefer not to spend menu bar space.
- *NEW* v0.7.4 beta renames diagnostics to **Export Logs and Diagnostics** and makes the export available from the Help menu as well as Settings.
- *NEW* v0.7.3 beta (build 26) adds **Switch to Preferred**. When a share is mounted on a fallback path and the faster one comes back, the button on that share now says what it will do — disconnect the share and mount it once on the preferred network — instead of a generic *Fix Connection*. It only says **Switch to Preferred** when the preferred path really is the one it will use; if your fastest network is still down and only a middle fallback is available, the wording stays generic, because the share is not going where the other label would suggest. It asks before it does anything: quit Final Cut Pro and anything else with files open on that share first.
- *NEW* v0.7.3 beta records what it does, so a problem can be looked into after the fact rather than reproduced. It logs every connection state change, the network path chosen for each share, and every mount and unmount together with what asked for it — including the mounts and unmounts macOS performs on its own, which is what tells you whether shares dropped because the app disconnected them or because the network did. **Export Diagnostics** in Settings writes that log, your configured shares, the live network interfaces and the current mount table into one text file, ready to send. No passwords and no account names are in it.
- *FIXED* v0.7.3 beta stops a failed reconnect from leaving a share unmounted. Automatic reconnection, and the repair button, both used to disconnect the share first and only then look for a saved password and a reachable server — so if either was missing you were left with no mount at all, having had a working one moments earlier. This was most likely exactly when it hurt: while a Mac changes network, every configured path is briefly unreachable, so every share could be taken down at once. Both now check they can reconnect before disconnecting anything, and say so when they decline.
- *FIXED* v0.7.3 beta makes the app far quicker to notice a server that is not answering. Checking whether a share's server was reachable waited a second and a quarter before giving up, even when the server had already refused outright — which it does immediately when it is switched off. That check now returns as soon as the answer is known. It matters most while a Mac is changing network, when the old behaviour could leave the app busy for fifteen seconds at a time.
- *FIXED* v0.7.3 beta fixes a crash and a freeze around saved passwords. Reading a password from the Keychain was done on the part of the app that draws the window, so the Settings window locked up for as long as the standard macOS *Always Allow* prompt was on screen — the one you see the first time the second app reads a share the first one saved. Separately, status checks could overlap and run into each other, which could crash the app outright; they no longer can.
- *FIXED* v0.7.2 beta (build 22) makes the status colours say one thing at a time. A share connected on its **fallback** path showed an orange check mark — a warning colour on the icon that means "connected", repeating what the orange **Fallback** label beside it already said. A green check now always means connected, and only the wording turns orange. An **offline** share is grey rather than red and no longer counts as needing attention: a server that is switched off, or being away from that network, is not something you can fix.
- *FIXED* v0.7.1 beta (build 21) makes **Connect All** work in SMB Connect Desktop. In 0.7.0 the `Shares` menu decided once at launch — before the app had finished looking at your network — whether anything was connectable, and never checked again, so **Connect All** and **Disconnect All** were greyed out for as long as the app was open. Connect All is also a properly labelled toolbar button now rather than an unlabelled icon.
- *NEW* v0.7.0 beta (build 20) adds **SMB Connect Desktop**, a second app with a Dock icon and a proper window — shares down the left, and the selected one filling the right with the things the menu bar popup has to shorten: the full explanation when another user holds a volume, every configured network path with the one in use marked, and the complete repair guidance. Closing its window does not quit it. Both apps share one configuration and are built to run side by side.
- *FIXED* v0.7.0 beta warns properly when you are on **Wi-Fi with no wired connection**. The banner previously only said anything when the Mac had no network at all, so a Wi-Fi-only Mac saw a reassuring blue "Active Networks". Shares mount fine over Wi-Fi — that is why it is worth flagging, because everything on them is simply far slower than the `1GbE` or `10GbE` path they are configured for.
- *NEW* v0.6.0 beta (build 19) says when **another user logged in on this Mac** already has the share mounted — naming who has it, whether they are still logged in, and where — instead of reporting a folder to rename that belongs to another account and cannot be opened from your session. A `/Volumes` path is claimed once for the whole Mac, not once per user.
- *NEW* v0.6.0 beta detects **one server mounted through two different addresses** — its IP and its Bonjour `.local` name, which is what the Finder's **Network** sidebar uses. macOS cannot tell those are the same machine, so mounting through both gives you two volumes and the second gets a `-1`. The share now names both addresses, and `Fix Connection…` clears it.
- *FIXED* v0.6.0 beta no longer reports a share as connected when the mount belongs to another user's account, and says so immediately if macOS has to place a mount at `-1` rather than leaving you to find the suffixed path later in Final Cut Pro.
- *NEW* v0.5.5 (build 14) adds built-in help — press `?` in the menu or open Settings → Help — with a **Quick Start** (add a share, save credentials, connect, read the status icons) and an **Advanced** section (preferred/fallback paths, VPN, duplicate mounts, `/Volumes` conflicts, MDM deployment). Adds **Check for Updates**, which compares version numbers only, installs nothing, and sends no device or share information.
- *FIXED* v0.5.5 stops long share names garbling the status badges beside them — the share card header now carries a single status icon (wording on hover and for VoiceOver) plus the source badge, with the full detail still spelled out in the pills below. The menu footer now marks `Connect All` as the primary action, with Settings, Help, Check for Updates and Quit in a lighter row beneath it.
- *FIXED* v0.5.4 (build 13) connects to shares that are reachable only over a VPN or routed network (WireGuard, Tailscale, corporate, inter-VLAN). Endpoint selection no longer requires the server IP to be on a local subnet — it keeps subnet matching as a fast path, then falls back to probing every configured endpoint and connects to whichever answers on SMB (TCP port 445). Connections made over a routed path are tagged `(via VPN)` in the status detail.
- *FIXED* v0.5.3 (build 12) shows a readable "Authentication failed" message instead of `Mount failed (error 80)` when a credential is rejected, keeps startup auto-connect quiet (failures show on the footer status line instead of a modal alert), and pins the popup header and `Quit` button so the title and buttons are never clipped — only the summary and shares list scroll.
- *FIXED* v0.5.3 stops a false `Mounted Wrong` / duplicate state caused by macOS system and autofs volumes (for example the `auto_home` map named `home`) matching a configured share such as `Home`, and posts a quiet macOS notification when a share genuinely needs attention. The app version is also shown in the popup (next to `Quit`) and in the bottom-left of the Settings window.
- *FIXED* v0.5.2 gives MDM-managed shares a stable identity so usernames and passwords can be entered once and persist, and adds `json_to_mobileconfig.sh` to convert a setup JSON into a profile.
- *NEW* v0.5.0 auto-reconnects dropped shares when the server is still reachable, with stale mount cleanup and a 60-second cooldown.
- *FIXED* v0.5.1 removes main-thread publishing warnings in the mount service.
- v0.4.1 fixed the SMB Connect Settings window so it reliably comes to the front when opened from the menu bar app.

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
