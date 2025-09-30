#!/bin/bash

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the utility scripts
[ -f "${WORKFLOW_DIR}/bin/format_xml.sh" ] && source "${WORKFLOW_DIR}/bin/format_xml.sh"
[ -f "${WORKFLOW_DIR}/bin/config.sh" ] && source "${WORKFLOW_DIR}/bin/config.sh"
[ -f "${WORKFLOW_DIR}/bin/error_handler.sh" ] && source "${WORKFLOW_DIR}/bin/error_handler.sh"
[ -f "${WORKFLOW_DIR}/lib/constants.sh" ] && source "${WORKFLOW_DIR}/lib/constants.sh"

# Parse the input arguments
query="$1"
command_type="$2"

# Process commands
case "$command_type" in
  "s") # Search tasks
    completed="false"
    flagged="false"
    active_only="true"

    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "$query" "$completed" "$flagged" "$active_only")
    generate_xml_output "task" "$results"

    ;;

  "sc") # Search completed tasks
    completed="true"
    flagged="false"
    active_only="false"

    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "$query" "$completed" "$flagged" "$active_only")
    generate_xml_output "task" "$results"
    ;;

  "p") # Search projects
    active_only="true"

    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_projects.applescript" "$query" "$active_only")
    generate_xml_output "project" "$results"
    ;;

  "i") # Search inbox
    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_inbox.applescript" "$query")
    generate_xml_output "task" "$results"
    ;;

  "t") # Search tags
    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tags.applescript" "$query")
    generate_xml_output "tag" "$results"
    ;;

  "f") # Search folders
    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_folders.applescript" "$query")
    generate_xml_output "folder" "$results"
    ;;

  "v") # List perspectives
    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/get_perspectives.applescript" "$query")
    generate_xml_output "perspective" "$results"
    ;;

  "n") # Search notes
    # Call the AppleScript and process results
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_notes.applescript" "$query")
    generate_xml_output "task" "$results"
    ;;

  "find-of-db") # Find OmniFocus database
    find_omnifocus_database
    ;;

  "set-of-db") # Set OmniFocus database path
    set_omnifocus_database_path "$query"
    ;;

  *) # Unknown command
    show_error "Unknown command" "Command type '$command_type' is not recognized"
    ;;
esac