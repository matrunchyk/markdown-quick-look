#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$project_root/.build/Tests"
module_cache="$test_dir/ModuleCache"

mkdir -p "$module_cache"

CLANG_MODULE_CACHE_PATH="$module_cache" \
SWIFT_MODULECACHE_PATH="$module_cache" \
swiftc -parse-as-library \
  "$project_root/MarkdownPreview/MarkdownRenderer.swift" \
  "$project_root/Tests/RendererSmoke.swift" \
  -o "$test_dir/renderer-smoke"

"$test_dir/renderer-smoke"
