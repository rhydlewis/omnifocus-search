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

# Auto-detect OmniFocus database path
find_omnifocus_database() {
  # Try to find the OmniFocus database in the default location
  local db_path=""

  # Check OmniFocus 4 database location first
  local of4_path="$HOME/Library/Containers/com.omnigroup.OmniFocus4/Data/Library/Application Support/OmniFocus/OmniFocus.sqlite"
  if [[ -f "$of4_path" ]]; then
    db_path="$of4_path"
  else
    # Check OmniFocus 3 database location
    local of3_path="$HOME/Library/Containers/com.omnigroup.OmniFocus3/Data/Library/Caches/com.omnigroup.OmniFocus3/OmniFocusDatabase2"
    if [[ -d "$of3_path" ]]; then
      db_path="$of3_path"
    fi
  fi

  # Set the database path in Alfred workflow variables if found
  if [[ -n "$db_path" ]]; then
    if set_workflow_var "OF_DATABASE_PATH" "$db_path"; then
      show_message "OmniFocus Database Found" "Path: $db_path" "${WORKFLOW_DIR}/icons/success.png"
    else
      show_message "Error Setting Database Path" "Could not save the path to Alfred workflow variables" "${WORKFLOW_DIR}/icons/error.png"
    fi
  else
    show_message "OmniFocus Database Not Found" "Please set the database path manually with 'of set-db-path [path]'" "${WORKFLOW_DIR}/icons/error.png"
  fi
}

# Set OmniFocus database path manually
set_omnifocus_database_path() {
  local path="$1"

  # Validate the path exists
  if [[ ! -e "$path" ]]; then
    show_message "Invalid Path" "The specified path does not exist: $path" "${WORKFLOW_DIR}/icons/error.png"
    return 1
  fi

  # Set the path in Alfred workflow variables
  if set_workflow_var "OF_DATABASE_PATH" "$path"; then
    show_message "Database Path Set" "Path: $path" "${WORKFLOW_DIR}/icons/success.png"
    return 0
  else
    show_message "Error Setting Database Path" "Could not save the path to Alfred workflow variables" "${WORKFLOW_DIR}/icons/error.png"
    return 1
  fi
}

# Get the OmniFocus database path
get_omnifocus_database_path() {
  local default_path="$HOME/Library/Containers/com.omnigroup.OmniFocus4/Data/Library/Application Support/OmniFocus/OmniFocus.sqlite"
  get_workflow_var "OF_DATABASE_PATH" "$default_path"
}

# Check if caching is enabled (default: true)
is_caching_enabled() {
  # Create settings directory if it doesn't exist
  local settings_dir="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings"
  mkdir -p "$settings_dir" 2>/dev/null

  local default_value="true"
  local value="$default_value"

  # Try to read directly from the settings file
  if [ -f "${settings_dir}/OF_CACHING_ENABLED" ]; then
    value=$(cat "${settings_dir}/OF_CACHING_ENABLED")
  else
    # If the file doesn't exist, create it with default value
    echo "$default_value" > "${settings_dir}/OF_CACHING_ENABLED"
  fi

  # Log the caching status for debugging
  echo "Checking caching status: $value" > "${settings_dir}/cache_status.log"
  echo "Timestamp: $(date)" >> "${settings_dir}/cache_status.log"

  echo "$value"
}

# Enable caching
enable_caching() {
  # Create settings directory if it doesn't exist
  local settings_dir="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings"
  mkdir -p "$settings_dir" 2>/dev/null

  # Write directly to the settings file for maximum reliability
  echo "true" > "${settings_dir}/OF_CACHING_ENABLED"

  # Also try to set the workflow variable as a backup
  set_workflow_var "OF_CACHING_ENABLED" "true"

  # Clear any old debug logs
  rm -f "${settings_dir}/*debug*.log" 2>/dev/null

  # Log the action
  echo "Enabled caching at $(date)" > "${settings_dir}/cache_enable.log"

  show_message "Caching Enabled" "OmniFocus search results will be cached for better performance." "${WORKFLOW_DIR}/icons/success.png"
  return 0
}

# Disable caching
disable_caching() {
  # Make sure we have CACHE_DIR defined
  if [ -z "$CACHE_DIR" ]; then
    CACHE_DIR="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch"
  fi

  # Create settings directory if it doesn't exist
  local settings_dir="${CACHE_DIR}/settings"
  mkdir -p "$settings_dir" 2>/dev/null

  # Write directly to the settings file for maximum reliability
  echo "false" > "${settings_dir}/OF_CACHING_ENABLED"

  # Also try to set the workflow variable as a backup
  set_workflow_var "OF_CACHING_ENABLED" "false"

  # Log the action
  echo "Disabled caching at $(date)" > "${settings_dir}/cache_disable.log"

  # Clear the cache by removing all files (more reliable than importing cache_manager.sh)
  echo "Removing all cache files..." > "${CACHE_DIR}/cache_clear.log"

  # Create these directories if they don't exist (to avoid errors when removing contents)
  mkdir -p "${CACHE_DIR}/projects" 2>/dev/null
  mkdir -p "${CACHE_DIR}/folders" 2>/dev/null
  mkdir -p "${CACHE_DIR}/tags" 2>/dev/null
  mkdir -p "${CACHE_DIR}/perspectives" 2>/dev/null
  mkdir -p "${CACHE_DIR}/tasks" 2>/dev/null
  mkdir -p "${CACHE_DIR}/completed_tasks" 2>/dev/null
  mkdir -p "${CACHE_DIR}/inbox" 2>/dev/null
  mkdir -p "${CACHE_DIR}/notes" 2>/dev/null

  # Remove all cache files
  rm -f "${CACHE_DIR}/projects/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/folders/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/tags/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/perspectives/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/tasks/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/completed_tasks/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/inbox/"*.cache 2>/dev/null
  rm -f "${CACHE_DIR}/notes/"*.cache 2>/dev/null

  echo "Cache cleared at $(date)" >> "${CACHE_DIR}/cache_clear.log"

  show_message "Caching Disabled" "Cache cleared. OmniFocus will always return fresh results (may be slower)." "${WORKFLOW_DIR}/icons/success.png"
  return 0
}