#!/usr/bin/env bash
# Install the App Store profiles fetched into $1 and write ExportOptions for manual signing to $2.
# Exports VOE_APP_PROFILE and VOE_WIDGET_PROFILE (profile names) to $GITHUB_ENV for the archive step.
set -euo pipefail
dir="$1"
export_options="$2"
team="SUM249566D"
app_bundle="com.github.yefimtsev.VOEMonitor.iOS"
widget_bundle="$app_bundle.Widget"

/usr/libexec/PlistBuddy -c "Add :method string app-store-connect" \
  -c "Add :destination string export" \
  -c "Add :signingStyle string manual" \
  -c "Add :signingCertificate string Apple Distribution" \
  -c "Add :teamID string $team" \
  -c "Add :manageAppVersionAndBuildNumber bool false" \
  -c "Add :uploadSymbols bool true" \
  -c "Add :provisioningProfiles dict" "$export_options" > /dev/null

found=0
for profile in "$dir"/*.mobileprovision; do
  [ -f "$profile" ] || continue
  decoded=$(mktemp)
  security cms -D -i "$profile" > "$decoded"
  name=$(/usr/libexec/PlistBuddy -c 'Print :Name' "$decoded")
  bundle=$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$decoded")
  bundle="${bundle#"$team".}"
  rm -f "$decoded"

  case "$bundle" in
    "$app_bundle") echo "VOE_APP_PROFILE=$name" >> "$GITHUB_ENV" ;;
    "$widget_bundle") echo "VOE_WIDGET_PROFILE=$name" >> "$GITHUB_ENV" ;;
    *) echo "::warning::Skipping profile '$name' for unexpected bundle $bundle"; continue ;;
  esac
  asc profiles local install --path "$profile" --force --output json > /dev/null
  /usr/libexec/PlistBuddy -c "Add :provisioningProfiles:$bundle string $name" "$export_options" > /dev/null
  echo "Installed '$name' for $bundle"
  found=$((found + 1))
done

if [ "$found" -ne 2 ]; then
  echo "::error::Expected App Store profiles for $app_bundle and $widget_bundle, installed $found"
  exit 1
fi
