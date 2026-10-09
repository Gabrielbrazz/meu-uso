#!/usr/bin/env bash
# Compile the Liquid Glass app icon (assets/AppIcon.icon) into assets/AppIcon.prebuilt/Assets.car.
#
# Why this exists: actool in the Xcode versions on GitHub's macOS runners (26.4.1 and 26.5) crashes
# compiling Icon Composer files (Apple regression FB20183399 — 26.5 crashes even on an empty icon.json).
# Older actool (e.g. Xcode 26.2) works. Run this on a Mac whose actool can read the .icon and commit the
# resulting Assets.car; builds then add it on top of the classic AppIcon.icns, which this script leaves
# alone (that one comes from script/brand/mark.py --icns).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT_DIR/assets/AppIcon.prebuilt"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
xcrun actool "$ROOT_DIR/assets/AppIcon.icon" --compile "$WORK" \
  --app-icon AppIcon --enable-on-demand-resources NO --development-region en \
  --target-device mac --platform macosx --minimum-deployment-target 15.0 \
  --output-partial-info-plist /dev/null --output-format human-readable-text --errors --warnings
mkdir -p "$OUT"
cp "$WORK/Assets.car" "$OUT/Assets.car"

echo "Wrote $OUT/Assets.car"
