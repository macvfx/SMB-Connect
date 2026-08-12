#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
TEST_DIR="$(mktemp -d /private/tmp/smbconnect-mdm-tooling.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

"$SCRIPT_DIR/generate_smbconnect_config.sh" \
  -i "$SCRIPT_DIR/examples/server-shares-example.csv" \
  -o "$TEST_DIR/generated" \
  --organization "Example Organization" \
  --identifier-prefix com.example.SMBConnect \
  --allow-user-defined false >/dev/null

plutil -lint "$TEST_DIR/generated.mobileconfig" >/dev/null
"$SCRIPT_DIR/validate_copytrust_mdm_profile.sh" \
  "$TEST_DIR/generated.mobileconfig" Example_Archive Example_Camera >/dev/null

"$SCRIPT_DIR/json_to_mobileconfig.sh" \
  -i "$TEST_DIR/generated.json" \
  -o "$TEST_DIR/converted.mobileconfig" \
  --organization "Example Organization" \
  --allow-user-defined false >/dev/null

plutil -lint "$TEST_DIR/converted.mobileconfig" >/dev/null
"$SCRIPT_DIR/validate_copytrust_mdm_profile.sh" \
  "$TEST_DIR/converted.mobileconfig" Example_Archive Example_Camera >/dev/null

cat > "$TEST_DIR/legacy.csv" <<'EOF'
legacy,smb,Archive,Legacy_Archive,example-user,Legacy row,192.0.2.40,10g,198.51.100.40,1g
EOF
"$SCRIPT_DIR/generate_smbconnect_config.sh" \
  -i "$TEST_DIR/legacy.csv" \
  -o "$TEST_DIR/legacy" >/dev/null

legacy_value="$(plutil -extract PayloadContent.0.ManagedShares.0.allowExternalMountRequests raw -o - "$TEST_DIR/legacy.mobileconfig")"
[[ "$legacy_value" == "false" ]] || fail "legacy ten-column input did not default external requests off"
if "$SCRIPT_DIR/validate_copytrust_mdm_profile.sh" "$TEST_DIR/legacy.mobileconfig" Legacy_Archive >/dev/null 2>&1; then
  fail "validator accepted a required share whose external requests were disabled"
fi

cat > "$TEST_DIR/bad.csv" <<'EOF'
bad,smb,Archive,Bad_Archive,example-user,Bad boolean,192.0.2.41,10g,198.51.100.41,1g,maybe
EOF
if "$SCRIPT_DIR/generate_smbconnect_config.sh" -i "$TEST_DIR/bad.csv" -o "$TEST_DIR/bad" >/dev/null 2>&1; then
  fail "CSV generator accepted an invalid external-request boolean"
fi

cat > "$TEST_DIR/bad.json" <<'EOF'
{
  "configDate": "20260811",
  "shares": [{
    "alias": "Example",
    "shareName": "Archive",
    "mountName": "Bad_Archive",
    "allowExternalMountRequests": "true",
    "endpoints": [{"serverIP": "192.0.2.42", "networkType": "10gbe"}]
  }]
}
EOF
if "$SCRIPT_DIR/json_to_mobileconfig.sh" -i "$TEST_DIR/bad.json" -o "$TEST_DIR/bad.mobileconfig" >/dev/null 2>&1; then
  fail "JSON converter accepted a non-boolean external-request value"
fi

"$SCRIPT_DIR/validate_copytrust_mdm_profile.sh" \
  "$REPO_ROOT/examples/com.matx.SMBConnect.mobileconfig" Outputs >/dev/null

echo "PASS: CopyTrust MDM profile tooling"
echo "  CSV to profile preserves independent policy"
echo "  JSON to profile preserves independent policy"
echo "  legacy input defaults to false"
echo "  malformed booleans and unapproved required shares fail closed"
