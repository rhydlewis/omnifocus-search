#!/bin/bash

# update_installer.sh - Install updates to the OmniFocus Search Workflow
#
# This script downloads and installs the latest version of the workflow.
# It's triggered when a user clicks on the "Update Available" item
# presented by update_checker.sh.

# Get the download URL from the argument
DOWNLOAD_URL="$1"

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: No download URL provided" >&2
  exit 1
fi

# Path to the workflow directory for logging
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
LOG_FILE="${WORKFLOW_DIR}/update_install.log"

# Log the update attempt
echo "Update installation started at $(date)" > "$LOG_FILE"
echo "Download URL: $DOWNLOAD_URL" >> "$LOG_FILE"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
WORKFLOW_FILE="$TEMP_DIR/omnifocus-search.alfredworkflow"

echo "Downloading update to: $WORKFLOW_FILE" >> "$LOG_FILE"

# Download the workflow
if ! curl -L -s "$DOWNLOAD_URL" -o "$WORKFLOW_FILE"; then
  echo "Error: Failed to download workflow from $DOWNLOAD_URL" >> "$LOG_FILE"
  echo "Error: Failed to download the update." >&2
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "Download completed successfully" >> "$LOG_FILE"

# Check if file exists and has size greater than zero
if [ ! -s "$WORKFLOW_FILE" ]; then
  echo "Error: Downloaded file is empty or does not exist" >> "$LOG_FILE"
  echo "Error: The downloaded update file is invalid." >&2
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Open the workflow file with Alfred to install it
echo "Opening workflow file for installation" >> "$LOG_FILE"
open "$WORKFLOW_FILE"

# Wait a moment for Alfred to start processing the file
sleep 1

# Clean up the temporary directory
echo "Cleaning up temporary files" >> "$LOG_FILE"
rm -rf "$TEMP_DIR"

echo "Update installation process completed at $(date)" >> "$LOG_FILE"
echo "The update has been downloaded and installation started."