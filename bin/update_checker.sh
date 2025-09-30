#!/bin/bash

# update_checker.sh - Check for updates to the OmniFocus Search Workflow
#
# This script checks GitHub for the latest release and compares it to the
# current version. If a newer version is available, it provides the user
# with an option to update.

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the utility scripts if needed
[ -f "${WORKFLOW_DIR}/bin/format_xml.sh" ] && source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Read current version from info.plist
# First check if plutil is available (macOS tool for plist manipulation)
if command -v plutil &> /dev/null; then
  CURRENT_VERSION=$(plutil -extract version xml1 -o - "${WORKFLOW_DIR}/info.plist" 2>/dev/null | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p')
else
  # Fallback using grep and sed if plutil isn't available
  CURRENT_VERSION=$(grep -A1 "<key>version</key>" "${WORKFLOW_DIR}/info.plist" | tail -n1 | sed -E 's/.*<string>(.*)<\/string>.*/\1/')
fi

# If version isn't found or is empty, set a default
if [[ -z "$CURRENT_VERSION" ]]; then
  CURRENT_VERSION="0.0.0"
fi

# GitHub repository info
REPO="rhydlewis/omnifocus-search"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

# Fetch latest release info
LATEST_RELEASE=$(curl -s "$API_URL")
LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | grep '"browser_download_url":' | grep '.alfredworkflow' | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')

# Remove 'v' prefix from versions if present
CURRENT_VERSION=${CURRENT_VERSION#v}
LATEST_VERSION=${LATEST_VERSION#v}

# Log the version check
echo "Current version: $CURRENT_VERSION" > "${WORKFLOW_DIR}/update_check.log"
echo "Latest version: $LATEST_VERSION" >> "${WORKFLOW_DIR}/update_check.log"
echo "Check time: $(date)" >> "${WORKFLOW_DIR}/update_check.log"

# Function to compare versions
version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# Generate XML output for Alfred
generate_update_xml() {
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<items>'

  if [[ -z "$LATEST_VERSION" ]]; then
    # Failed to get latest version
    echo '  <item uid="update_error" valid="no">'
    echo '    <title>Error Checking for Updates</title>'
    echo '    <subtitle>Couldn'"'"'t fetch the latest version information</subtitle>'
    echo '    <icon>icons/info.png</icon>'
    echo '  </item>'
  elif version_gt "$LATEST_VERSION" "$CURRENT_VERSION"; then
    # Update available
    echo '  <item uid="update_available" arg="'"$DOWNLOAD_URL"'" valid="yes">'
    echo '    <title>Update Available: v'"$LATEST_VERSION"'</title>'
    echo '    <subtitle>You have v'"$CURRENT_VERSION"'. Click to update.</subtitle>'
    echo '    <icon>icons/refresh.png</icon>'
    echo '  </item>'
  else
    # No update available
    echo '  <item uid="up_to_date" valid="no">'
    echo '    <title>Up to Date: v'"$CURRENT_VERSION"'</title>'
    echo '    <subtitle>You have the latest version of OmniFocus Search.</subtitle>'
    echo '    <icon>icons/success.png</icon>'
    echo '  </item>'
  fi

  echo '</items>'
}

# Output the results to Alfred
generate_update_xml