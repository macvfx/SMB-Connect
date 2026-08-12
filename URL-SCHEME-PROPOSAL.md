# URL Scheme — so another app can ask for a mount

**Raised:** 2026-08-11, from CopyTrust's enforced-naming work.
**Status:** Released in SMB Connect 0.7.4 (build 27) on 2026-08-11. The same
request path was manually proven between SMB Connect Desktop and the original
SMB Connect app on a separate test Mac. CopyTrust adoption remains a separate
change; see [CopyTrust integration with SMB Connect](COPYTRUST-SMB-CONNECT-INTEGRATION.md).

---

## Why

CopyTrust is gaining a mode where the destination comes from a preset — a volume plus a path
on it — rather than being browsed to. When the operator loads that preset and the volume is
not mounted, CopyTrust has three options today:

1. Warn, name the volume, and let the operator mount it themselves.
2. Ask SMB Connect to mount it.
3. Mount it itself.

Before this implementation, option 2 was not possible: `SMBMountService` mounted via
`NetFSMountURLSync`, but the app exposed no URL scheme or command-line entry point. Option 3
would mean a second app growing its own share list, credential storage and mount-conflict
handling — duplicating this one and splitting the place a client's credentials live.

Option 2 is now implemented in SMB Connect. CopyTrust can adopt it in a later version while
retaining option 1 as the fallback for older installations, refused requests, and off-site use.

---

## Separation of roles

CopyTrust should describe the storage it requires, not how to connect to it. SMB Connect
should remain the only app that knows how a configured network volume is reached.

| Responsibility | Owner |
|---|---|
| Required volume name, such as `Example_NAS1` | CopyTrust |
| Required relative folder, such as `Archives` | CopyTrust |
| Confirm that `/Volumes/Example_NAS1/Archives` exists | CopyTrust |
| Map the requested volume name to a configured share | SMB Connect |
| Choose the fastest reachable preferred or fallback network path | SMB Connect |
| Read the username and password from Keychain | SMB Connect |
| Detect duplicate mounts, wrong paths, name conflicts, and mounts held by another user | SMB Connect |
| Perform and log the mount | SMB Connect |

CopyTrust must never receive the SMB username, password, server address, share path, or list
of network endpoints. It asks for a volume. SMB Connect decides whether and how that
configured volume can be mounted.

The folder below the volume remains CopyTrust's concern. SMB Connect mounts a share, not an
individual project folder, so there is no reason to pass `Archives` or `Projects` through the
URL scheme. After the volume appears, CopyTrust checks the full path required by its preset.

---

## Plain-text example

```
CopyTrust requires:
  /Volumes/Example_NAS1/Archives
  /Volumes/Example_NAS2/Projects

Example_NAS1 is absent
  -> CopyTrust asks SMB Connect to mount volume Example_NAS1
  -> SMB Connect finds the configured share whose Mount Name is Example_NAS1
  -> SMB Connect selects its fastest reachable preferred or fallback endpoint
  -> SMB Connect mounts it using the credential in its own Keychain entry
  -> CopyTrust sees /Volumes/Example_NAS1 appear
  -> CopyTrust checks /Volumes/Example_NAS1/Archives

Example_NAS2 is absent
  -> the same independent process runs for Example_NAS2
  -> CopyTrust checks /Volumes/Example_NAS2/Projects after it appears
```

The two Macs at a facility may have different SMB Connect aliases, IP addresses, usernames,
network priorities, and available interfaces. The CopyTrust preset remains valid as long as
SMB Connect produces the stable volume names that the preset requires.

---

## Implemented contract

The original SMB Connect app registers a URL scheme that resolves to an existing configured
share rather than accepting arbitrary connection details:

```
smbconnect://v1/mount?volume=<mount name>&request=<uuid>
```

**Resolve by configured Mount Name, never by alias, server, share path, IP address, or
credentials.** Alias is an editable display label and need not be known to CopyTrust. Mount
Name is the name SMB Connect already expects to appear under `/Volumes`, which is exactly the
identity CopyTrust's portable project-root configuration knows.

A caller that could pass an arbitrary host, share or credential would turn SMB Connect into a
general-purpose mounter driven by another process. Restricting requests to Mount Names already
configured in SMB Connect keeps its configuration and Keychain as the single source of truth.

