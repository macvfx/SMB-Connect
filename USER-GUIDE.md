# SMB Connect User Guide

## Preferred-only connections and laptop recovery

In **Settings → General**, enable **Only use preferred network** to restrict new
connections for every share to its preferred endpoint. Turn it off to return to
each share’s own setting; individual choices are preserved. The global setting
is shared by both apps and defaults off. It does not disconnect existing mounts.

For an individual share, select it in **Settings** and enable **Only connect on preferred network**.
This blocks new connections to fallback endpoints for manual Connect, Connect All,
startup, auto-reconnect, repair, and external mount requests. With the preferred
endpoint unavailable, the share shows **Waiting for preferred network**. The
setting defaults off and follows the existing managed-share editing restrictions.

Preferred means the first endpoint in priority order. This selects a server
endpoint; it does not bind SMB traffic to a physical adapter or verify 10GbE link
speed. Before probing a local-subnet endpoint, SMB Connect checks which source
address macOS would actually use. If Wi-Fi owns that route while a matching wired
interface is active, the endpoint is blocked as a **Route Conflict** rather than
contacted through the wrong network. An existing fallback mount is left connected when you enable the setting.
Use the confirmed repair/switch action when you are ready to move it. External
requests for an already mounted volume keep using that volume.

Auto-reconnect retains intent for shares that were mounted during this app
session, including when a temporary network outage occurs before a route returns.
Retries respect the existing 60-second cooldown. Network-path changes and wake
from sleep request a debounced refresh immediately; the 20-second status refresh
remains as a backstop.
Explicit Disconnect or Disconnect All cancels that intent. A surviving mount is
not automatically disconnected because a reachability probe changes its result.

Click the Dock icon to open and focus the main window, including when only Help
or Settings is visible. For the original app, enable **Show Dock icon and desktop
window** under General. The existing `smbconnect://v1/show-desktop` action also
opens the window and saves that preference.


## Overview

SMB Connect connects to SMB shares by IP address while preferring the fastest configured network path.

Typical uses:

- connect to the same storage over `10GbE` when available and `1GbE` when not
- keep several shares ready in one utility
- preload share definitions from JSON or MDM
- let each user store their own password locally in Keychain

## One App, Two Presentations

Use the original **SMB Connect** app as the main interface. It owns saved
credentials, selects the preferred or fallback network, performs mounts, runs
automatic reconnection, and accepts approved mount requests from apps such as
CopyTrust.

The same app has two presentations:

- **Menu bar, the default** — a compact popup for status, Connect, Disconnect,
  Refresh, Settings, Help, and updates. This is the normal interface.
- **Optional Dock icon and full window** — the same SMB Connect app gains a Dock
  icon, macOS application menus, and a resizable shares window. The menu-bar
  control remains available.

To enable the full window, open **Settings → General** and turn on **Show Dock
icon and desktop window**. Use this mode on a laptop with limited menu-bar space,
or whenever you want a persistent window with a share list, expanded status and
repair details, and toolbar actions. The window also provides `⌘R` for Refresh,
`⌘K` for Connect All, and `⇧⌘K` for Disconnect All.

Changing presentation does not create another configuration or another
credential owner. The same SMB Connect process, preferences, Keychain entries,
mount logic, and automatic behavior continue underneath. Turning the option off
returns the app to its menu-bar presentation.

