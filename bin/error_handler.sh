#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the format_xml script for showing messages
source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Log an error to the log file
log_error() {
  local error_message="$1"
  local log_file="${WORKFLOW_DIR}/error.log"

  # Create a timestamped error message
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] ERROR: $error_message" >> "$log_file"
}

# Show an error message to the user in Alfred XML format
show_error() {
  local title="$1"
  local subtitle="$2"

  # Log the error
  log_error "$title: $subtitle"

  # Show the error in Alfred
  show_message "$title" "$subtitle" "${WORKFLOW_DIR}/icons/error.png"
}

# Handle AppleScript errors
handle_applescript_error() {
  local error_message="$1"

  # Check if it's a specific error type we can provide better messaging for
  if [[ "$error_message" == *"Application isn't running"* ]]; then
    show_error "OmniFocus Not Running" "Please launch OmniFocus and try again"
  elif [[ "$error_message" == *"Can't get default document"* ]]; then
    show_error "OmniFocus Document Error" "Unable to access OmniFocus document"
  elif [[ "$error_message" == *"Access not allowed"* ]]; then
    show_error "Accessibility Permission Required" "Please allow Alfred to control OmniFocus in System Preferences > Security & Privacy > Privacy > Accessibility"
  else
    show_error "AppleScript Error" "$error_message"
  fi
}

# Check if OmniFocus is running, show error if not
check_omnifocus_running() {
  # Use AppleScript to check if OmniFocus is running
  local is_running=$(/usr/bin/osascript -e 'tell application "System Events" to (name of processes) contains "OmniFocus"')

  if [[ "$is_running" != "true" ]]; then
    show_error "OmniFocus Not Running" "Please launch OmniFocus and try again"
    return 1
  fi

  return 0
}