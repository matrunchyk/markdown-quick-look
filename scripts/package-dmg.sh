#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  echo "Usage: $0 <numeric-version>" >&2
  exit 2
fi

project_root="$(cd "$(dirname "$0")/.." && pwd)"
product="$project_root/.build/DerivedData/Build/Products/Release/MarkdownQuickLook.app"
release_dir="$project_root/.build/releases"
output="$release_dir/MarkdownQuickLook-$1-universal.dmg"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/markdown-quick-look-dmg.XXXXXX")"
trap 'rm -rf "$staging_dir"' EXIT

if [[ ! -d "$product" ]]; then
  echo "App not found. Run ./scripts/build.sh first." >&2
  exit 1
fi

mkdir -p "$release_dir"
/usr/bin/ditto "$product" "$staging_dir/MarkdownQuickLook.app"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
  -volname "Markdown Quick Look" \
  -srcfolder "$staging_dir" \
  -format UDZO \
  -ov \
  "$output"
hdiutil verify "$output"

echo "Packaged: $output"
