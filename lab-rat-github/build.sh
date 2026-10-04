#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h}"
app_path="${1:-${project_dir}/dist/Lab Rat.app}"
scratch_dir="${LABRAT_BUILD_DIR:-$(mktemp -d -t labrat-build)}"
mkdir -p "$scratch_dir/cache/clang" "$scratch_dir/cache/swiftpm"
export CLANG_MODULE_CACHE_PATH="$scratch_dir/cache/clang"
export SWIFTPM_MODULECACHE_OVERRIDE="$scratch_dir/cache/clang"
swift build --package-path "$project_dir" --scratch-path "$scratch_dir/build" --cache-path "$scratch_dir/cache/swiftpm" --disable-sandbox --build-system native -c release
bin_path=$(swift build --package-path "$project_dir" --scratch-path "$scratch_dir/build" --cache-path "$scratch_dir/cache/swiftpm" --disable-sandbox --build-system native -c release --show-bin-path)
mkdir -p "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
cp "$bin_path/LabRat" "$app_path/Contents/MacOS/LabRat"
cp "$project_dir/Info.plist" "$app_path/Contents/Info.plist"
swift "$project_dir/Tools/MakeIcon.swift" "$scratch_dir/LabRat.iconset" "$app_path/Contents/Resources/LabRat.icns"
# Bundle metadata may be added by Finder on Desktop/Documents folders.
xattr -cr "$app_path"
codesign --force --sign - "$app_path"
# File-provider folders can restore top-level Finder metadata after recursive clearing.
xattr -d com.apple.FinderInfo "$app_path" 2>/dev/null || true
codesign --verify --deep --strict "$app_path"
echo "Built: $app_path"
