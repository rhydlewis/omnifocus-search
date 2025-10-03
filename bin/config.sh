#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the format_xml script for showing messages
source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Workflow bundle ID - will be used to store/retrieve Alfred variables
WORKFLOW_BUNDLE_ID="com.search.omnifocus"

# Simple file-based storage for settings
SETTINGS_DIR="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings"

# Create settings directory if it doesn't exist
mkdir -p "$SETTINGS_DIR" 2>/dev/null

# Get workflow variable (uses simple file-based storage)
get_workflow_var() {
  local var_name="$1"
  local default_value="$2"
  local settings_file="${SETTINGS_DIR}/${var_name}"

  # Check if settings file exists
  if [ -f "$settings_file" ]; then
    cat "$settings_file"
  else
    # Return default if file doesn't exist
    echo "$default_value"
  fi
}

# Set workflow variable (uses simple file-based storage)
set_workflow_var() {
  local var_name="$1"
  local value="$2"
  local settings_file="${SETTINGS_DIR}/${var_name}"

  # Create settings directory if it doesn't exist
  mkdir -p "$SETTINGS_DIR" 2>/dev/null

  # Write value to file
  echo "$value" > "$settings_file"

  # Check if operation was successful
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Check if caching is enabled (default: false)
is_caching_enabled() {
  # Read from Alfred environment variable (set via workflow configuration UI)
  # Alfred checkboxes return "1" for checked, "0" for unchecked
  local caching_value="${caching_enabled:-0}"

  # Convert to true/false for consistency with existing code
  if [[ "$caching_value" == "1" ]]; then
    echo "true"
  else
    echo "false"
  fi
}