#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h}"
scratch_dir="${LABRAT_TEST_DIR:-$(mktemp -d -t labrat-tests)}"
mkdir -p "$scratch_dir/cache/clang" "$scratch_dir/cache/swiftpm"
export CLANG_MODULE_CACHE_PATH="$scratch_dir/cache/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$scratch_dir/cache/clang"
swift test --package-path "$project_dir" --scratch-path "$scratch_dir/build" --cache-path "$scratch_dir/cache/swiftpm" --disable-sandbox --build-system native
