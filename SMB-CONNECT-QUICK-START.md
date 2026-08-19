# SMB Connect Quick Start

## 1. Open SMB Connect

Use the original **SMB Connect** app. It owns credentials, network selection,
mounting, and reconnection. Click its drive icon in the macOS menu bar to see
networks, share cards, connection counts, and actions.

For a regular Mac window, enable **Settings -> General -> Show Dock icon and
desktop window**. The same app gains a Dock icon and resizable window while the
menu-bar control stays available.

## 2. Complete Setup And Connect

1. Open `Settings... -> Shares`, choose a share, and confirm its Mount Name and
   network paths.
2. Save the username and password.
3. Press `Connect`, or use `Connect All` for every ready share.

Passwords stay in the user's Keychain.

<div class="page-break"></div>

## 3. Read The Status

A green check means mounted; `Fallback` means it used a slower configured path.
Blue dashed means ready to connect. Grey means no endpoint answered. Yellow or
red means complete setup or follow the card's repair guidance.

## 4. Make It Automatic

In **Settings -> General**, enable **Launch at login**, **Connect all shares on
start**, and **Auto-reconnect dropped shares** for hands-off operation.

## 5. Preferred, Fallback, And Warnings

SMB Connect tries paths in priority order: `10GbE`, `1GbE`, then an optional
VPN. Fallback is still connected. Quit apps before `Switch to Preferred...`.

If Wi-Fi conflicts with required `1GbE` or `10GbE` storage, turn Wi-Fi off
before connecting so the Mac uses the intended wired path.

- **Name conflict or duplicate** - inspect `/Volumes` and follow the card's
  guided repair.
- **Mounted by Another User** - ask that user to eject or sign out.
- **Offline** - no endpoint is answering; check the server and network.

For support, choose **Help -> Export Logs and Diagnostics...**. The report omits
passwords and account names.

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

Open `?` Help or read the [full User Guide](USER-GUIDE.md).