Mount Names used for external requests must be unique case-insensitively. If no configured
share matches, or more than one share claims the requested Mount Name, SMB Connect refuses the
request rather than guessing. Settings disables the external-request option for ambiguous
duplicate Mount Names.

The existing pieces map cleanly:

| Need | Already exists |
|---|---|
| Find the share | `ShareConfiguration` by `mountName` |
| Is it already mounted | `mountedURL(for:)`, `assessMounts(for:preferredEndpoint:)` |
| Mount it | `connect(share:endpoint:credential:reason:)` |
| Refuse sensibly | `volumeNameConflict(for:)`, `foreignMountConflict(for:)` |

`MountReason.externalRequest` and the caller-generated request UUID follow the attempt through
the log. That matters here more than usual: a mount that
appears without the operator touching anything should be explicable afterwards from the log
alone. The UUID correlates attempts; it does not authenticate the caller.

The request is idempotent. If the configured share is already mounted correctly, SMB Connect
logs success and does nothing. An external request may mount a missing share, but it must never
silently repair, unmount, switch endpoints, or replace an existing mount.

---

## Decisions implemented in version 1

- **Permission:** a share mounts silently only after its operator enables **Allow apps to
  request this volume**. The option is off by default. A request for any other share is refused.
- **What comes back:** the URL scheme is fire-and-forget. CopyTrust polls for the
  volume appearing, which is workable because it already watches mount state. Version 1 does
  not need a separate `status` URL: if the volume appears, CopyTrust validates its relative
  folder and refreshes the project roots; if it does not appear within a bounded interval,
  CopyTrust tells the operator to open SMB Connect for the connection details.
- **Rate and repeat:** SMB Connect coalesces one in-flight request per Mount Name, uses the same
  cross-process lock as automatic reconnect, and rechecks mount state after acquiring it.
- **Safety boundary:** an external request may mount a cleanly missing volume. It cannot repair,
  unmount, switch endpoints, replace an existing mount, or override a conflict.

---

## SMB Connect Desktop proves the integration path

SMB Connect Desktop no longer reads the password or performs a new mount itself. Its Connect
actions build the same `smbconnect://v1/mount` URL intended for CopyTrust. The original SMB
Connect app receives it, checks the per-share permission, chooses the best available network,
reads its own Keychain entry, and performs the mount.

This directly addresses the earlier Desktop deployment failure mode: installing a sibling app
no longer requires users to grant that second bundle access to every existing Keychain item or
to re-enter each server/share password. SMB Connect remains the one credential and mount
authority. Desktop shares configuration and status, can explicitly disconnect, and sends
credential editing or repair work back to the original app.

The original app can now also provide the full-window experience itself. **Settings → General
→ Show Dock icon and desktop window** changes its activation policy, displays a Dock icon and
opens the shared desktop window. This makes Desktop optional for users who only wanted a Dock
presence or more room on a laptop.

---

## What CopyTrust does at launch

Settled on the CopyTrust side 2026-08-11, recorded here so both halves of the contract sit in
one place each.

CopyTrust checks its preset's volumes **at launch**, asynchronously and without blocking the
window, so an operator learns a volume is missing while still unpacking rather than with a card
already in a reader. When something is absent it names *which* volumes and offers three
choices: **Try Again**, **Open SMB Connect**, and **Off Site — Use New Destinations**.

Two consequences for this proposal:

- **The middle option is hidden entirely when SMB Connect is not installed.** Detection is by
  what can handle the URL rather than what is on disk — `NSWorkspace.urlForApplication(toOpen:)`
  against the scheme answers "installed" and "new enough to accept a request" in one call. If an
  app is found but the scheme is not registered, CopyTrust simply opens it and lets the operator
  connect. That means shipping the scheme is **additive**: an older SMB Connect degrades to the
  behaviour that exists today rather than breaking.
- **CopyTrust will not retry in a loop.** One request, a bounded wait for the volume to appear,
  then it defers to the operator. A caller queueing attempts was listed as a concern here; it is
  answered on the calling side as well as the receiving one.

Off site the request goes unanswered by design, the bounded wait ends, and CopyTrust falls into
its declared off-site mode. Nothing about that path needs anything from this app.

---

## Cross-reference

CopyTrust's side of this is in
`Folder Copy Compare/docs/COPYTRUST_ENFORCED_NAMING_PLAN.md` — the destination flow, where an
unmounted project root is reported to the operator rather than silently producing an empty
project list.
