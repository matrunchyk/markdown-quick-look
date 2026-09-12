#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data="$project_root/.build/DerivedData"
product="$derived_data/Build/Products/Release/MarkdownQuickLook.app"
marketing_version="${MARKETING_VERSION:-1.1}"
build_number="${CURRENT_PROJECT_VERSION:-2}"

xcodebuild \
  -project "$project_root/MarkdownQuickLook.xcodeproj" \
  -scheme MarkdownQuickLook \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data" \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM= \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="$marketing_version" \
  CURRENT_PROJECT_VERSION="$build_number" \
  build

codesign --verify --deep --strict "$product"
echo "Built: $product"
