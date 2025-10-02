#!/bin/bash

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the utility scripts
[ -f "${WORKFLOW_DIR}/bin/format_xml.sh" ] && source "${WORKFLOW_DIR}/bin/format_xml.sh"
[ -f "${WORKFLOW_DIR}/bin/config.sh" ] && source "${WORKFLOW_DIR}/bin/config.sh"
[ -f "${WORKFLOW_DIR}/bin/error_handler.sh" ] && source "${WORKFLOW_DIR}/bin/error_handler.sh"
[ -f "${WORKFLOW_DIR}/lib/constants.sh" ] && source "${WORKFLOW_DIR}/lib/constants.sh"
[ -f "${WORKFLOW_DIR}/bin/cache_manager.sh" ] && source "${WORKFLOW_DIR}/bin/cache_manager.sh"

# Parse the input arguments
query="$1"
# Handle case where Alfred passes "(null)" as a literal string
if [[ "$query" == "(null)" ]]; then
  query=""
fi
command_type="$2"

# Define the function to execute scripts (AppleScript or JXA) and format output
execute_and_cache() {
  local entity_type="$1"
  local script_path="$2"
  local query="$3"
  local additional_params="$4"

  # Create settings directory if it doesn't exist
  local settings_dir="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings"
  mkdir -p "$settings_dir" 2>/dev/null

  # Debug log
  echo "[$entity_type] execute_and_cache called at $(date)" > "${settings_dir}/execute_debug.log"
  echo "Script: $script_path" >> "${settings_dir}/execute_debug.log"
  echo "Query: $query" >> "${settings_dir}/execute_debug.log"
  echo "Params: $additional_params" >> "${settings_dir}/execute_debug.log"

  # Check if caching is enabled by reading the file directly
  local caching_enabled="true"
  if [ -f "${settings_dir}/OF_CACHING_ENABLED" ]; then
    caching_enabled=$(cat "${settings_dir}/OF_CACHING_ENABLED")
  fi
  echo "Caching status: $caching_enabled" >> "${settings_dir}/execute_debug.log"

  # Check cache first if caching is enabled
  if [[ "$caching_enabled" == "true" ]]; then
    cached_results=$(get_cache "$entity_type" "$query" "$additional_params")
    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "Cache hit - returning cached results" >> "${settings_dir}/execute_debug.log"
      echo "$cached_results"
      return
    fi
    echo "Cache miss - executing script" >> "${settings_dir}/execute_debug.log"
  else
    echo "Caching disabled - executing script directly" >> "${settings_dir}/execute_debug.log"
  fi

  # Detect script type and execute accordingly
  local script_type="applescript"
  if [[ "$script_path" == *.js ]]; then
    script_type="jxa"
    echo "Detected JXA script" >> "${settings_dir}/execute_debug.log"
  fi

  # Execute the script with timeout
  local timeout_duration=30
  if [[ "$script_type" == "jxa" ]]; then
    # Execute JXA script with timeout
    results=$(timeout "$timeout_duration" /usr/bin/osascript -l JavaScript "$script_path" "$query" "${@:5}" 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      echo "Script execution timed out after ${timeout_duration}s" >> "${settings_dir}/execute_debug.log"
      results="ERROR: Script execution timed out"
    elif [[ $exit_code -ne 0 ]]; then
      echo "Script execution failed with exit code $exit_code" >> "${settings_dir}/execute_debug.log"
      echo "Error output: $results" >> "${settings_dir}/execute_debug.log"
    fi
  else
    # Execute AppleScript with timeout
    results=$(timeout "$timeout_duration" /usr/bin/osascript "$script_path" "$query" "${@:5}" 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      echo "Script execution timed out after ${timeout_duration}s" >> "${settings_dir}/execute_debug.log"
      results="ERROR: Script execution timed out"
    elif [[ $exit_code -ne 0 ]]; then
      echo "Script execution failed with exit code $exit_code" >> "${settings_dir}/execute_debug.log"
      echo "Error output: $results" >> "${settings_dir}/execute_debug.log"
    fi
  fi

  xml_output=$(generate_xml_output "$entity_type" "$results")

  # Save to cache if enabled
  if [[ "$caching_enabled" == "true" ]]; then
    echo "Saving results to cache" >> "${settings_dir}/execute_debug.log"
    save_cache "$entity_type" "$query" "$additional_params" "$xml_output"
  else
    echo "Caching disabled - not saving to cache" >> "${settings_dir}/execute_debug.log"
  fi

  echo "$xml_output"
}

# Process commands
case "$command_type" in
  "s") # Search tasks
    completed="false"
    flagged="false"
    active_only="true"
    additional_params="completed:${completed}_flagged:${flagged}_active:${active_only}"

    execute_and_cache "task" "${WORKFLOW_DIR}/applescript/search_tasks.js" "$query" "$additional_params" "$completed" "$flagged" "$active_only"
    ;;

  "sc") # Search completed tasks
    completed="true"
    flagged="false"
    active_only="false"
    additional_params="completed:${completed}_flagged:${flagged}_active:${active_only}"

    execute_and_cache "task" "${WORKFLOW_DIR}/applescript/search_tasks.js" "$query" "$additional_params" "$completed" "$flagged" "$active_only"
    ;;

  "p") # Search projects
    active_only="true"
    additional_params="active:${active_only}"

    execute_and_cache "project" "${WORKFLOW_DIR}/applescript/search_projects.js" "$query" "$additional_params" "$active_only"
    ;;

  "i") # Search inbox
    execute_and_cache "inbox" "${WORKFLOW_DIR}/applescript/search_inbox.js" "$query" ""
    ;;

  "t") # Search tags
    execute_and_cache "tag" "${WORKFLOW_DIR}/applescript/search_tags.js" "$query" ""
    ;;

  "f") # Search folders
    execute_and_cache "folder" "${WORKFLOW_DIR}/applescript/search_folders.js" "$query" ""
    ;;

  "v") # List perspectives
    execute_and_cache "perspective" "${WORKFLOW_DIR}/applescript/get_perspectives.js" "$query" ""
    ;;

  "n") # Search notes
    execute_and_cache "note" "${WORKFLOW_DIR}/applescript/search_notes.js" "$query" ""
    ;;

  "find-of-db") # Find OmniFocus database
    find_omnifocus_database
    ;;

  "set-of-db") # Set OmniFocus database path
    set_omnifocus_database_path "$query"
    ;;

  "clear-cache") # Clear cache
    # Handle "clear" as a default command without arguments
    if [[ "$query" == "clear" || -z "$query" ]]; then
      clear_all_cache
      show_message "Cache Cleared" "All cache has been cleared" "${WORKFLOW_DIR}/icons/success.png"
    else
      clear_entity_cache "$query"
      show_message "Cache Cleared" "Cache for $query has been cleared" "${WORKFLOW_DIR}/icons/success.png"
    fi
    ;;

  "rebuild-cache") # Rebuild cache
    # Handle "rebuild" as a default command without arguments
    if [[ "$query" == "rebuild" || -z "$query" ]]; then
      show_message "Rebuilding Cache" "This may take a moment..." "${WORKFLOW_DIR}/icons/refresh.png"
      rebuild_cache
      show_message "Cache Rebuilt" "Cache has been successfully rebuilt" "${WORKFLOW_DIR}/icons/success.png"
    else
      show_message "Rebuilding Cache" "Rebuilding cache for $query..." "${WORKFLOW_DIR}/icons/refresh.png"
      rebuild_cache "$query"
      show_message "Cache Rebuilt" "Cache for $query has been successfully rebuilt" "${WORKFLOW_DIR}/icons/success.png"
    fi
    ;;

  "cache-stats") # Show cache statistics
    # Handle "stats" as a default command without arguments
    if [[ "$query" == "stats" || -z "$query" ]]; then
      # Format cache stats as Alfred XML
      echo '<?xml version="1.0" encoding="UTF-8"?>'
      echo '<items>'

      # Get stats data
      stats_data=$(cache_stats)

      # Extract basic stats
      total_queries=$(echo "$stats_data" | grep "Total Queries:" | awk '{print $NF}')
      cache_hits=$(echo "$stats_data" | grep "Cache Hits:" | awk '{print $NF}')
      hit_rate=$(echo "$stats_data" | grep "Hit Rate:" | awk '{print $3}')

      # Main stats item
      echo '  <item uid="stats_main" arg="stats_main">'
      echo '    <title>Cache Statistics Summary</title>'
      echo "    <subtitle>Total Queries: $total_queries | Cache Hits: $cache_hits | Hit Rate: $hit_rate</subtitle>"
      echo '    <icon>icons/info.png</icon>'
      echo '  </item>'

      # Add entity-specific stats
      entity_stats=$(echo "$stats_data" | sed -n '/Entity-specific hit rates:/,//p' | tail -n +2)
      if [[ -n "$entity_stats" ]]; then
        while read -r line; do
          if [[ -n "$line" ]]; then
            entity=$(echo "$line" | awk '{print $1}' | tr -d ':')
            hit_rate=$(echo "$line" | awk '{print $2}')
            details=$(echo "$line" | awk '{print $3}' | tr -d '()')

            echo "  <item uid=\"stats_$entity\" arg=\"stats_$entity\">"
            echo "    <title>$entity Hit Rate: $hit_rate</title>"
            echo "    <subtitle>$details</subtitle>"
            echo "    <icon>icons/$entity.png</icon>"
            echo "  </item>"
          fi
        done <<< "$entity_stats"
      fi

      echo '</items>'
    else
      # Handle entity-specific stats if we implement that in the future
      echo '<?xml version="1.0" encoding="UTF-8"?>'
      echo '<items>'
      echo '  <item uid="stats_error" arg="stats_error">'
      echo '    <title>Cache Statistics</title>'
      echo '    <subtitle>Entity-specific stats not yet implemented</subtitle>'
      echo '    <icon>icons/info.png</icon>'
      echo '  </item>'
      echo '</items>'
    fi
    ;;

  "cache-commands") # Show cache commands
    "${WORKFLOW_DIR}/bin/cache_commands.sh" "$query"
    ;;

  "enable-caching") # Enable caching
    # Handle "enable" as a command without arguments
    if [[ "$query" == "enable" || -z "$query" ]]; then
      enable_caching
    else
      show_error "Invalid Command" "Expected 'enable' but got '$query'"
    fi
    ;;

  "disable-caching") # Disable caching
    # Handle "disable" as a command without arguments
    if [[ "$query" == "disable" || -z "$query" ]]; then
      disable_caching
    else
      show_error "Invalid Command" "Expected 'disable' but got '$query'"
    fi
    ;;

  "check-update") # Check for updates
    # Run the update checker script
    "${WORKFLOW_DIR}/bin/update_checker.sh"
    ;;

  "install-update") # Install update
    # Run the update installer script with the provided download URL
    "${WORKFLOW_DIR}/bin/update_installer.sh" "$query"
    ;;

  *) # Unknown command
    # Default - show error for unknown command
    show_error "Unknown command" "Command type '$command_type' is not recognized"
    ;;
esac