The separate **SMB Connect Desktop** compatibility app is no longer needed for
a full-size interface or for a new deployment. Existing users can read
[Appendix: SMB Connect Desktop Compatibility App](#appendix-smb-connect-desktop-compatibility-app)
for how that older companion connects through SMB Connect.

## How To Use The App

### 1. Open The App

Click the SMB Connect drive icon in the macOS menu bar.

The popover shows:

- a top banner with your current network information, which turns orange to warn you when the Mac is on Wi-Fi with no wired connection
- a `Connection Summary` section
- a `Shares` section with one status card per configured share
- `Refresh` and `Connect All` as the main actions at the bottom
- a row beneath them with `Settings`, `Help`, `Check for Updates`, and `Quit`
- the app version in that same row for a quick peek (also shown, with build number, in the bottom-left of the Settings window)

`Connect All` is highlighted as the primary action. Hover any of the smaller buttons for a description of what it does.

The top banner and the bottom action rows (including `Quit`) stay pinned in place. Only the `Connection Summary` and `Shares` sections scroll, so the title and buttons remain visible no matter how many shares you have configured.

If you prefer a regular Mac window, open `Settings…`, select `General`, and
turn on `Show Dock icon and desktop window`. The full window shows the same
shares and live state with more room for network paths, explanations, and repair
guidance. You can keep using the menu-bar popup while the window mode is enabled.

### 2. Read The Connection Summary

The `Connection Summary` section gives a quick count of:

- `Mounted`
- `Preferred`
- `Fallback`
- `Attention`

`Attention` counts only shares you can actually do something about — a duplicate
or wrong-path mount, a `/Volumes` name conflict, a volume another user is
holding, or a share still needing credentials. A share that is simply offline
because its server is switched off or you are away from that network is **not**
counted, and shows a grey icon rather than a red one.

Below that is a one-line summary per share so you can quickly scan which shares
are connected and on what network speed. A green check means connected. The
network-speed badge uses neutral high-contrast text; its small green dot means
the preferred path and its orange dot means a fallback path. `Fallback` is also
spelled out in orange so the meaning does not depend on colour alone.

### 3. Read A Share Card

Each share card is centered on one configured share alias.

A card shows:

- the share alias
- the SMB share name
- a status icon and a source badge, at the top right
- a `Connection` pill
- a `Status` pill
- a `Network` pill
- a summary line
- a detail line
- an action button such as `Connect`, `Disconnect`, `Fix Connection…`, or `Complete Setup…`

Long share names are shortened with a trailing `…`. Hover the name to see it in full.

#### Status Icon Legend

The icon at the top right of each card is an at-a-glance version of the same state the
`Connection` and `Status` pills spell out below it. Hover any icon to see its wording.

<div class="page-break"></div>

- **✅ Green check — Connected:** the share is mounted. Nothing to do.
- **✅ Green check + orange `Fallback` — Connected on fallback:** the share is
  mounted on a fallback path rather than the preferred one. Nothing to do unless
  you expected the faster path.
- **◌ Blue dashed circle — Ready:** a network path is reachable and credentials
  are saved. Press `Connect`.
- **🚫 Grey crossed-out Wi-Fi — Offline:** no configured endpoint responded on
  port 445. Grey, not red: nothing is broken; the server simply is not
  answering. Check the server is on and that you are on the right network.
- **🔑 Yellow key — Setup needed:** no credentials are saved for this share.
  Press `Complete Setup…`.
- **⚠️ Red warning triangle — Mounted wrong or duplicate:** press
  `Fix Connection…`.
- **🛑 Red octagon — Blocked:** a `/Volumes` name conflict is preventing the
  mount. See *What To Do For A Volume Name Conflict*.
- **👤 Red person badge — Blocked:** another user logged in on this Mac has the
  volume mounted. See *What To Do When Another User Has The Volume*.
- **Branching arrows — Route Conflict:** macOS would route the configured storage
  address through Wi-Fi even though a wired interface is active on the same subnet.
  SMB Connect refuses that endpoint until the route is corrected.
- **❌ Red cross — Error:** read the detail line beneath the card.

Or follow it through:

```mermaid
flowchart TD
    A[Share shows an icon] --> B{Which icon?}
    B -->|Green check| C[Connected — nothing to do]
    B -->|Blue dashed| D[Press Connect]
    B -->|Yellow key| E[Save credentials in Settings]
    B -->|Red triangle| F[Press Fix Connection]
    E --> D
    F --> G{Reconnected?}
    G -->|Yes| C
    G -->|No| H[Check /Volumes for a name conflict]
```

#### Source Badge

Beside the status icon, a badge shows where the share's configuration came from:

- `User` — added by you in Settings
- `JSON` — imported from a setup file
- `MDM` — supplied by a managed configuration profile and locked

### 4. Understand The Main Pills

#### Connection

This tells you the broad connection state:

- `Connected`
- `Ready`
- `Blocked`
- `Not Connected`
- `Error`

#### Status

This tells you whether the share is on the expected path:

- `Preferred`
- `Fallback`
- `Fix Needed`
- `Duplicate`
- `Setup`
- `Blocked`
- `In Use`

There may also be a second share-state pill such as:

- `Mounted`
- `Available`
- `Reconnect`
- `Setup Needed`
- `Rename /Volumes Item`
- `Other User`

#### Network

This shows the current or selected network speed for that share, for example:

- `1GbE`
- `10GbE`
- `25GbE`
- `100GbE`

### 5. Use Connect All

The `Connect All` button (`⌘K`) in the footer starts by refreshing the setup,
mounted volumes, networks, and share readiness. It accounts for every configured
share, then mounts each ready share one at a time. Sequential mounting avoids a
burst of simultaneous SMB sessions while still continuing to later shares when
one share fails.

While the batch runs, the progress line names the share being mounted and the
button remains disabled so a second batch cannot overlap it. The final message
reports how many shares connected now, were already connected, failed, or were
skipped. It includes the reason for every failed or skipped share.

Ready means a preferred or permitted fallback endpoint is reachable and the
share is safe to mount. Already mounted shares are preserved. Shares with
missing credentials, unavailable or policy-blocked networks, name conflicts,
another user's mount, or a repair state are not mounted; the status and final
summary explain what needs attention.

## What The Main States Mean

### Connected On Preferred Network

The share is mounted and the app believes it is using the fastest configured preferred path.

### Connected On Fallback Network

The share is mounted, but the preferred path is not active or not selected.

The check mark stays **green** — the share is connected and there is nothing
wrong with it. The word **Fallback** is what appears in orange. In the compact
Connection Summary, the speed stays neutral and an orange dot marks the
fallback path; on the detailed share card, the full `Network` pill remains
orange. A green check always means connected.

Once the preferred path comes back — the wired network returns, or the server
starts answering on it again — the share's button changes to
`Switch to Preferred…`. It disconnects the share and mounts it once on the
preferred path.

Quit Final Cut Pro and anything else with files open on that share first. macOS
cannot move a mount without taking it away, and an application holding a file
across the switch will lose it. The app asks for confirmation before it does
anything.

The button only says `Switch to Preferred` when the preferred path is the one it
will actually use. If your fastest path is still down and only a middle fallback
is reachable, it reads `Fix Connection…` instead — the mount is still worth
repairing, but it is not going where the other label would imply.

### Preferred Network Available

The share is not mounted yet, but the preferred network path appears reachable and ready.

### Fallback Network Available

The share is not mounted yet, but only a slower fallback path appears available right now.

### Complete Setup

The share definition is present, but the user has not yet saved credentials in Keychain.

### Duplicate Mount Detected

The app has detected multiple mounted instances such as:

- `Video`
- `Video-1`

This is a warning condition and should usually be repaired before continuing work.

Mount detection only looks at genuine network shares mounted under `/Volumes`. macOS system and automounted volumes — such as the `auto_home` map that appears as a non-local volume literally named `home` at `/System/Volumes/Data/home` — are ignored, so a share whose name matches a system volume (for example a share called `Home`) no longer shows a false `Mounted Wrong` or duplicate state.

### Notifications

When a share *newly* enters an attention state — a genuine duplicate, a wrong-path mount, or a `/Volumes` name conflict — SMB Connect posts a single, quiet macOS notification so you are told without having to open the popover. macOS asks for notification permission the first time the app runs; you can change it later in System Settings → Notifications → SMB Connect.

### Volume Name Conflict

The app found a local file or folder in `/Volumes` that already uses the share’s mount name.

Example:

- local folder: `/Volumes/Video`
- intended share mount: `Video`

If the app mounted anyway, macOS could create `Video-1`, which is exactly what SMB Connect is trying to prevent.

### Same Share Mounted Two Ways

A server can be reached by more than one address — its IP, or a Bonjour name such as
`nas._smb._tcp.local` that the Finder's **Network** sidebar uses. macOS has no way to tell
those are the same machine, so mounting the share through both gives you two volumes, the
second suffixed:

```
/Volumes/Storage      from 192.0.2.50               (IP address)
/Volumes/Storage-1    from nas._smb._tcp.local     (Bonjour discovery)
```

This normally happens when a share is mounted once from SMB Connect and once by
double-clicking the server in the Finder sidebar. The card names both addresses and which
kind each is. Use `Fix Connection…` to disconnect every copy and reconnect once on the
configured path, and mount from SMB Connect rather than the Finder sidebar to stop it
coming back.

A single mount from an address that is not one of the share's configured endpoints is
called out too, before it has a chance to duplicate.

### Mounted By Another User

A volume is mounted at a `/Volumes` path once for the whole Mac, not once per user. If a
second person is logged in through fast user switching and has already mounted the share,
that path is taken and macOS would place your copy at `Video-1`.

macOS gives their mount to their account alone — it is `drwx------` under their user ID —
so from your session the folder exists but cannot be opened. Earlier versions of SMB
Connect could not see who owned a mount and reported this as a local folder to rename,
which was impossible advice.

The share card now names the person holding it and whether they are still logged in. For
example:

> Jane Doe (jdoe) has this share mounted at `/Volumes/Video` and is logged in via fast
> user switching. macOS cannot give you that path while they hold it, so connecting now
> would mount Shared Video as `Video-1`.

## Why `-1` Mount Paths Matter

If macOS mounts a share as `Video-1`, applications may record file paths using that full mounted path.

That is especially risky in Final Cut Pro because relinking later can become more difficult if media paths were recorded using a suffixed mount name.

SMB Connect tries to prevent this by:

- warning when duplicate mounts already exist
- blocking connects when a `/Volumes` name conflict would cause a `-1` mount
- offering repair guidance and reconnect workflows

## What To Do For A Volume Name Conflict

If the menu shows `Volume Name Conflict`:

1. Click `Open /Volumes in Finder`.
2. Inspect the conflicting item.
3. Rename or remove the local item that is occupying the intended mount name.
4. Return to SMB Connect and press `Refresh`.
5. Connect again.

If files are already open from that share, quit those apps first.

## What To Do When Another User Has The Volume

If the menu shows `Mounted by Another User`, the fix belongs to whoever holds the mount —
SMB Connect cannot eject another account's volume, and neither can you without admin
rights.

If they are still logged in:

1. Read the card to see who has it and whether they are at the display or switched away.
2. Ask them to eject the volume in the Finder, or switch to their session and eject it.
3. Alternatively, log that user out completely.
4. Return to SMB Connect and press `Refresh`.
5. Connect again.

If the card says they are no longer logged in, the mount was left behind at logout. Press
`Copy Unmount Command` and give the copied line to an admin to run in Terminal:

```bash
sudo umount '/Volumes/Video'
```

Then press `Refresh` and connect again.

`Copy Diagnostics` copies the mount point, the owning account and user ID, their session
state, the server and share behind the mount, and the SMB account they mounted with —
useful when passing the problem to whoever administers the Mac.

To confirm any of this yourself, `mount` in Terminal lists every mount with the account
that made it:

```bash
mount | grep smbfs
```

Each SMB line ends with `mounted by <user>`, which is the same information SMB Connect
now reads directly.

## Wi-Fi Warning

The banner at the top turns orange and reads **Wi-Fi only — no wired network** when your Mac has Wi-Fi but no Ethernet connection.

This is a warning, not an error. Shares mount perfectly well over Wi-Fi — that is exactly why it is worth flagging. Nothing fails, nothing reports an error, and the only symptom is that everything you do on that storage is far slower than it should be. Your shares are configured for a wired `1GbE` or `10GbE` path, and for editing work that path is the one you want.

If you see it, plug in Ethernet and press `Refresh`.

Thunderbolt bridges and VPN tunnels are shown but not judged either way — the app cannot tell a 10GbE Thunderbolt adapter from a tunnel, so it reports the connection and leaves the verdict to you.

### Wi-Fi And Ethernet On The Same Subnet

Two active interfaces can use the same IPv4 subnet while reaching different
physical networks. For example, Wi-Fi and a dedicated storage adapter might both
have addresses in the fictional `192.0.2.0/24` documentation subnet. macOS still
chooses only one outgoing interface for a server address, and its service order
may send that address through Wi-Fi even while the wired adapter remains active.

SMB Connect asks the kernel which local source address it would use before it
probes or mounts an endpoint on a directly attached subnet. When Wi-Fi owns that
route and a matching wired interface is active, the app:

- does not probe or mount that endpoint
- shows **Route Conflict** with the Wi-Fi and wired interface names
- continues to an allowed configured fallback, when one is available
- re-evaluates the share after a network-path change, wake, manual Refresh, or
  the periodic refresh

The most reliable correction is to put the wired storage network on a subnet
that does not overlap Wi-Fi. Alternatively, move the wired service above Wi-Fi
in **System Settings → Network → Set Service Order**, then press `Refresh`.

## What `Refresh` Does

`Refresh` does four things:

- re-evaluates any MDM managed preferences pushed since the last refresh
- rescans the setup folder for new JSON setup files
- rechecks active local network interfaces and reachability
- refreshes mounted volume and conflict status

Use it after:

- dropping a new setup JSON into the setup folder
- an MDM policy change is pushed to the device
- changing networks
- renaming or removing an item in `/Volumes`
- disconnecting or reconnecting shares outside the app

SMB Connect also requests a refresh automatically when macOS reports a
network-path change and after the Mac wakes from sleep. These event-driven
refreshes are debounced briefly so the app assesses one stable route snapshot.
The regular 20-second refresh remains as a backstop.

## In-App Help

You do not need this guide open to get going. SMB Connect has help built in.

Press the `?` button in the menu bar popup, or open **Settings → Help → Getting Started**.
The Help window has two tabs:

- **Quick Start** — adding a share, saving credentials, connecting, and a visual legend
  for the status icons, plus how to make mounting fully automatic.
- **Advanced** — preferred and fallback network paths, shares over VPN, duplicate mounts
  and `-1` paths, volume name conflicts, deploying to many Macs, update checking, and what
  `Refresh` does.

Both tabs link back to this full guide.

## Checking For Updates

SMB Connect can tell you when a newer version has been published.

**On demand** — press `Check for Updates…` in the footer of the menu bar popup. This
always checks and always reports back, including when nothing newer exists. If your copy
is newer than the published release, it says so and names both versions rather than
claiming a match.

**Automatically** — the app also checks quietly when it launches, at most once every 24
hours. This check is silent unless a newer version is found, in which case an alert
offers a `Download` button that opens the release page in your browser.

Nothing is downloaded or installed for you. The check reads only the published version
number and compares it against the running app, and no information about your Mac or your
share configuration is sent.

Pre-release builds are not offered. You will only be told about full releases.

## Settings Window

Open `Settings…` from the menu bar popover.

The Settings window has a left sidebar and a right detail pane.

### Sidebar

The sidebar contains:

- `General`
- `Shares`

The `Shares` list shows each configured share alias, source, and preferred network summary.

### General Section

This contains:

- `Launch at login`
- `Connect all shares on start`
- `Auto-reconnect dropped shares`
- `Show Dock icon and desktop window`
- `Setup Folder`
- `Refresh Status`

`Launch at login` registers the app with macOS to open automatically when the user logs in.

`Connect all shares on start` runs the same refreshed, sequential Connect All
batch after the first status check on launch. Ready shares are attempted even if
an earlier share fails. Already mounted shares are preserved, and shares with
missing credentials, no permitted reachable endpoint, or a safety/repair issue
are recorded but not mounted.

`Auto-reconnect dropped shares` monitors connected shares and automatically reconnects any that drop while the server is still reachable. When a share transitions from mounted to unmounted and SMB Connect can still reach the server on TCP port 445, the app disconnects any stale mount points and reconnects cleanly via the best available network path. A 60-second cooldown per share prevents rapid-fire reconnect attempts if the server is flapping. This is enabled by default.

Pairing `Launch at login` with `Connect all shares on start` and `Auto-reconnect dropped shares` gives a fully automatic mount experience: the app opens at login, connects all ready shares without any user interaction, and keeps them connected if a transient network drop occurs.

`Show Dock icon and desktop window` gives the original SMB Connect app a Dock
icon, application menus, a toolbar, and a resizable shares window. It does not
install or launch another app, and it does not move credentials or mount work to
another process. The menu-bar control remains available. Turning the option off
closes the full-window presentation and returns SMB Connect to menu-bar-only use.

`Setup Folder` is where the app looks for setup JSON files on startup and refresh:

`~/Library/Application Support/SMBConnect/Setup`

### Import / Export

This section is for:

- `Import JSON…`
- `Export JSON…`
- `Open Setup Folder`
- `Export Logs and Diagnostics…`

Use `Import JSON…` to load a setup file manually from anywhere.

Use `Export JSON…` to save the current user-editable share definitions as JSON.

Passwords are not exported.

If you need to create a valid setup JSON file and a matching MDM `.mobileconfig` from a server list, the repo includes a helper script:

- [generate_smbconnect_config.sh](https://github.com/macvfx/SMB-Connect/blob/main/generate_smbconnect_config.sh)

It accepts a comma-separated `.csv` or `.txt` file using
`alias, protocol, shareName, mountName, defaultUsername, note, preferredIP,
preferredSpeed, fallbackIP, fallbackSpeed, allowExternalMountRequests`. The
last field is optional for older input and safely defaults to `false`.

and generates both output formats for SMB Connect.

Examples and usage details are here:

- [Config Generator README](https://github.com/macvfx/SMB-Connect/blob/main/README-config-generator.md)

### Reporting A Problem

SMB Connect records what it does to the macOS unified log: every connection
state change, every network path it selects, and every mount and unmount along
with what asked for it — you, a repair, a switch to the preferred path, or
automatic reconnection. It also records the mounts and unmounts **macOS**
performs on its own, which is what tells you whether shares dropped because the
app disconnected them or because the network did.

For Connect All, the log marks the batch start and refresh duration, the local
interfaces, every recognized configured volume, each share's readiness and
selected endpoint, existing mounts, each sequential mount start, every reason a
share was not mounted, the per-share outcome, and the final counts and duration.
This makes a slow batch distinguishable from one waiting on credentials, network
reachability, a mount operation, or a safety conflict.

`Export Logs and Diagnostics…`, available from the macOS **Help** menu and
Settings, writes that log together with your configured shares and
their current states, the live network interfaces and the current mount table,
into a single text file and reveals it in the Finder. Send that file with your
report.

Passwords and account names are not included.

Export it while the problem is fresh. The report covers the last two hours, and
macOS discards older entries on its own schedule.

If you would rather read the log directly:

```bash
log show \
  --predicate 'subsystem == "com.matx.SMBConnect"' \
  --last 1h \
  --style compact
```

The original app appears in the log as `SMBConnect`. If the older compatibility
app is also running, its lines appear as `SMBConnectDesktop` under the same
logging subsystem.

### Share Settings

This section defines the core share identity.

Fields:

- `Source`
  Admin or config origin, such as user-defined, imported JSON, or MDM-managed.
- `Preferred Network`
  The first-choice network path for this share.
- `Alias`
  The display name shown in the menu bar.
- `Protocol`
  Currently `smb`.
- `Share Name`
  The SMB share path, such as `Outputs` in `smb://server/Outputs`.
- `Mount Name`
  The volume name expected in `/Volumes` after the share is mounted.
- `Default Username`
  A suggested username for the user.
- `Notes`
  Optional comments about the share.

### Network Paths

This section defines one or more IP-based paths to the same share.

Typical use:

- one preferred `10GbE` path
- one fallback `1GbE` path

For each network path, the app shows:

- `Server IP`
- `Network Speed`
- `Priority`
- `Subnet`
- `Label`

Lower priority numbers are preferred first.

**Reachability over VPN.** SMB Connect prefers an endpoint whose `Server IP` is on the same subnet as one of your Mac's local interfaces (your fast local path). If none of those respond, it then tries every other configured endpoint and connects to whichever actually answers on SMB (TCP port 445). This means a share reachable only through a VPN — WireGuard, Tailscale, a corporate tunnel, or a routed/inter-VLAN path — connects normally even though your `utun` address is on a different subnet than the NAS. When a connection is made over such a routed path, the status detail tags it `(via VPN)`, for example `Current network: 1GbE · 198.51.100.50 (via VPN)`, so an over-the-tunnel connection is always visible.

### Credentials

This section stores the user’s login details in Keychain.

Fields:

- `Username`
- `Password`

Actions:

- `Save Credentials`
- `Delete Credentials`

Important:

- passwords are saved locally in Keychain
- passwords are not stored in JSON
- passwords are not stored in the MDM profile

The original SMB Connect app is the credential owner. Use its Settings window
to create, change, or delete credentials whether you use the compact menu-bar
presentation or its optional full window.

### External Mount Requests

`Allow apps to request this volume` permits CopyTrust or another local app to
ask SMB Connect to mount this share by its configured **Mount Name**. It is off
by default. It remains unavailable when two shares have the same Mount Name
because SMB Connect will not guess which one the caller meant.

CopyTrust uses the same request model as the SMB Connect Desktop compatibility
app: it sends the required Mount Name to SMB Connect, then waits for the volume
and its own required folder to appear. CopyTrust does not receive the SMB
password, server address, or preferred/fallback network configuration.

IT can force the same per-share setting through the `com.matx.SMBConnect` MDM
payload by placing `allowExternalMountRequests = true` in an approved
`ManagedShares` dictionary. Managed shares are locked in the UI. For a fleet
rollout, generate and validate the exact profile as described in
[CopyTrust and SMB Connect MDM deployment plan](https://github.com/macvfx/SMB-Connect/blob/main/COPYTRUST-MDM-DEPLOYMENT-PLAN.md).

An allowed request contains no connection details or credentials:

```text
smbconnect://v1/mount?volume=Example_NAS1&request=<uuid>
```

SMB Connect selects the fastest reachable preferred or fallback endpoint and reads the password from its own Keychain item. The caller watches for `/Volumes/Example_NAS1`, then checks the relative folder it needs. For example, CopyTrust may require `/Volumes/Example_NAS1/Archives`; only `Example_NAS1` is sent to SMB Connect, while checking `Archives` remains CopyTrust's responsibility.

### Current Status

This section shows the live status for the selected share and any repair guidance.

If the share needs repair or attention, this section explains why.

## Ways To Create Configuration

There are several ways to produce share definitions, depending on what you start
from. They all end in one of two artifacts: a **setup JSON** (imported per user
in the app) or an **MDM `.mobileconfig` profile** (pushed by IT).

- **In the app** — add and edit shares in `Settings…`, then `Export` to a JSON
  file for backup or to seed another Mac. See `Import / Export` above.
- **Mount Import Assistant** — a small companion app that reads the SMB shares
  already mounted on a Mac and writes a setup JSON, so you can bootstrap a config
  from a machine that is already working. The same workflow is available on the
  command line via `mount_to_smbconnect_config.sh`. See
  [scripts/README-mount-import.md](https://github.com/macvfx/SMB-Connect/blob/main/README-mount-import.md).
- **Generator script** — turn a `.csv`/`.txt` server list into both a setup JSON
  and a matching profile in one step. See
  [scripts/README-config-generator.md](https://github.com/macvfx/SMB-Connect/blob/main/README-config-generator.md).
- **JSON → profile converter** — when you already have a setup JSON and just need
  the deployable MDM profile. See
  [scripts/README-json-to-mobileconfig.md](https://github.com/macvfx/SMB-Connect/blob/main/README-json-to-mobileconfig.md).

## JSON Configuration

SMB Connect can import and export JSON share definitions.

JSON is useful for:

- bootstrapping users
- copying a setup to another Mac
- keeping a backup of share definitions

JSON can define:

- alias
- protocol
- share name
- mount name
- default username
- one or more network paths
- path priority
- notes
- whether approved local apps may request the volume by Mount Name

Passwords are intentionally omitted.

See:

- [Configuration Format](https://github.com/macvfx/SMB-Connect/blob/main/CONFIGURATION-FORMAT.md)
- [SMBConnectSetup-EXAMPLE.json](https://github.com/macvfx/SMB-Connect/blob/main/examples/SMBConnectSetup-EXAMPLE.json)
- [SMBConnectSetup-DEMO-SIX-SERVERS.json](https://github.com/macvfx/SMB-Connect/blob/main/examples/SMBConnectSetup-DEMO-SIX-SERVERS.json)

## MDM Profile Configuration

SMB Connect also supports an MDM profile that preloads managed share definitions.

This is useful when IT wants to push:

- share aliases
- share names
- mount names
- preferred and fallback IPs
- network speed labels
- default usernames
- per-share CopyTrust/external-request approval

The user can still enter and store their own password locally in Keychain.

You can build the profile directly from a setup JSON with
[`json_to_mobileconfig.sh`](https://github.com/macvfx/SMB-Connect/blob/main/json_to_mobileconfig.sh):

```bash
./scripts/json_to_mobileconfig.sh \
  -i ./Config/SMBConnectSetup-EXAMPLE.json \
  -o ./Config/generated/SMBConnectSetup-EXAMPLE.mobileconfig \
  --organization "Example Organization"
```

Two options shape how the profile behaves on the user's Mac:

- `--allow-user-defined true|false` — with `true` (the default) a deployed
  profile **keeps** each user's own imported shares and merges the managed ones
  on top, so pushing a profile does not wipe a user's existing setup. With
  `false`, the app shows only the managed shares.
- `--blank-username` — leave each managed share's `defaultUsername` empty so
  every user enters their own. Without it, the username from the JSON is baked
  into the profile and is identical (and locked) for all users on the device.

Passwords are never written to the profile.

For CopyTrust, validate the finished profile before MDM upload. This command
requires both fictional example volumes to exist exactly once and to have the
external-request policy explicitly enabled:

```bash
./scripts/validate_copytrust_mdm_profile.sh \
  ./Config/generated/Example-Ingest.mobileconfig \
  Archive Projects
```

<div class="page-break"></div>

### Entering Credentials For A Managed Share

A managed share is preloaded read-only, but its username and password are not
part of the profile. To finish setup, open `Settings…`, select the managed
share, and enter the username and password in the `Credentials` section — they
are saved to the user's Keychain and reused on every connect.

> **Requires app v0.5.2 or later.** Earlier builds regenerated a managed share's
> internal identity on every refresh (about every 20 seconds), which reset the
> Settings selection and blanked the credential fields as you typed, and
> prevented saved credentials from being reloaded. v0.5.2 gives managed shares a
> stable identity so credentials can be entered once and persist. If you deployed
> an earlier build, install v0.5.2 and re-enter the credentials once; the profile
> itself does not need to be redeployed.

See:

- [com.matx.SMBConnect.mobileconfig](https://github.com/macvfx/SMB-Connect/blob/main/examples/com.matx.SMBConnect.mobileconfig)
- [scripts/README-json-to-mobileconfig.md](https://github.com/macvfx/SMB-Connect/blob/main/README-json-to-mobileconfig.md)

## Recommended Admin Workflow

1. Create share definitions using one of the methods in
   [Ways To Create Configuration](#ways-to-create-configuration) — type them in
   the app, import existing mounts with the Mount Import Assistant, or generate
   them from a server list.
2. Preload alias, share name, mount name, and preferred/fallback IPs.
3. Optionally preload a default username, or use `--blank-username` so each user
   supplies their own.
4. For every CopyTrust destination, explicitly enable
   `allowExternalMountRequests`; leave it false for other shares.
5. To deploy by MDM, convert the JSON with
   [`json_to_mobileconfig.sh`](https://github.com/macvfx/SMB-Connect/blob/main/json_to_mobileconfig.sh) (or generate
   the profile directly). Keep `--allow-user-defined true` unless you want to
   lock users to only the managed shares.
6. Validate every required CopyTrust Mount Name with
   `validate_copytrust_mdm_profile.sh` before uploading the profile.
7. Let the user open the app and save their password locally in Keychain.
8. Have the user connect from the menu bar app.

## Recommended User Workflow

1. Open SMB Connect from the menu bar.
2. Open `Settings…` if a share shows `Complete Setup`.
3. Save your username and password in the `Credentials` section.
4. Return to the menu bar app.
5. Press `Connect All` to refresh and mount all ready shares sequentially, or connect individual shares as needed. Review the final summary for any share that failed or was skipped.
6. If warned about duplicate mounts or `/Volumes` conflicts, resolve those before editing media.

To connect automatically on every login, enable both `Launch at login` and `Connect all shares on start` in Settings → General.

## Troubleshooting

### The Share Does Not Connect

Check:

- the configured IP address
- whether the preferred or fallback network is actually active
- whether credentials were saved in Keychain
- whether the target SMB server is reachable

### The App Says `Volume Name Conflict`

There is already a local item in `/Volumes` using the mount name.
Open `/Volumes`, inspect the item, then rename or remove it before connecting.

### The App Says `Same Share Mounted Two Ways`

The share is mounted from two different addresses for the same server — typically its IP
and its Bonjour `.local` name. Use `Fix Connection…`, then mount from SMB Connect rather
than the Finder's Network sidebar.

To see it yourself, `mount` in Terminal shows the address each mount came from:

```bash
mount | grep smbfs
```

### The App Says `Mounted by Another User`

Another account logged in on this Mac holds the `/Volumes` path this share needs. Ask
them to eject it or log them out, then press `Refresh`. If they have already logged out,
an admin can clear the leftover mount with `sudo umount` — the card's `Copy Unmount
Command` button gives you the exact line.

### The App Says `Duplicate Mount Detected`

The share appears mounted more than once.
Use the repair workflow or manually disconnect all matching mounts and reconnect only once.

### The Share Mounted On The Wrong Network

If the app says the share is on a fallback or slower path, use the repair flow to disconnect and reconnect on the preferred network when available.

### The Share Shows `Route Conflict`

The preferred server address currently resolves to a Wi-Fi source address while
a wired interface is active on the same subnet. SMB Connect blocks the endpoint
before probing or mounting it because the same numeric address may name a
different device on the Wi-Fi network.

Use a distinct subnet for dedicated storage when possible. Otherwise, move the
wired network service above Wi-Fi in macOS service order and press `Refresh`.
Turning off preferred-only policy may allow a separately addressed fallback; it
does not make an ambiguous preferred route safe.

> **Fixed in v0.5.3.** Earlier builds (v0.5.1 and v0.5.2) could falsely report `Mounted Wrong` or a duplicate for a share whose name matched a macOS system/autofs volume — most commonly a share called `Home`, which collided with the built-in `auto_home` volume named `home` — even though there was no real mount and no `-1` volume in `/Volumes`. v0.5.3 restricts detection to genuine network shares under `/Volumes`. If you saw this, install v0.5.3 and press `Refresh`.

### A Share Keeps Disconnecting And Reconnecting

If a share repeatedly drops and auto-reconnects, the underlying NAS or network path is unstable. SMB Connect enforces a 60-second cooldown between reconnect attempts for the same share to prevent thrashing. Check:

- the physical network connection to the NAS
- whether the NAS is under heavy load or restarting services
- whether a VPN or firewall is intermittently blocking SMB traffic on port 445

If the flapping continues, consider disabling `Auto-reconnect dropped shares` in Settings → General until the network issue is resolved.

### Auto-Reconnect Is Not Triggering

Auto-reconnect only fires when the share transitions from mounted to unmounted while the server is still reachable. It will not trigger if:

- the server itself is down or unreachable (the share shows `Unavailable`, not `Ready`)
- the share was never mounted in the current session (the app must have seen it mounted at least once)
- the 60-second cooldown from a previous reconnect attempt has not elapsed
- `Auto-reconnect dropped shares` is turned off in Settings → General

## Appendix: SMB Connect Desktop Compatibility App

The separate **SMB Connect Desktop** app is retained for compatibility with
older deployments. It is no longer needed for a full-size interface: the
original SMB Connect app now provides its own optional Dock icon, application
menus, toolbar, and resizable window through **Settings → General → Show Dock
icon and desktop window**.

If SMB Connect Desktop is already installed, it can continue to show the shared
share configuration and current mount state. Its role is a client of the
original SMB Connect app. CopyTrust can use the same request path when it needs
an approved volume before starting an ingest:

1. A Connect action checks that the share allows external mount requests.
2. Desktop sends a versioned request using the share's configured Mount Name,
   for example:

   ```text
   smbconnect://v1/mount?volume=Example_Archive&request=<uuid>
   ```

3. macOS opens or activates the original SMB Connect app.
4. SMB Connect resolves the unique Mount Name, chooses the best reachable
   preferred or fallback endpoint, reads its own Keychain entry, performs the
   mount, and updates the shared status.

SMB Connect Desktop does not read, copy, or resave the SMB password. It cannot
repair a conflicted mount or complete missing credentials itself; those actions
open the original SMB Connect app. It can still display status, request
connections for explicitly approved volumes, disconnect a mounted share, and
reveal it in Finder.

For a new installation, install and use **SMB Connect** alone. Enable its Dock
icon and full window if the menu-bar presentation is too compact. This keeps one
credential authority and one mount authority while providing both interface
styles.
