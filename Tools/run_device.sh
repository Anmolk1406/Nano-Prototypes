#!/bin/bash
#
# Build, install and launch on the connected iPhone — without touching Xcode's
# run-destination dropdown.
#
# That dropdown is the source of "A build only device cannot be used to run this
# target": Xcode persists the selected destination in
#   GyroQR.xcodeproj/project.xcworkspace/xcuserdata/*/UserInterfaceState.xcuserstate
# and once "Any iOS Device" (a build-only placeholder meant for archiving) is
# saved there, every reopen restores it. This script resolves the concrete
# device itself, so there is nothing to mis-select.
#
# Usage:
#   Tools/run_device.sh                     # build, install, launch
#   Tools/run_device.sh -onbStep Avatar     # extra args are passed to the app
#   Tools/run_device.sh --build-only
#
set -euo pipefail

cd "$(dirname "$0")/.."
PROJ="GyroQR.xcodeproj"
SCHEME="GyroQR"
BUNDLE="com.noon.gyroqr"
DD="build/device"
SPM="build/spm"

BUILD_ONLY=0
if [ "${1:-}" = "--build-only" ]; then BUILD_ONLY=1; shift; fi

# Two different identifiers for the same phone, and they are not interchangeable:
# xcodebuild wants the hardware UDID, devicectl wants the CoreDevice UUID.
HW_UDID=$(xcodebuild -project "$PROJ" -scheme "$SCHEME" -showdestinations 2>/dev/null \
  | grep 'platform:iOS,' | grep -v 'placeholder' | grep -o 'id:[0-9A-Fa-f-]*' \
  | head -1 | cut -d: -f2)

if [ -z "$HW_UDID" ]; then
  echo "No iPhone found as a run destination." >&2
  echo "Check: cable connected, phone unlocked, trusted, Developer Mode on." >&2
  echo "Then:  xcrun devicectl list devices" >&2
  exit 1
fi

CD_UUID=$(xcrun devicectl list devices 2>/dev/null \
  | awk '/connected/ {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{4}-/) {print $i; exit}}')

echo "▸ device  $HW_UDID"
xcodebuild -project "$PROJ" -scheme "$SCHEME" \
  -destination "platform=iOS,id=$HW_UDID" \
  -derivedDataPath "$DD" -clonedSourcePackagesDirPath "$SPM" \
  -allowProvisioningUpdates build \
  | grep -E "error:|warning: (Sendable|unused)|BUILD (SUCCEEDED|FAILED)" || true

APP="$DD/Build/Products/Debug-iphoneos/GyroQR.app"
[ -d "$APP" ] || { echo "Build produced no .app at $APP" >&2; exit 1; }
[ "$BUILD_ONLY" = "1" ] && { echo "▸ built $APP"; exit 0; }

if [ -z "$CD_UUID" ]; then
  echo "Built, but devicectl sees no connected device to install onto." >&2
  exit 1
fi

echo "▸ install"
xcrun devicectl device install app --device "$CD_UUID" "$APP" >/dev/null

echo "▸ launch"
if [ "$#" -gt 0 ]; then
  xcrun devicectl device process launch --device "$CD_UUID" "$BUNDLE" "$@" >/dev/null
else
  xcrun devicectl device process launch --device "$CD_UUID" "$BUNDLE" >/dev/null
fi
echo "▸ running on device"
