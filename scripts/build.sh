#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data="$project_root/.build/DerivedData"
product="$derived_data/Build/Products/Release/MarkdownQuickLook.app"
marketing_version="${MARKETING_VERSION:-1.1}"
build_number="${CURRENT_PROJECT_VERSION:-2}"
signing_identity="${CODE_SIGN_IDENTITY:-${SIGNING_IDENTITY:--}}"
development_team="${DEVELOPMENT_TEAM:-}"
timestamp_flags=""

if [[ "$signing_identity" != "-" ]]; then
  timestamp_flags="--timestamp"
fi

xcodebuild \
  -project "$project_root/MarkdownQuickLook.xcodeproj" \
  -scheme MarkdownQuickLook \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGN_IDENTITY="$signing_identity" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="$development_team" \
  OTHER_CODE_SIGN_FLAGS="$timestamp_flags" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="$marketing_version" \
  CURRENT_PROJECT_VERSION="$build_number" \
  build

codesign --verify --deep --strict --verbose=2 "$product"
echo "Built: $product"
