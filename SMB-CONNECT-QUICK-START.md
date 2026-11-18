# SMB Connect Quick Start

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


## 1. Open SMB Connect

SMB Connect keeps a list of the important servers and shares you want to use,
including an individual account for each share. It connects through your
preferred fast network, such as `10GbE`, and can fall back to a slower network,
such as `1GbE`, when that is better than having no connection.

For a regular Mac window, enable **Settings -> General -> Show Dock icon and
desktop window**. The same app gains a Dock icon and resizable window while the
menu-bar control stays available.

## 2. Complete Setup And Connect

1. Open `Settings... -> Shares`, choose a share, and confirm its Mount Name and
   network paths.
2. Save the username and password.
3. Press `Connect`, or use `Connect All` to refresh and check every configured
   share, then mount each ready share one at a time. One failure does not stop
   the remaining shares. The final message counts connected, already connected,
   failed, and skipped shares and explains every failure or skip. If `Connect All`
   is greyed out, the reason appears under the button in the menu bar popup.

Passwords stay in the user's Keychain.

<div class="page-break"></div>

## 3. Read The Status

A green check means mounted; `Fallback` means it used a slower configured path.
In the Connection Summary, the speed uses neutral high-contrast text with a
green dot for the preferred path or an orange dot for a fallback path. Blue
dashed means ready to connect. Grey means no endpoint answered. Yellow or red
means complete setup or follow the card's repair guidance.

## 4. Make It Automatic

In **Settings -> General**, enable **Launch at login**, **Connect all shares on
start**, and **Auto-reconnect dropped shares** for hands-off operation.

## 5. Preferred, Fallback, And Warnings

SMB Connect tries paths in priority order: `10GbE`, `1GbE`, then an optional
VPN. Fallback is still connected. Quit apps before `Switch to Preferred...`.

If Wi-Fi and Ethernet use the same subnet but macOS routes a preferred storage
address through Wi-Fi, the share shows **Route Conflict** and SMB Connect refuses
that endpoint. Put the storage network on a distinct subnet or move the wired
service above Wi-Fi in macOS network service order, then Refresh. An allowed
fallback remains available.

- **Name conflict or duplicate** - inspect `/Volumes` and follow the card's
  guided repair.
- **Mounted by Another User** - ask that user to eject or sign out.
- **Offline** - no endpoint is answering; check the server and network.
- **Route Conflict** - macOS would send a matching storage address through Wi-Fi
  while wired Ethernet is active on the same subnet; correct the route and Refresh.

For support, choose **Help -> Export Logs and Diagnostics...**. For Connect All,
the report records recognized volumes and networks, readiness, each mounting
attempt, why a share was not mounted, the final outcomes, and timing. The report
omits passwords and account names.

<div class="page-break"></div>

## 6. CopyTrust Mount Requests

CopyTrust can request an approved volume before ingest using the same Mount Name
model as the older Desktop app:

```text
smbconnect://v1/mount?volume=Example_Archive&request=<uuid>
```

In **Settings -> Shares**, enable **Allow apps to request this volume**. The
Mount Name must be unique and its credential already saved.

SMB Connect chooses the best endpoint, reads its Keychain entry, and mounts.
CopyTrust waits for `/Volumes/Example_Archive`, then checks its required folder.
It receives no password, server address, or network preference.

MDM can enforce `allowExternalMountRequests = true`; passwords remain per user
and per Mac in Keychain.

## 7. SMB Connect Desktop Compatibility

The separate **SMB Connect Desktop** app is no longer needed for new installs.
It remains compatible and sends the same request shown above, but does not read
passwords; SMB Connect remains the mount and credential authority.

## More Help

Open `?` Help or read the full User Guide at
<https://github.com/macvfx/SMB-Connect/blob/main/USER-GUIDE.md>.
