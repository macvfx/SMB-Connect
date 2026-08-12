# CopyTrust and SMB Connect MDM deployment plan

**Purpose:** let IT centrally declare which managed SMB Connect volumes may be
mounted when CopyTrust reports them missing.

**Baseline:** SMB Connect 0.7.4 (build 27)

**Status:** the app-side MDM key is shipped. The repository generators,
fictional examples, schema documentation, and pre-deployment profile validator
now preserve and check the policy. Fleet deployment and MDM inventory evidence
still require an IT-controlled pilot.

This permission authorizes a mount request. It does not give CopyTrust the SMB
password, endpoint list, share address, or access beyond the permissions of the
SMB account used by SMB Connect.

## Current capability in 0.7.4

SMB Connect already reads this optional boolean from each dictionary in the
managed `ManagedShares` array:

```xml
<key>allowExternalMountRequests</key>
<true/>
```

The behavior is:

- `true`: the original SMB Connect app may satisfy an external request for that
  configured share's unique Mount Name;
- `false` or absent: external requests for that share are refused;
- managed shares are locked in Settings, so the operator cannot change the
  value delivered by MDM;
- the original SMB Connect app still chooses the endpoint, reads its own
  Keychain item, checks mount conflicts, performs the mount, and writes the log;
- both SMB Connect applications read the same managed preference domain,
  `com.matx.SMBConnect`; and
- profile changes are picked up by the normal live configuration refresh.

The permission is per managed share. `AllowUserDefinedShares` is a separate
top-level policy controlling whether operators can also maintain local shares.

## Important authorization boundary

The released v1 URL is not authenticated as coming from CopyTrust. Setting
`allowExternalMountRequests` to `true` currently means:

> Allow a local application in this user's login session to ask SMB Connect to
> mount this already configured volume.

It does not mean “CopyTrust exclusively.” The requester cannot provide a
server, obtain a password, force a repair, or mount an unconfigured share, but
it can cause an approved missing volume to be mounted.

IT must make this explicit decision before deployment:

| Policy choice | Required work |
|---|---|
| The current local-request boundary is acceptable | Complete the profile tooling and deployment work in this plan. |
| Only signed CopyTrust builds may request mounts | Design authenticated IPC, such as an XPC service that validates the caller's audit token and code signature. A URL scheme alone is not a reliable caller identity. |

Do not describe the current boolean as a CopyTrust bundle-ID allowlist.

## Interim profile for a controlled test

IT can add the key manually or generate it from an approved JSON/CSV source.
Use fictional values as a template and replace them only in the private MDM
console:

```xml
<key>AllowUserDefinedShares</key>
<false/>

<key>ManagedShares</key>
<array>
  <dict>
    <key>alias</key>
    <string>Example Archive</string>
    <key>protocol</key>
    <string>smb</string>
    <key>shareName</key>
    <string>Archive</string>
    <key>mountName</key>
    <string>Example_Archive</string>
    <key>defaultUsername</key>
    <string>ingest-user</string>
    <key>allowExternalMountRequests</key>
    <true/>
    <key>endpoints</key>
    <array>
      <dict>
        <key>serverIP</key>
        <string>192.0.2.50</string>
        <key>networkType</key>
        <string>10gbe</string>
        <key>priority</key>
        <integer>0</integer>
        <key>subnetPrefix</key>
        <integer>24</integer>
        <key>label</key>
        <string>Example preferred network</string>
      </dict>
    </array>
  </dict>
</array>
```

Set the boolean to `false`, or omit it, for every share that must not respond to
external requests. For a centrally controlled ingest station, set
`AllowUserDefinedShares` to `false`. If it is `true`, operators may add local
shares and control the same opt-in on those local definitions.

Validate the completed profile before uploading it:

```bash
plutil -lint Example-SMBConnect.mobileconfig
```

The actual profile must remain private because it contains internal addresses,
share names, usernames, and deployment identifiers even though it contains no
password.

## Repository tooling now available

Both configuration generators preserve `allowExternalMountRequests` per share.
The CSV/TXT generator accepts either its legacy ten columns (safe default:
`false`) or an eleventh boolean column. The JSON converter rejects non-boolean
values and defaults an absent value to `false`.

Before uploading a generated profile, validate every CopyTrust-required Mount
Name explicitly:

```bash
./validate_copytrust_mdm_profile.sh \
  ./generated/Example-Ingest.mobileconfig \
  Example_Archive Example_Projects
```

The command fails when the plist is invalid, the SMB Connect payload is absent,
a required Mount Name is missing or duplicated, or an expected share does not
have `allowExternalMountRequests = true`.

This proves the content of the profile artifact. It does not prove that MDM
installed the correct revision on every target Mac; use MDM inventory/reporting
and the pilot checks below for that evidence.

Mount Import Assistant 0.5 also exports the boolean. Its detected shares default
off; IT enables only the required volumes, reviews the JSON/CSV/report, converts
the JSON with `json_to_mobileconfig.sh`, and runs the same profile validator.

## Work required before general deployment

### 1. Keep the configuration schema synchronized

`docs/CONFIGURATION-FORMAT.md` now defines
`allowExternalMountRequests` for:

- setup JSON share dictionaries;
- MDM `ManagedShares` dictionaries;
- the default of `false` when absent; and
- the difference between this per-share boolean and the top-level
  `AllowUserDefinedShares` policy.

Keep it, the User Guide, generator READMEs, and examples synchronized whenever
the policy changes.

### 2. Maintain the JSON-to-profile converter

`json_to_mobileconfig.sh` now:

- accepts only a JSON boolean;
- copies it into the matching managed share;
- defaults it to `false` when absent;
- preserves independent values for different shares; and
- documents the mapping in `README-json-to-mobileconfig.md`.

