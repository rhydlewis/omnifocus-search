#!/bin/bash

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the utility scripts
[ -f "${WORKFLOW_DIR}/bin/format_xml.sh" ] && source "${WORKFLOW_DIR}/bin/format_xml.sh"
[ -f "${WORKFLOW_DIR}/bin/config.sh" ] && source "${WORKFLOW_DIR}/bin/config.sh"
[ -f "${WORKFLOW_DIR}/bin/error_handler.sh" ] && source "${WORKFLOW_DIR}/bin/error_handler.sh"
[ -f "${WORKFLOW_DIR}/lib/constants.sh" ] && source "${WORKFLOW_DIR}/lib/constants.sh"
[ -f "${WORKFLOW_DIR}/bin/cache_manager.sh" ] && source "${WORKFLOW_DIR}/bin/cache_manager.sh"

# Log rotation function
rotate_logs_if_needed() {
  local settings_dir="$1"
  local rotation_days=7
  local rotation_marker="${settings_dir}/.log_rotation_marker"

  # Check if we've already rotated today (avoid checking repeatedly)
  if [ -f "$rotation_marker" ]; then
    local marker_age=$(( $(date +%s) - $(stat -f %m "$rotation_marker" 2>/dev/null || echo 0) ))
    # If marker is less than 24 hours old, skip rotation check
    if [ "$marker_age" -lt 86400 ]; then
      return 0
    fi
  fi

  # Check and rotate execute_debug.log if needed
  local debug_log="${settings_dir}/execute_debug.log"
  if [ -f "$debug_log" ]; then
    local log_age=$(( $(date +%s) - $(stat -f %m "$debug_log" 2>/dev/null || echo 0) ))
    local max_age=$((rotation_days * 86400))

    if [ "$log_age" -gt "$max_age" ]; then
      echo "=== Log rotated on $(date) ===" > "$debug_log"
      echo "Previous log was older than $rotation_days days" >> "$debug_log"
      echo "" >> "$debug_log"
    fi
  fi

  # Check and rotate performance.log if needed
  local perf_log="${settings_dir}/performance.log"
  if [ -f "$perf_log" ]; then
    local log_age=$(( $(date +%s) - $(stat -f %m "$perf_log" 2>/dev/null || echo 0) ))
    local max_age=$((rotation_days * 86400))

    if [ "$log_age" -gt "$max_age" ]; then
      echo "=== Log rotated on $(date) ===" > "$perf_log"
      echo "Previous log was older than $rotation_days days" >> "$perf_log"
      echo "" >> "$perf_log"
    fi
  fi

  # Update rotation marker
  touch "$rotation_marker" 2>/dev/null
}

# Parse the input arguments
query="$1"
# Handle case where Alfred passes "(null)" as a literal string
if [[ "$query" == "(null)" ]]; then
  query=""
fi
command_type="$2"

# Show help if -h flag is passed
if [[ "$query" == "-h" || "$command_type" == "-h" ]]; then
  cat << 'EOF'
OmniFocus Search Workflow - Main Script Usage

SYNOPSIS:
  main.sh <query> <command_type>

PARAMETERS:
  query         - Search query string or command argument
  command_type  - Type of search or command to execute

COMMAND TYPES:

Search Commands:
  s   - Search active tasks
        Usage: main.sh "search term" s
        Parameters: completed=false, flagged=false, active_only=true

  sc  - Search completed tasks
        Usage: main.sh "search term" sc
        Parameters: completed=true, flagged=false, active_only=false

  p   - Search projects
        Usage: main.sh "project name" p
        Parameters: active_only=true

  i   - Search inbox
        Usage: main.sh "search term" i

  t   - Search tags
        Usage: main.sh "tag name" t

  f   - Search folders
        Usage: main.sh "folder name" f

  v   - List perspectives
        Usage: main.sh "perspective name" v

  n   - Search notes
        Usage: main.sh "search term" n

Cache Commands:
  clear-cache    - Clear all cache or specific entity cache
                   Usage: main.sh "clear" clear-cache (clear all)
                   Usage: main.sh "task" clear-cache (clear task cache)

  rebuild-cache  - Rebuild all cache or specific entity cache
                   Usage: main.sh "rebuild" rebuild-cache (rebuild all)
                   Usage: main.sh "task" rebuild-cache (rebuild task cache)

  cache-stats    - Show cache statistics
                   Usage: main.sh "stats" cache-stats

  cache-commands - Show available cache commands
                   Usage: main.sh "" cache-commands

Update Commands:
  check-update   - Check for workflow updates
                   Usage: main.sh "" check-update

  install-update - Install workflow update
                   Usage: main.sh "download_url" install-update

