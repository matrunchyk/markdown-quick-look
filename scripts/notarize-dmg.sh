#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 || ! -f "$1" || -z "$2" ]]; then
  echo "Usage: $0 <dmg-path> <developer-id-identity>" >&2
  exit 2
fi

: "${NOTARY_KEY_PATH:?NOTARY_KEY_PATH is required}"
: "${NOTARY_KEY_ID:?NOTARY_KEY_ID is required}"
: "${NOTARY_ISSUER_ID:?NOTARY_ISSUER_ID is required}"

dmg_path="$1"
signing_identity="$2"

codesign \
  --force \
  --sign "$signing_identity" \
  --timestamp \
  "$dmg_path"
codesign --verify --strict --verbose=2 "$dmg_path"

xcrun notarytool submit "$dmg_path" \
  --key "$NOTARY_KEY_PATH" \
  --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER_ID" \
  --wait \
  --timeout 30m

xcrun stapler staple --verbose "$dmg_path"
xcrun stapler validate --verbose "$dmg_path"
/usr/sbin/spctl --assess \
  --type open \
  --context context:primary-signature \
  --verbose=2 \
  "$dmg_path"
