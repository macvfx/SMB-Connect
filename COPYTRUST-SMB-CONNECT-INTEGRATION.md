# CopyTrust integration with SMB Connect

**Reference contract:** SMB Connect 0.7.4 (build 27)

**Validation status:** the SMB Connect / SMB Connect Desktop delegation path was manually proven on a separate test Mac on 2026-08-11.

**CopyTrust status:** reference client supplied here; CopyTrust adoption remains a separate change.

## Purpose

CopyTrust knows the destination it requires, for example:

```text
/Volumes/Example_NAS1/Archives
```

It does not need to know whether `Example_NAS1` is currently reachable through
10GbE, 1GbE, Wi-Fi, a VPN, or a different address at another facility. If the
volume is missing, CopyTrust can ask SMB Connect to mount the configured volume
whose **Mount Name** is `Example_NAS1`.

SMB Connect remains the only owner of:

- server and share addresses;
- endpoint preference and reachability;
- SMB usernames and Keychain passwords;
- duplicate-mount, wrong-path, and other-user conflict handling; and
- the actual mount operation and its diagnostic log.

CopyTrust owns the required volume and relative folder, sends one request, and
checks the filesystem for the result.

## Reference client

The standalone Swift package is in
[`examples/CopyTrustSMBConnectClient`](examples/CopyTrustSMBConnectClient).
Its production implementation is one source file, so CopyTrust can either add
the package as a local dependency during development or copy
`SMBConnectMountClient.swift` into its own integration layer.

The client deliberately contains no SMB implementation. It:

1. validates that the required directory is below `/Volumes/<Mount Name>`;
2. returns immediately if the full directory already exists;
3. reports a missing relative folder without remounting an existing volume;
4. checks whether macOS has an application registered for the released URL;
5. sends exactly one request;
6. waits for the complete required directory for a bounded interval; and
7. returns an outcome for CopyTrust's UI.

## Basic CopyTrust use

```swift
import SMBConnectMountClient

let requiredDirectory = URL(
    fileURLWithPath: "/Volumes/Example_NAS1/Archives",
    isDirectory: true
)
let requirement = try SMBConnectMountRequirement(
    requiredDirectory: requiredDirectory
)
let outcome = await SMBConnectMountClient().ensureAvailable(
    requirement,
    timeout: 15
)

switch outcome {
case .alreadyAvailable, .mounted:
    // Refresh CopyTrust destinations and continue its normal preflight.
    break

case .volumeAvailableButFolderMissing:
    // Name the missing folder. Do not ask SMB Connect to remount the volume.
    break

case .smbConnectUnavailable:
    // Hide Open SMB Connect; offer Try Again and off-site destinations.
    break

case .requestCouldNotBeOpened, .timedOut:
    // Offer Try Again, Open SMB Connect, and off-site destinations.
    break

case .cancelled:
    // The task or owning view ended; do not display a stale alert.
    break
}
```

Call this asynchronously during CopyTrust launch preflight. Do not block the
main window and do not start an automatic retry loop.

## Released URL contract

```text
smbconnect://v1/mount?volume=Example_NAS1&request=<uuid>
```

Only the configured Mount Name and a caller-generated correlation UUID cross
the application boundary. The request contains no alias, relative folder,
server, share path, endpoint, username, or password.

The UUID appears in SMB Connect's log. It correlates an attempt but does not
authenticate the caller.

Version 1 is fire-and-forget. A timeout therefore means only that the required
volume did not appear during the bounded wait. It does not prove whether SMB
Connect refused the request, lacked credentials, found no reachable endpoint,
or encountered a mount conflict. The operator can use **Help → Export Logs and
Diagnostics…** in SMB Connect for that detail.

## Required SMB Connect setup

For each CopyTrust destination volume:

1. Add the share to the original SMB Connect app.
2. Set its unique **Mount Name** to the name CopyTrust expects below `/Volumes`.
3. Save its credentials in the original app.
4. Enable **Allow apps to request this volume**.
5. Confirm that no second share has the same Mount Name, ignoring case.

The option is off by default. Older share JSON also decodes with external
requests off, so installing 0.7.4 does not silently grant this permission.

IT can control the same value per managed share with the MDM
`allowExternalMountRequests` boolean. The app already reads that key, but the
profile generators and deployment documentation still need production work.
See the [CopyTrust and SMB Connect MDM deployment plan](COPYTRUST-MDM-DEPLOYMENT-PLAN.md)
before a managed rollout.

## CopyTrust launch behavior

For each configured destination:

```text
Required directory exists
  -> continue normal CopyTrust preflight

Volume exists but relative folder is missing
  -> report the missing folder
  -> do not request a remount

Volume is missing and SMB Connect handles the URL
  -> send one request
  -> wait up to the CopyTrust timeout
  -> refresh destinations if the complete directory appears

Volume remains missing
  -> Try Again
  -> Open SMB Connect
  -> Off Site — Use New Destinations
```

If no application handles the request URL, omit **Open SMB Connect**. CopyTrust
must retain its existing manual/off-site path so SMB Connect stays an optional
integration rather than a requirement.

## Safety boundaries

An external request may mount a cleanly missing, explicitly permitted volume.
It cannot ask SMB Connect to:

- connect to an arbitrary server;
- receive or replace credentials;
- repair or unmount an existing volume;
- switch an already-mounted share to another endpoint;
- override a duplicate or foreign-user conflict; or
- create or validate CopyTrust's relative destination folder.

Those refusals are intentional. CopyTrust should identify what is missing and
send the operator to SMB Connect when the storage state needs intervention.

## Acceptance checks for CopyTrust

Use fictional test shares and paths. The integration is ready when these checks
pass on a Mac with SMB Connect 0.7.4 or later:

| Case | Expected CopyTrust behavior |
|---|---|
| Required directory already exists | No URL is opened; preflight continues |
| Volume mounted, relative folder missing | Folder-specific warning; no remount request |
| Allowed volume missing | One request; destination refreshes after mount |
| External requests disabled | Bounded wait, then operator choices |
| No saved SMB credential | Bounded wait, then operator choices; SMB Connect diagnostics explain why |
| No reachable endpoint | Bounded wait, then operator choices |
| Duplicate Mount Name | Request is refused; SMB Connect identifies ambiguity |
| Existing wrong or conflicting mount | No automatic repair; operator opens SMB Connect |
| SMB Connect not installed | No request and no Open SMB Connect button |
| CopyTrust preflight is cancelled | Polling stops without a stale alert |

Also verify that no CopyTrust code reads SMB Connect Keychain items and that a
new CopyTrust build never prompts users to re-enter SMB passwords.
