#!/bin/bash
set -u

project_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$project_dir" || exit 1

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode is required. Open ClubConnect.xcodeproj on your Mac."
    exit 1
fi

build_directory="$(mktemp -d "${TMPDIR:-/tmp}/ClubConnect-build.XXXXXX")" || exit 1
log_file="$project_dir/Build-Report.txt"
echo "Building ClubConnect for the iOS Simulator. This may take a few minutes."
echo "Report: $log_file"

xcodebuild -project ClubConnect.xcodeproj -scheme ClubConnect \
    -configuration Debug -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$build_directory" CODE_SIGNING_ALLOWED=NO build \
    > "$log_file" 2>&1
build_status=$?

if [ "$build_status" -eq 0 ]; then
    echo "BUILD SUCCEEDED. Open the project and press Command-R to test the app."
else
    echo "Build did not succeed. See Build-Report.txt for the exact Xcode messages."
    tail -n 35 "$log_file"
fi
echo "Temporary build output: $build_directory"
echo "Press Return to close."
read -r unused_reply
exit "$build_status"
