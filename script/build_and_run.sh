#!/usr/bin/env bash
set -euo pipefail

# Builds Meu Uso, stages a signed .app bundle under dist/, and launches it in place — no install
# to /Applications. The dev build:
#   - is signed with a stable Apple Development identity, so keychain/permission grants stick across
#     rebuilds (macOS keys those to the signing identity + bundle id, not the install location);
#   - uses its own bundle id (io.github.gabrielbrazz.meuuso.dev), so it never touches the real installed
#     app's settings or keychain. To run against the real app's data instead, set BUNDLE_ID to
#     io.github.gabrielbrazz.meuuso below;
#   - ships no Sparkle feed, so it never checks for or installs updates (test updates with a real
#     signed + notarized release build — that's the only honest way).
#
# Usage: script/build_and_run.sh [run|build|logs|verify]
# Env:   CODESIGN_IDENTITY  override signing identity (exact name or hash)
#        CONFIG             "release" (default) or "debug"
#        APP_VERSION / APP_BUILD / APP_VERSION_SUFFIX  version stamped into Info.plist (dev: 0.1.0-dev)
#        DISTRIBUTION       "dev" (default) or "terminal" — the GitHub release installed by
#                         script/install.sh, which tells the app to point updates at that script
#        UNIVERSAL=1        build arm64 + x86_64 slices (the terminal release ships universal)
#        SIGN_ENTITLEMENTS  entitlements for the ad-hoc / development signature
#        ICLOUD_PROVISIONING_PROFILE  optional override for the development provisioning profile;
#                         otherwise the newest matching installed profile is selected automatically

MODE="${1:-run}"
CONFIG="${CONFIG:-release}"

TARGET_NAME="MeuUso"                 # SwiftPM target / binary name
APP_DISPLAY="MeuUso"                 # user-facing app name
BUNDLE_ID="${BUNDLE_ID:-io.github.gabrielbrazz.meuuso.dev}"
ICLOUD_CONTAINER_ID="iCloud.$BUNDLE_ID"
MIN_SYSTEM_VERSION="15.0"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BUILD="${APP_BUILD:-0.1.0}"
APP_VERSION_SUFFIX="${APP_VERSION_SUFFIX--dev}"
DISTRIBUTION="${DISTRIBUTION:-dev}"
UNIVERSAL="${UNIVERSAL:-0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_DISPLAY.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_HELPERS="$APP_CONTENTS/Helpers"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$TARGET_NAME"
CLI_BINARY="$APP_HELPERS/meu-uso"
INFO_PLIST="$APP_CONTENTS/Info.plist"
RESOURCE_BUNDLE_NAME="${TARGET_NAME}_${TARGET_NAME}.bundle"
ENTITLEMENTS="$ROOT_DIR/script/MeuUso.dev.entitlements.plist"
SIGN_ENTITLEMENTS="${SIGN_ENTITLEMENTS:-$ROOT_DIR/script/MeuUso.local.entitlements.plist}"

# Match the staged binary path, not the bare process name, so an installed app with the same
# executable name is never touched.
pkill -f "$APP_BINARY" >/dev/null 2>&1 || true

# ARCH_FLAGS is word-split on purpose (empty for a host-arch build). With several --arch, SwiftPM
# lipo-merges the slices and --show-bin-path resolves to the merged products dir (same as release.sh).
ARCH_FLAGS=""
if [ "$UNIVERSAL" = "1" ]; then
  ARCH_FLAGS="--arch arm64 --arch x86_64"
  echo "==> swift build ($CONFIG, universal arm64 + x86_64)"
  # shellcheck disable=SC2086
  swift build -c "$CONFIG" $ARCH_FLAGS --product "$TARGET_NAME"
  # shellcheck disable=SC2086
  swift build -c "$CONFIG" $ARCH_FLAGS --product meu-uso-cli
else
  echo "==> swift build ($CONFIG)"
  swift build -c "$CONFIG"
fi
# shellcheck disable=SC2086
BUILD_DIR="$(swift build -c "$CONFIG" $ARCH_FLAGS --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$TARGET_NAME"
BUILD_CLI_BINARY="$BUILD_DIR/meu-uso-cli"

if [ ! -x "$BUILD_BINARY" ]; then
  echo "missing built binary: $BUILD_BINARY" >&2
  exit 1
fi
if [ ! -x "$BUILD_CLI_BINARY" ]; then
  echo "missing built CLI: $BUILD_CLI_BINARY" >&2
  exit 1
fi