EXAMPLES:
  # Search for active tasks containing "meeting"
  main.sh "meeting" s

  # Search completed tasks
  main.sh "report" sc

  # Search for a project named "Website"
  main.sh "Website" p

  # Search tags
  main.sh "urgent" t

  # Clear all cache
  main.sh "clear" clear-cache

  # Show cache statistics
  main.sh "stats" cache-stats

SCRIPT DETECTION:
  The script automatically detects whether to use AppleScript (.applescript) or
  JXA (.js) based on the file extension in the applescript/ directory.

CACHING:
  Caching is disabled by default and can improve performance significantly.
  Configure caching via the Alfred workflow configuration UI (click the [x] button in Alfred).

LOGS:
  Debug logs: execute_debug.log
  Performance logs: performance.log
  Logs are automatically rotated every 7 days.

EOF
  exit 0
fi

# Define the function to execute scripts (AppleScript or JXA) and format output
execute_and_cache() {
  local entity_type="$1"
  local script_path="$2"
  local query="$3"
  local additional_params="$4"

  # Create settings directory if it doesn't exist
  local settings_dir="${HOME}/Library/Caches/com.runningwithcrayons.Alfred/Workflow Data/net.rhydlewis.alfred.omnifocussearch/settings"
  mkdir -p "$settings_dir" 2>/dev/null

  # Rotate logs if needed (once per day check)
  rotate_logs_if_needed "$settings_dir"

  # Debug log
  echo "[$entity_type] execute_and_cache called at $(date)" > "${settings_dir}/execute_debug.log"
  echo "Script: $script_path" >> "${settings_dir}/execute_debug.log"
  echo "Query: $query" >> "${settings_dir}/execute_debug.log"
  echo "Params: $additional_params" >> "${settings_dir}/execute_debug.log"

  # Check if caching is enabled from Alfred environment variable
  local caching_status=$(is_caching_enabled)
  echo "Caching status: $caching_status" >> "${settings_dir}/execute_debug.log"

  # Check cache first if caching is enabled
  if [[ "$caching_status" == "true" ]]; then
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

  # Execute the script with timeout and performance monitoring
  local timeout_duration=30
  local start_time=$(date +%s)

  if [[ "$script_type" == "jxa" ]]; then
    # Execute JXA script with timeout
    results=$(timeout "$timeout_duration" /usr/bin/osascript -l JavaScript "$script_path" "$query" "${@:5}" 2>&1)
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "JXA script execution time: ${duration}s" >> "${settings_dir}/execute_debug.log"
    echo "Script type: JXA" >> "${settings_dir}/performance.log"
    echo "Script: $script_path" >> "${settings_dir}/performance.log"
    echo "Duration: ${duration}s" >> "${settings_dir}/performance.log"
    echo "Timestamp: $(date)" >> "${settings_dir}/performance.log"
    echo "---" >> "${settings_dir}/performance.log"

    if [[ $exit_code -eq 124 ]]; then
      echo "Script execution timed out after ${timeout_duration}s" >> "${settings_dir}/execute_debug.log"
      handle_jxa_error "Script execution timed out after ${timeout_duration} seconds"
      return 1
    elif [[ $exit_code -ne 0 ]]; then
      echo "Script execution failed with exit code $exit_code" >> "${settings_dir}/execute_debug.log"
      echo "Error output: $results" >> "${settings_dir}/execute_debug.log"
      handle_jxa_error "$results"
      return 1
    fi
  else
    # Execute AppleScript with timeout
    results=$(timeout "$timeout_duration" /usr/bin/osascript "$script_path" "$query" "${@:5}" 2>&1)
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo "AppleScript execution time: ${duration}s" >> "${settings_dir}/execute_debug.log"
    echo "Script type: AppleScript" >> "${settings_dir}/performance.log"
    echo "Script: $script_path" >> "${settings_dir}/performance.log"
    echo "Duration: ${duration}s" >> "${settings_dir}/performance.log"
    echo "Timestamp: $(date)" >> "${settings_dir}/performance.log"
    echo "---" >> "${settings_dir}/performance.log"

    if [[ $exit_code -eq 124 ]]; then
      echo "Script execution timed out after ${timeout_duration}s" >> "${settings_dir}/execute_debug.log"
      handle_applescript_error "Script execution timed out after ${timeout_duration} seconds"
      return 1
    elif [[ $exit_code -ne 0 ]]; then
      echo "Script execution failed with exit code $exit_code" >> "${settings_dir}/execute_debug.log"
      echo "Error output: $results" >> "${settings_dir}/execute_debug.log"
      handle_applescript_error "$results"
      return 1
    fi
  fi

  xml_output=$(generate_xml_output "$entity_type" "$results")

  # Save to cache if enabled
  if [[ "$caching_status" == "true" ]]; then
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