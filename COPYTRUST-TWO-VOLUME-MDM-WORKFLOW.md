# Two-volume CopyTrust MDM workflow

Use this workflow when CopyTrust requires two stable destinations such as:

```text
/Volumes/Example_Archive
/Volumes/Example_Projects
```

The names after `/Volumes` are the SMB Connect **Mount Names**. They must match
the names stored in CopyTrust. SMB Connect owns the server addresses, endpoint
priority, credentials, mount safety checks, and actual mounting.

## Recommended option: known preferred and fallback addresses

When IT already knows both addresses, create an 11-column inventory:

```csv
server alias,protocol,share name,mount name,user name,note,preferred ip,speed preferred,fallback ip,speed fallback,allow external mount requests
archive,smb,Archive,Example_Archive,ingest-user,Example CopyTrust archive destination,192.0.2.10,10g,198.51.100.10,1g,true
projects,smb,Projects,Example_Projects,ingest-user,Example CopyTrust projects destination,192.0.2.20,10g,198.51.100.20,1g,true
```

Use reserved documentation IPs in examples. Put real addresses only in the
private IT inventory and MDM system.

Generate setup JSON and a locked profile:

```bash
./generate_smbconnect_config.sh \
  -i ./Example-CopyTrust-Ingest.csv \
  -o ./generated/Example-CopyTrust-Ingest \
  --organization "Example Organization" \
  --identifier-prefix com.example.SMBConnect \
  --allow-user-defined false
```

Validate the exact required Mount Names before uploading the profile:

```bash
./validate_copytrust_mdm_profile.sh \
  ./generated/Example-CopyTrust-Ingest.mobileconfig \
  Example_Archive Example_Projects
```

The validator fails if either volume is missing, duplicated, or does not have
`allowExternalMountRequests = true`.

## Mount Import Assistant option

Use Mount Import Assistant when a representative Mac already mounts the shares
and IT wants to discover or confirm the share names, Mount Names, server
addresses, usernames, and interface roles.

1. Mount both required shares through a normal macOS workflow.
2. Run Mount Import Assistant and refresh the mount data.
3. Classify detected interfaces and server endpoints as preferred, fallback,
   VPN, or custom.
4. Under **CopyTrust And External Mount Requests**, enable both required
   volumes. All detected shares default off.
5. Choose whether the JSON has a blank, detected, or generic username.
6. Export JSON, CSV, and the review report.
7. Confirm the JSON contains `allowExternalMountRequests: true` for both
   required Mount Names.
8. Convert that JSON to a locked profile:

```bash
./json_to_mobileconfig.sh \
  -i ./SMBConnectSetup-ExampleMac.json \
  -o ./generated/Example-CopyTrust-Ingest.mobileconfig \
  --organization "Example Organization" \
  --allow-user-defined false
```

9. Run `validate_copytrust_mdm_profile.sh` with both required Mount Names.

Mount Import Assistant only knows endpoint addresses visible in the current
mount data. If a share is mounted only through its preferred address, the tool
cannot infer an unseen fallback address. Add the known fallback to the reviewed
JSON or use the inventory generator instead. Do not create duplicate `-1`
mounts merely to discover an address.

## Reference-Mac option

IT can configure the two shares in SMB Connect on one reference Mac, enable
**Allow apps to request this volume** for each, export setup JSON, review it,
and run `json_to_mobileconfig.sh`. The generated MDM profile—not the reference
Mac's local preferences—becomes fleet authority.

## Hand-authored profile option

IT can directly author two `ManagedShares` dictionaries. Each approved share
must contain:

```xml
<key>mountName</key>
<string>Example_Archive</string>
<key>allowExternalMountRequests</key>
<true/>
```

Use the equivalent pair for `Example_Projects`. Run both `plutil -lint` and the
CopyTrust profile validator before deployment. Hand authoring is supported but
more error-prone than generating from reviewed inventory.

## What the locked MDM profile enforces

For a centrally controlled ingest station, use:

```xml
<key>AllowUserDefinedShares</key>
<false/>
```

This makes the active share definitions come from MDM, locks their UI fields,
and prevents operators from changing the per-share authorization or endpoint
list. SMB Connect still selects the best reachable configured endpoint.

The current authorization permits a local application in the logged-in user's
session to request an approved configured volume; it is not a CopyTrust bundle
ID allowlist. The caller cannot obtain credentials, supply another server, or
force SMB Connect to repair or replace an existing mount.

## Credential and fleet requirements

MDM does not deploy SMB passwords. For every ingest login account:

1. Install SMB Connect 0.7.4 or later and start it in that user's session.
2. Confirm the managed profile appears and both shares are locked.
3. Save the credentials for both shares once in the original SMB Connect app.
4. Test each volume with preferred and fallback network availability.
5. Unmount both volumes and confirm CopyTrust can request them.
6. Export Logs and Diagnostics for the pilot evidence.

The profile validator proves the profile artifact contains both permissions.
MDM inventory or compliance reporting must separately prove the intended
profile revision reached every target Mac. Password enrollment remains per
macOS user and per Mac because credentials are stored in that user's Keychain.

## Production checklist

- [ ] Both Mount Names exactly match the CopyTrust configuration.
- [ ] Both shares have `allowExternalMountRequests = true`.
- [ ] All other shares are explicitly false or absent.
- [ ] Preferred and fallback endpoint priorities are correct.
- [ ] `AllowUserDefinedShares` matches IT policy; use `false` for locked ingest stations.
- [ ] The generated profile passes `plutil -lint`.
- [ ] The CopyTrust profile validator passes with both Mount Names.
- [ ] MDM reports the intended profile revision on every target Mac.
- [ ] Each ingest user has saved both passwords in SMB Connect's Keychain.
- [ ] CopyTrust succeeds with both volumes initially unmounted.
- [ ] Fallback-network and rollback tests pass.

See [CopyTrust and SMB Connect MDM deployment plan](COPYTRUST-MDM-DEPLOYMENT-PLAN.md)
for the complete security boundary and acceptance matrix.