### 3. Maintain the CSV/TXT configuration generator

`generate_smbconnect_config.sh` accepts an optional per-share column:

```text
allowExternalMountRequests
```

For backward compatibility, it accepts the existing ten-column format as
`false`, and accepts an eleven-column format whose final value is normalized
from `true/false`, `yes/no`, or `1/0`. It emits the boolean in both the setup
JSON and `.mobileconfig` output. Keep these related artifacts synchronized:

- `README-config-generator.md`;
- `examples/server-shares-example.csv`;
- `examples/server-shares-example.txt`;
- the device-inventory template and its documentation; and
- generator validation messages and examples.

### 4. Keep checked-in examples fictional and current

Explicit fictional `true` and `false` examples now exist in:

- `examples/com.matx.SMBConnect.mobileconfig`; and
- `examples/SMBConnectSetup-EXAMPLE.json`.

Examples must make clear that only selected destinations are externally
requestable. Do not add real facility shares, addresses, usernames, or profile
identifiers to public documentation.

### 5. Complete automated regression coverage

The app tests and `test_copytrust_mdm_tooling.sh` now prove:

- the MDM reader maps `true` to an opted-in managed share;
- an absent or malformed value is safely `false`;
- two managed shares can have different values;
- managed share definitions, including this policy, are locked against local UI changes;
- JSON export/import preserves the boolean;
- the JSON-to-profile converter preserves the boolean;
- the CSV generator emits it into both outputs and defaults old ten-column
  input to `false`; and
- a generated profile passes `plutil -lint`.

Run both before publishing profile tooling:

```bash
xcodebuild -project SMBConnect.xcodeproj \
  -scheme SMBConnect \
  -destination 'platform=macOS' test

./test_copytrust_mdm_tooling.sh
```

Retain the existing URL-contract tests proving that connection details are
rejected and ambiguous Mount Names are refused.

### 6. Decide the credential enrollment workflow

MDM intentionally does not contain SMB passwords. `defaultUsername` may be
managed, but the password remains in the current macOS user's Keychain and is
read only by the original SMB Connect app.

Before deployment, IT must choose and document one of these workflows:

1. An operator signs in once and uses **Save Credentials** in SMB Connect for
   every managed share.
2. IT develops a separate approved credential-provisioning mechanism with an
   appropriate security review.

The current application requires a saved Keychain credential before an
external request can mount a missing share. Deploying the profile alone is not
zero-touch credential provisioning.

### 7. Deploy the original SMB Connect app as infrastructure

CopyTrust depends on the original SMB Connect app, not SMB Connect Desktop, for
mount authority. The managed ingest-Mac deployment must ensure:

- SMB Connect 0.7.4 or later is installed;
- SMB Connect starts in the ingest user's login session;
- the `com.matx.SMBConnect` managed preference payload is installed;
- managed Mount Names exactly match the volume names in CopyTrust presets;
- CopyTrust's required relative folders are created and permissioned on the
  share; and
- endpoint priorities represent IT's desired fastest-to-slowest order.

Where the MDM product supports it, target the policy to the ingest-device
group. Verify how that product applies custom managed preferences to multiple
local users; passwords remain per-user regardless of device-level policy.

### 8. Add CopyTrust integration

CopyTrust must adopt the reference client in
`examples/CopyTrustSMBConnectClient` and retain these responsibilities:

- derive the Mount Name from `/Volumes/<Mount Name>/<relative folder>`;
- request only a missing volume;
- send one request and wait for a bounded interval;
- validate the complete relative folder after the volume appears;
- never read SMB Connect's Keychain items;
- never retry continuously; and
- retain manual and off-site destination choices.

See [CopyTrust integration with SMB Connect](COPYTRUST-SMB-CONNECT-INTEGRATION.md)
for the caller contract and UI outcomes.

## Lab acceptance before production

Use a disposable device group and fictional test shares. Record the profile
revision, SMB Connect version/build, CopyTrust build, macOS version, and result
for every case.

| Test | Expected evidence |
|---|---|
| Profile installation | `ManagedShares` is forced in `com.matx.SMBConnect`; managed share UI is locked. |
| Approved share | Disabled volume is missing, CopyTrust sends one request, and SMB Connect mounts it using the best reachable endpoint. |
| Unapproved share | Request times out; SMB Connect logs that external requests are not enabled. |
| Mixed policy | An approved and unapproved managed share retain different boolean values. |
| Missing credential | No mount occurs; diagnostics say that credentials must be saved. |
| Duplicate Mount Name | No mount occurs; ambiguity is reported. |
| Wrong or conflicting mount | No automatic repair or replacement occurs. |
| Preferred network unavailable | SMB Connect selects the configured reachable fallback. |
| Profile update | Changing the managed boolean takes effect without allowing a local override. |
| Profile removal | Managed definitions disappear and the documented local-share policy is restored. |
| Second macOS user | Managed policy scope is verified; separate Keychain enrollment is required. |

Export **Logs and Diagnostics** after the approved, refused, and fallback tests.
Confirm the request UUID is present and that the export contains no passwords.

## Production rollout gate

General deployment is ready only when:

- IT accepts either the current local-request security boundary or a signed
  CopyTrust-only IPC design has shipped;
- both generators preserve the per-share boolean;
- schema, user-guide, and example documentation agree;
- automated tests pass;
- a generated profile passes `plutil -lint`;
- the credential enrollment procedure is approved;
- the complete lab matrix passes on the intended macOS version; and
- rollback has been tested by setting the boolean to `false` and by removing
  the profile.

Do not describe the workflow as centrally deployed and ready until these gates
are satisfied.
