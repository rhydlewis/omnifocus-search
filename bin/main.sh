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
command_type="$2"

# Process commands
case "$command_type" in
  "s") # Search tasks
    completed="false"
    flagged="false"
    active_only="true"

    # Try to get from cache first
    additional_params="completed:${completed}_flagged:${flagged}_active:${active_only}"
    cached_results=$(get_cache "task" "$query" "$additional_params")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "$query" "$completed" "$flagged" "$active_only")
      xml_output=$(generate_xml_output "task" "$results")

      # Save to cache
      save_cache "task" "$query" "$additional_params" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "sc") # Search completed tasks
    completed="true"
    flagged="false"
    active_only="false"

    # Try to get from cache first
    additional_params="completed:${completed}_flagged:${flagged}_active:${active_only}"
    cached_results=$(get_cache "task" "$query" "$additional_params")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "$query" "$completed" "$flagged" "$active_only")
      xml_output=$(generate_xml_output "task" "$results")

      # Save to cache
      save_cache "task" "$query" "$additional_params" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "p") # Search projects
    active_only="true"

    # Try to get from cache first
    additional_params="active:${active_only}"
    cached_results=$(get_cache "project" "$query" "$additional_params")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_projects.applescript" "$query" "$active_only")
      xml_output=$(generate_xml_output "project" "$results")

      # Save to cache
      save_cache "project" "$query" "$additional_params" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "i") # Search inbox
    # Try to get from cache first
    cached_results=$(get_cache "inbox" "$query" "")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_inbox.applescript" "$query")
      xml_output=$(generate_xml_output "task" "$results")

      # Save to cache
      save_cache "inbox" "$query" "" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "t") # Search tags
    # Try to get from cache first
    cached_results=$(get_cache "tag" "$query" "")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tags.applescript" "$query")
      xml_output=$(generate_xml_output "tag" "$results")

      # Save to cache
      save_cache "tag" "$query" "" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "f") # Search folders
    # Try to get from cache first
    cached_results=$(get_cache "folder" "$query" "")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_folders.applescript" "$query")
      xml_output=$(generate_xml_output "folder" "$results")

      # Save to cache
      save_cache "folder" "$query" "" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "v") # List perspectives
    # Try to get from cache first
    cached_results=$(get_cache "perspective" "$query" "")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/get_perspectives.applescript" "$query")
      xml_output=$(generate_xml_output "perspective" "$results")

      # Save to cache
      save_cache "perspective" "$query" "" "$xml_output"

      echo "$xml_output"
    fi
    ;;

  "n") # Search notes
    # Try to get from cache first
    cached_results=$(get_cache "note" "$query" "")

    if [[ $? -eq 0 ]]; then
      # Cache hit
      echo "$cached_results"
    else
      # Cache miss - call the AppleScript and process results
      results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_notes.applescript" "$query")
      xml_output=$(generate_xml_output "task" "$results")

      # Save to cache
      save_cache "note" "$query" "" "$xml_output"

      echo "$xml_output"
    fi
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