#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the format_xml script for showing messages
source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Error codes for standardized error handling
readonly ERR_OMNIFOCUS_NOT_RUNNING=1
readonly ERR_OMNIFOCUS_DOCUMENT_ERROR=2
readonly ERR_PERMISSION_DENIED=3
readonly ERR_TIMEOUT=4
readonly ERR_SCRIPT_EXECUTION=5
readonly ERR_UNKNOWN=99

# Log an error to the log file with detailed information
log_error() {
  local error_message="$1"
  local error_code="${2:-$ERR_UNKNOWN}"
  local script_type="${3:-unknown}"
  local log_file="${WORKFLOW_DIR}/error.log"

  # Create a timestamped error message with context
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] ERROR_CODE: $error_code | TYPE: $script_type | MESSAGE: $error_message" >> "$log_file"

  # Also log to detailed error log for debugging
  local detailed_log="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings/error_details.log"
  echo "=== Error Report ===" >> "$detailed_log"
  echo "Timestamp: $timestamp" >> "$detailed_log"
  echo "Error Code: $error_code" >> "$detailed_log"
  echo "Script Type: $script_type" >> "$detailed_log"
  echo "Message: $error_message" >> "$detailed_log"
  echo "System: $(uname -a)" >> "$detailed_log"
  echo "===================" >> "$detailed_log"
  echo "" >> "$detailed_log"
}

# Show an error message to the user in Alfred XML format with recovery suggestions
show_error() {
  local title="$1"
  local subtitle="$2"
  local recovery_suggestion="${3:-}"

  # Log the error
  log_error "$title: $subtitle"

  # Build subtitle with recovery suggestion
  local full_subtitle="$subtitle"
  if [[ -n "$recovery_suggestion" ]]; then
    full_subtitle="$subtitle → $recovery_suggestion"
  fi

  # Show the error in Alfred
  show_message "$title" "$full_subtitle" "${WORKFLOW_DIR}/icons/error.png"
}

# Handle AppleScript errors
handle_applescript_error() {
  local error_message="$1"

  # Check if it's a specific error type we can provide better messaging for
  if [[ "$error_message" == *"Application isn't running"* ]]; then
    log_error "OmniFocus not running" "$ERR_OMNIFOCUS_NOT_RUNNING" "applescript"
    show_error "OmniFocus Not Running" "Please launch OmniFocus and try again" "Open OmniFocus"
  elif [[ "$error_message" == *"Can't get default document"* ]]; then
    log_error "Cannot access OmniFocus document" "$ERR_OMNIFOCUS_DOCUMENT_ERROR" "applescript"
    show_error "OmniFocus Document Error" "Unable to access OmniFocus document" "Ensure OmniFocus database is accessible"
  elif [[ "$error_message" == *"Access not allowed"* ]]; then
    log_error "Permission denied" "$ERR_PERMISSION_DENIED" "applescript"
    show_error "Accessibility Permission Required" "Alfred needs permission to control OmniFocus" "Go to System Preferences > Security & Privacy > Privacy > Accessibility"
  else
    log_error "AppleScript error: $error_message" "$ERR_SCRIPT_EXECUTION" "applescript"
    show_error "AppleScript Error" "$error_message" "Check error.log for details"
  fi
}

# Handle JXA errors
handle_jxa_error() {
  local error_message="$1"

  # Check for common JXA error patterns
  if [[ "$error_message" == *"Application isn't running"* ]] || [[ "$error_message" == *"not running"* ]]; then
    log_error "OmniFocus not running" "$ERR_OMNIFOCUS_NOT_RUNNING" "jxa"
    show_error "OmniFocus Not Running" "Please launch OmniFocus and try again" "Open OmniFocus"
  elif [[ "$error_message" == *"Can't get"* ]] || [[ "$error_message" == *"undefined"* ]]; then
    log_error "Cannot access OmniFocus document" "$ERR_OMNIFOCUS_DOCUMENT_ERROR" "jxa"
    show_error "OmniFocus Document Error" "Unable to access OmniFocus document" "Ensure OmniFocus database is accessible"
  elif [[ "$error_message" == *"not allowed"* ]] || [[ "$error_message" == *"permission"* ]]; then
    log_error "Permission denied" "$ERR_PERMISSION_DENIED" "jxa"
    show_error "Accessibility Permission Required" "Alfred needs permission to control OmniFocus" "Go to System Preferences > Security & Privacy > Privacy > Accessibility"
  elif [[ "$error_message" == *"timeout"* ]] || [[ "$error_message" == *"timed out"* ]]; then
    log_error "Script execution timeout" "$ERR_TIMEOUT" "jxa"
    show_error "Search Timeout" "Search took too long to complete" "Try a more specific search query"
  elif [[ "$error_message" == *"Error:"* ]]; then
    # Extract the error message after "Error:"
    local clean_message=$(echo "$error_message" | sed 's/.*Error: //')
    log_error "JXA error: $clean_message" "$ERR_SCRIPT_EXECUTION" "jxa"
    show_error "Search Error" "$clean_message" "Check error.log for details"
  else
    log_error "JXA error: $error_message" "$ERR_SCRIPT_EXECUTION" "jxa"
    show_error "JXA Error" "$error_message" "Check error.log for details"
  fi
}

# Handle script errors with automatic detection of script type
handle_script_error() {
  local error_message="$1"
  local script_path="${2:-}"

  # Detect script type from path
  if [[ "$script_path" == *.js ]]; then
    handle_jxa_error "$error_message"
  else
    handle_applescript_error "$error_message"
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