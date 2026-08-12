#!/bin/bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  validate_copytrust_mdm_profile.sh PROFILE.mobileconfig MOUNT_NAME [MOUNT_NAME ...]

Validates the exact SMB Connect profile intended for CopyTrust deployment.
Every required Mount Name must appear exactly once in ManagedShares and have
allowExternalMountRequests=true. The profile must also be valid plist data.

Example:
  ./scripts/validate_copytrust_mdm_profile.sh \
    ./Config/generated/Example-Ingest.mobileconfig \
    Example_Archive Example_Projects
EOF
}

[[ $# -ge 2 ]] || { usage >&2; exit 2; }

PROFILE_PATH="$1"
shift

[[ -f "$PROFILE_PATH" ]] || { echo "ERROR: profile not found: $PROFILE_PATH" >&2; exit 1; }
plutil -lint "$PROFILE_PATH" >/dev/null

PROFILE_PATH="$PROFILE_PATH" REQUIRED_MOUNTS="$(printf '%s\n' "$@")" python3 - <<'PY'
import os
import plistlib
import sys

profile_path = os.environ["PROFILE_PATH"]
required = [value for value in os.environ["REQUIRED_MOUNTS"].splitlines() if value]

with open(profile_path, "rb") as handle:
    profile = plistlib.load(handle)

payloads = [
    payload for payload in profile.get("PayloadContent", [])
    if payload.get("PayloadType") == "com.matx.SMBConnect"
]
if len(payloads) != 1:
    print("ERROR: expected exactly one com.matx.SMBConnect payload", file=sys.stderr)
    sys.exit(1)

shares = payloads[0].get("ManagedShares")
if not isinstance(shares, list):
    print("ERROR: ManagedShares is missing or is not an array", file=sys.stderr)
    sys.exit(1)

by_name = {}
errors = []
for index, share in enumerate(shares, start=1):
    name = share.get("mountName") or share.get("shareName")
    if not isinstance(name, str) or not name.strip():
        errors.append(f"ManagedShares[{index}] has no usable Mount Name")
        continue
    normalized = name.strip().casefold()
    by_name.setdefault(normalized, []).append((name.strip(), share))

for normalized, matches in by_name.items():
    if len(matches) > 1:
        errors.append(f"duplicate Mount Name (case-insensitive): {matches[0][0]}")

for wanted in required:
    matches = by_name.get(wanted.strip().casefold(), [])
    if not matches:
        errors.append(f"required Mount Name is absent: {wanted}")
        continue
    if len(matches) != 1:
        continue
    actual_name, share = matches[0]
    if share.get("allowExternalMountRequests") is not True:
        errors.append(
            f"required Mount Name is not opted in: {actual_name} "
            "(allowExternalMountRequests must be true)"
        )

if errors:
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(1)

print(f"PASS: {profile_path}")
print(f"  SMB Connect managed shares: {len(shares)}")
print(f"  CopyTrust-required shares enabled: {len(required)}")
for name in required:
    print(f"  - {name}")
PY
