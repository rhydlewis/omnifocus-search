#!/bin/bash

# Test Runner Script for OmniFocus Search AppleScript files
# This script will test each AppleScript file with a simple query and report the results

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print headers
print_header() {
  echo
  echo -e "${BLUE}===========================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}===========================================================${NC}"
  echo
}

# Function to run a test and print the result
run_test() {
  local script_name="$1"
  local script_path="${WORKFLOW_DIR}/applescript/${script_name}.applescript"
  local test_query="$2"
  shift 2
  local extra_args=("$@")

  echo -e "${YELLOW}Testing ${script_name}${NC} with query: '${test_query}'"

  # Run the script with the test query and any extra arguments
  local result
  if [ ${#extra_args[@]} -eq 0 ]; then
    result=$(/usr/bin/osascript "${script_path}" "${test_query}" 2>&1)
  else
    result=$(/usr/bin/osascript "${script_path}" "${test_query}" "${extra_args[@]}" 2>&1)
  fi

  # Check if the result contains ERROR
  if [[ "$result" == ERROR* ]]; then
    echo -e "${RED}FAILED:${NC} $result"
    return 1
  elif [[ -z "$result" ]]; then
    echo -e "${YELLOW}WARNING:${NC} No results returned. This might be normal if no matches found."
    return 0
  else
    # Show a preview of the result (first 150 characters)
    local preview="${result:0:150}"
    if [[ ${#result} -gt 150 ]]; then
      preview+="..."
    fi
    echo -e "${GREEN}SUCCESS:${NC} Received data (preview): $preview"

    # Count the number of items returned (based on ### delimiter)
    local count=1
    if [[ "$result" == *"###"* ]]; then
      count=$(echo "$result" | awk -F'###' '{print NF}')
    fi
    echo -e "${GREEN}Items found:${NC} $count"
    return 0
  fi
}

# Function to check if OmniFocus is running
check_omnifocus() {
  if ! pgrep -q OmniFocus; then
    echo -e "${RED}ERROR: OmniFocus is not running. Please launch OmniFocus and try again.${NC}"
    exit 1
  else
    echo -e "${GREEN}OmniFocus is running.${NC}"
  fi
}

# Main test sequence
main() {
  print_header "OmniFocus Search Test Runner"

  echo "This script will test each AppleScript file with sample queries."
  echo "Make sure OmniFocus is running before proceeding."
  echo
  echo "Workflow directory: ${WORKFLOW_DIR}"
  echo

  # Check if OmniFocus is running
  check_omnifocus

  # Test task searching
  print_header "Testing Task Search Scripts"
  run_test "search_tasks" "add" "false" "false" "true"
  run_test "search_tasks" "schedule" "false" "true" "true"
  run_test "search_tasks" "call" "true" "false" "false"

  # Test project searching
  print_header "Testing Project Search Scripts"
  run_test "search_projects" "quick" "true"

  # Test tag searching
  print_header "Testing Tag Search Scripts"
  run_test "search_tags" "code"

  # Test folder searching
  print_header "Testing Folder Search Scripts"
  run_test "search_folders" "axa"

  # Test inbox searching
  print_header "Testing Inbox Search Scripts"
  run_test "search_inbox" "fast"

  # Test perspectives listing
  print_header "Testing Perspectives Scripts"
  run_test "get_perspectives" "waiting"

  # Test notes searching
  print_header "Testing Notes Search Scripts"
  run_test "search_notes" "come"

  print_header "Test Summary"
  echo "All tests executed. Check the results above for any errors."
  echo "Note: Some tests may show 'No results returned' if no matching items were found."
  echo "This is normal and not necessarily an error."
}

# Run the main function
main