#!/bin/bash
set -euo pipefail

rm -rf build/
mkdir -p build

echo "Build Started!"
echo

set +e
xcodebuild \
  -project relazin.xcodeproj \
  -scheme relazin \
  -configuration Debug \
  -sdk iphoneos \
  -arch arm64e \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="Config/relazin.entitlements" \
  archive \
  -archivePath "$PWD/build/relazin.xcarchive" 2>&1 | tee "$PWD/build/xcodebuild.log" | xcpretty
build_status=${PIPESTATUS[0]}
set -e

if [ "$build_status" -ne 0 ]; then
  echo
  echo "xcodebuild failed with status $build_status. Last 150 raw log lines:"
  tail -n 150 "$PWD/build/xcodebuild.log"
  exit "$build_status"
fi

APP_PATH="$PWD/build/relazin.xcarchive/Products/Applications/relazin.app"
if [ ! -d "$APP_PATH" ]; then
  echo "Missing app at $APP_PATH"
  exit 1
fi
rm -rf "$PWD/build/Payload"
mkdir -p "$PWD/build/Payload"
cp -R "$APP_PATH" "$PWD/build/Payload/"

plutil -replace UIFileSharingEnabled -bool YES "$PWD/build/Payload/relazin.app/Info.plist"

if ! command -v ldid >/dev/null 2>&1; then
  echo "ERROR: ldid not installed. Install with: brew install ldid" >&2
  exit 1
fi
ldid -SConfig/relazin.entitlements "$PWD/build/Payload/relazin.app/relazin"
(cd "$PWD/build" && /usr/bin/zip -qry RSwordSvin.ipa Payload)

echo
echo "build successful!"
echo "ipa at: build/RSwordSvin.ipa"
exit 0
