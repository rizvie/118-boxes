#!/usr/bin/env bash
# Archive 118 Boxes and upload it to TestFlight with an App Store Connect API key.
# See scripts/TESTFLIGHT.md for the one-time setup.
set -euo pipefail

cd "$(dirname "$0")/.."
PROJECT="Boxes118.xcodeproj"
SCHEME="Boxes118"
BUILD_DIR="build"
ARCHIVE="$BUILD_DIR/Boxes118.xcarchive"

# One API key covers a whole team, so this reuses an existing key.
ENV_FILE="${BOXES118_ASC_ENV:-$HOME/.clipper-asc.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. It needs ASC_KEY_ID and ASC_ISSUER_ID." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"
: "${ASC_KEY_ID:?ASC_KEY_ID missing from $ENV_FILE}"
: "${ASC_ISSUER_ID:?ASC_ISSUER_ID missing from $ENV_FILE}"

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
[[ -f "$KEY_PATH" ]] || { echo "ERROR: API key not found at $KEY_PATH" >&2; exit 1; }

AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID"
      -authenticationKeyIssuerID "$ASC_ISSUER_ID")

echo "==> Regenerating project"
command -v xcodegen >/dev/null && xcodegen generate

echo "==> Archiving $SCHEME (Release)"
rm -rf "$ARCHIVE"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  "${AUTH[@]}" \
  clean archive

echo "==> Exporting + uploading to TestFlight"
if ! xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist ExportOptions.plist \
  "${AUTH[@]}"; then
  echo "Export failed. If it complained about 'method', this Xcode may want" >&2
  echo "method=app-store instead of app-store-connect in ExportOptions.plist." >&2
  exit 1
fi

echo "==> Done. The build processes in App Store Connect -> TestFlight in a few minutes."