echo "==> staging $APP_BUNDLE"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_HELPERS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$BUILD_CLI_BINARY" "$CLI_BINARY"
chmod +x "$APP_BINARY"
chmod +x "$CLI_BINARY"
# The shared module links Sparkle even though the one-shot CLI never initializes the updater. Helpers
# sit one directory below Contents, so give dyld the same embedded-framework location as the app binary.
install_name_tool -add_rpath "@executable_path/../Frameworks" "$CLI_BINARY"
if [ "$UNIVERSAL" = "1" ]; then
  for binary in "$APP_BINARY" "$CLI_BINARY"; do
    lipo -archs "$binary" | grep -q "x86_64" && lipo -archs "$binary" | grep -q "arm64" \
      || { echo "Expected a universal (arm64 + x86_64) binary, got: $(lipo -archs "$binary")" >&2; exit 1; }
  done
fi

# SwiftPM stamps LC_BUILD_VERSION's `sdk` field with the deployment target (macOS 15), not the real
# SDK it compiled against. macOS gates the modern Liquid Glass control appearance (pop-up buttons,
# pickers, etc.) on the linked SDK — a "15.0" stamp makes AppKit fall back to legacy Aqua controls.
# Restamp the sdk to 26.0 (Tahoe, where Liquid Glass landed) while keeping minos at MIN_SYSTEM_VERSION
# so the app still runs on macOS 15 but gets the modern controls. Re-signed below.
echo "==> stamping linked SDK 26.0 for Liquid Glass controls (minos stays $MIN_SYSTEM_VERSION)"
vtool -set-build-version macos "$MIN_SYSTEM_VERSION" 26.0 -replace -output "$APP_BINARY.tmp" "$APP_BINARY"
mv "$APP_BINARY.tmp" "$APP_BINARY"
chmod +x "$APP_BINARY"
# Stage every SwiftPM resource bundle produced by the build (the app's own
# MeuUso_MeuUso.bundle, which carries the provider SVGs + model manifest)
# into Contents/Resources, the standard app layout. Bundle.meuUsoResources
# (see Support/ResourceBundle.swift) loads it from there.
shopt -s nullglob
for bundle in "$BUILD_DIR"/*.bundle; do
  cp -R "$bundle" "$APP_RESOURCES/$(basename "$bundle")"
done
shopt -u nullglob

# The pt-BR strings (assets/Localization): the app's only localization, so the UI — including AppKit's
# own menus and panels — is always Portuguese. See Support/L10n.swift.
ditto "$ROOT_DIR/assets/Localization/pt-BR.lproj" "$APP_RESOURCES/pt-BR.lproj"
# The terminal installer/updater: `meu-uso update` runs this bundled copy (see Sources/MeuUsoCLI).
cp "$ROOT_DIR/script/install.sh" "$APP_RESOURCES/install.sh"

# App icon. The classic AppIcon.icns (rendered by script/brand/mark.py --icns) always ships. When actool
# can compile the Icon Composer source (assets/AppIcon.icon), the Liquid Glass Assets.car is added and
# CFBundleIconName (which must match the .icon file stem, "AppIcon") is declared; otherwise macOS shows
# the .icns through CFBundleIconFile.
PREBUILT_ICON_DIR="$ROOT_DIR/assets/AppIcon.prebuilt"
cp "$PREBUILT_ICON_DIR/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
ICON_NAME_ENTRY=""
echo "==> compiling app icon (actool)"
if xcrun actool "$ROOT_DIR/assets/AppIcon.icon" --compile "$APP_RESOURCES" \
  --app-icon AppIcon \
  --enable-on-demand-resources NO \
  --development-region en \
  --target-device mac \
  --platform macosx \
  --minimum-deployment-target "$MIN_SYSTEM_VERSION" \
  --output-partial-info-plist /dev/null \
  --output-format human-readable-text --errors --warnings; then
  ICON_NAME_ENTRY="<key>CFBundleIconName</key><string>AppIcon</string>"
  # actool also writes an AppIcon.icns from the .icon; keep the rendered one for a consistent look.
  cp "$PREBUILT_ICON_DIR/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
elif [ -f "$PREBUILT_ICON_DIR/Assets.car" ]; then
  # actool is broken on some toolchains (it crashes on Icon Composer files on GitHub's runners); a
  # catalog committed by script/compile_icon.sh is the next best thing.
  echo "==> actool failed; using prebuilt Liquid Glass icon (assets/AppIcon.prebuilt)"
  cp "$PREBUILT_ICON_DIR/Assets.car" "$APP_RESOURCES/Assets.car"
  ICON_NAME_ENTRY="<key>CFBundleIconName</key><string>AppIcon</string>"
else
  echo "==> actool unavailable; shipping the classic AppIcon.icns only"
fi

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$TARGET_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY</string>
  <key>LSHasLocalizedDisplayName</key>
  <true/>
  <key>CFBundleDevelopmentRegion</key>
  <string>pt-BR</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>pt-BR</string>
  </array>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION$APP_VERSION_SUFFIX</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>MeuUsoDistribution</key>
  <string>$DISTRIBUTION</string>
  $ICON_NAME_ENTRY
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSUbiquitousContainers</key>
  <dict>
    <key>$ICLOUD_CONTAINER_ID</key>
    <dict>
      <key>NSUbiquitousContainerIsDocumentScopePublic</key>
      <false/>
      <key>NSUbiquitousContainerName</key>
      <string>Meu Uso</string>
      <key>NSUbiquitousContainerSupportedFolderLevels</key>
      <string>None</string>
    </dict>
  </dict>
</dict>
</plist>
PLIST

if [ -n "${ICLOUD_PROVISIONING_PROFILE:-}" ] && [ ! -f "$ICLOUD_PROVISIONING_PROFILE" ]; then
  echo "iCloud provisioning profile not found: $ICLOUD_PROVISIONING_PROFILE" >&2
  exit 1
fi

if [ -z "${ICLOUD_PROVISIONING_PROFILE:-}" ]; then
  ICLOUD_PROVISIONING_PROFILE=$("$ROOT_DIR/script/find_icloud_provisioning_profile.sh" \
    "$BUNDLE_ID" "$ICLOUD_CONTAINER_ID" || true)
fi

if [ -n "${ICLOUD_PROVISIONING_PROFILE:-}" ]; then
  echo "==> using iCloud provisioning profile: $ICLOUD_PROVISIONING_PROFILE"
  cp "$ICLOUD_PROVISIONING_PROFILE" "$APP_CONTENTS/embedded.provisionprofile"
  SIGN_ENTITLEMENTS="$DIST_DIR/MeuUso.dev.resolved.entitlements.plist"
  "$ROOT_DIR/script/render_icloud_entitlements.sh" \
    "$ENTITLEMENTS" "$ICLOUD_PROVISIONING_PROFILE" "$SIGN_ENTITLEMENTS" \
    "$ICLOUD_CONTAINER_ID"
else
  echo "WARNING: no matching installed iCloud provisioning profile was found; iCloud Sync will be unavailable in this build." >&2
fi

# Pick a stable Apple Development identity so ad-hoc cdhash churn doesn't re-trigger
# permission prompts on every rebuild. Fall back to ad-hoc only if none is found.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -z "$CODESIGN_IDENTITY" ]; then
  CODESIGN_IDENTITY=$(/usr/bin/security find-identity -p codesigning -v 2>/dev/null \
    | /usr/bin/awk -F\" '/Apple Development:/ { print $2; exit }')
fi

# Embed + sign Sparkle.framework before sealing the app. The executable links Sparkle, so without the
# embedded framework the build would fail to launch — even though the updater stays dormant here (no
# SUFeedURL in the Info.plist above; see UpdaterController).
"$ROOT_DIR/script/embed_sparkle.sh" "$APP_BUNDLE" "$APP_BINARY" "$CODESIGN_IDENTITY" "--options runtime"

if [ -n "$CODESIGN_IDENTITY" ]; then
  /usr/bin/codesign --force --options runtime --sign "$CODESIGN_IDENTITY" "$CLI_BINARY" >/dev/null
  # Not --deep: the Sparkle framework is already signed above and must keep that signature.
  /usr/bin/codesign --force --options runtime \
    --sign "$CODESIGN_IDENTITY" \
    --entitlements "$SIGN_ENTITLEMENTS" \
    "$APP_BUNDLE" >/dev/null
  echo "==> signed with: $CODESIGN_IDENTITY"
else
  /usr/bin/codesign --force --sign - "$CLI_BINARY" >/dev/null
  /usr/bin/codesign --force --sign - --entitlements "$SIGN_ENTITLEMENTS" "$APP_BUNDLE" >/dev/null
  echo "WARNING: no Apple Development identity found; ad-hoc signed." >&2
fi

launch_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    launch_app
    echo "==> launched $APP_DISPLAY (dist/$APP_DISPLAY.app)"
    ;;
  build)
    : # build + stage + sign only
    ;;
  logs)
    launch_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$TARGET_NAME\""
    ;;
  verify)
    launch_app
    sleep 1
    pgrep -f "$APP_BINARY" >/dev/null && echo "==> running"
    ;;
  *)
    echo "usage: $0 [run|build|logs|verify]" >&2
    exit 2
    ;;
esac
