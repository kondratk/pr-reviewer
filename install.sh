#!/bin/bash
set -e

APP_NAME="pr_reviews"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

if pgrep -x "$APP_NAME" > /dev/null; then
    echo "Closing running $APP_NAME..."
    pkill -x "$APP_NAME"
    sleep 1
fi

echo "Building $APP_NAME..."
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$PROJECT_DIR/.build" \
    -quiet

APP_PATH="$PROJECT_DIR/.build/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Build failed: $APP_PATH not found"
    exit 1
fi

echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_PATH" "/Applications/$APP_NAME.app"

echo "Done. Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"
