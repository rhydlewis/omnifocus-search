#!/bin/bash

# Cache manager for OmniFocus search

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the utility scripts if needed
[ -f "${WORKFLOW_DIR}/bin/format_xml.sh" ] && source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Get the home directory explicitly
HOME_DIR=$(eval echo ~$USER)

# Cache directory
CACHE_DIR="${HOME_DIR}/.cache/alfred-omnifocus-search"

# Ensure cache directory exists
if [[ ! -d "$CACHE_DIR" ]]; then
  mkdir -p "$CACHE_DIR/projects"
  mkdir -p "$CACHE_DIR/folders"
  mkdir -p "$CACHE_DIR/tags"
  mkdir -p "$CACHE_DIR/perspectives"
  mkdir -p "$CACHE_DIR/tasks"
  mkdir -p "$CACHE_DIR/completed_tasks"
  mkdir -p "$CACHE_DIR/inbox"
  mkdir -p "$CACHE_DIR/notes"
fi

# Cache lifetimes in seconds
PROJECTS_CACHE_LIFE=86400       # 24 hours
FOLDERS_CACHE_LIFE=86400        # 24 hours
TAGS_CACHE_LIFE=86400           # 24 hours
PERSPECTIVES_CACHE_LIFE=86400   # 24 hours
TASKS_CACHE_LIFE=1800           # 30 minutes
COMPLETED_TASKS_CACHE_LIFE=21600 # 6 hours
INBOX_CACHE_LIFE=900            # 15 minutes
NOTES_CACHE_LIFE=3600           # 1 hour

# Check if cache is valid
is_cache_valid() {
  local cache_file="$1"
  local max_age="$2"

  if [[ ! -f "$cache_file" ]]; then
    echo "Cache file does not exist: $cache_file" >> "${CACHE_DIR}/is_valid.log"
    return 1
  fi

  # Get file modification time
  local file_mod_time=$(stat -f "%m" "$cache_file")
  local current_time=$(date +%s)
  local age=$((current_time - file_mod_time))

  # Log the validation results
  echo "Cache validation:" >> "${CACHE_DIR}/is_valid.log"
  echo "File: $cache_file" >> "${CACHE_DIR}/is_valid.log"
  echo "File mod time: $file_mod_time" >> "${CACHE_DIR}/is_valid.log"
  echo "Current time: $current_time" >> "${CACHE_DIR}/is_valid.log"
  echo "Age: $age seconds" >> "${CACHE_DIR}/is_valid.log"
  echo "Max age: $max_age seconds" >> "${CACHE_DIR}/is_valid.log"

  if [[ $age -lt $max_age ]]; then
    echo "Result: VALID" >> "${CACHE_DIR}/is_valid.log"
    return 0
  else
    echo "Result: EXPIRED" >> "${CACHE_DIR}/is_valid.log"
    return 1
  fi
}

# Get cache for a query
get_cache() {
  local entity_type="$1"
  local query="$2"
  local additional_params="$3"  # For flags like completed/flagged

  # Create cache key from query and params
  local cache_key="${query}_${additional_params}"
  if [[ -z "$query" ]]; then
    cache_key="all_${additional_params}"
  fi

  # Create safe filename from cache key
  local safe_key=$(echo "$cache_key" | sed 's/[^a-zA-Z0-9]/_/g')

  # Set cache file and lifetime based on entity type
  local cache_file=""
  local cache_life=0

  case "$entity_type" in
    "project")
      cache_file="${CACHE_DIR}/projects/${safe_key}.cache"
      cache_life=$PROJECTS_CACHE_LIFE
      ;;
    "folder")
      cache_file="${CACHE_DIR}/folders/${safe_key}.cache"
      cache_life=$FOLDERS_CACHE_LIFE
      ;;
    "tag")
      cache_file="${CACHE_DIR}/tags/${safe_key}.cache"
      cache_life=$TAGS_CACHE_LIFE
      ;;
    "perspective")
      cache_file="${CACHE_DIR}/perspectives/${safe_key}.cache"
      cache_life=$PERSPECTIVES_CACHE_LIFE
      ;;
    "task")
      if [[ "$additional_params" == *"completed:true"* ]]; then
        cache_file="${CACHE_DIR}/completed_tasks/${safe_key}.cache"
        cache_life=$COMPLETED_TASKS_CACHE_LIFE
      else
        cache_file="${CACHE_DIR}/tasks/${safe_key}.cache"
        cache_life=$TASKS_CACHE_LIFE
      fi
      ;;
    "inbox")
      cache_file="${CACHE_DIR}/inbox/${safe_key}.cache"
      cache_life=$INBOX_CACHE_LIFE
      ;;
    "note")
      cache_file="${CACHE_DIR}/notes/${safe_key}.cache"
      cache_life=$NOTES_CACHE_LIFE
      ;;
  esac

  # Debug info
  echo "Cache lookup for: $cache_file" > "${CACHE_DIR}/last_lookup.log"
  echo "Time: $(date)" >> "${CACHE_DIR}/last_lookup.log"
  echo "Entity: $entity_type" >> "${CACHE_DIR}/last_lookup.log"
  echo "Query: $query" >> "${CACHE_DIR}/last_lookup.log"
  echo "Params: $additional_params" >> "${CACHE_DIR}/last_lookup.log"
  echo "File exists: $(test -f "$cache_file" && echo Yes || echo No)" >> "${CACHE_DIR}/last_lookup.log"

  # Check if cache is valid
  if is_cache_valid "$cache_file" "$cache_life"; then
    # Log cache hit
    log_cache_hit "$entity_type" "$query"

    # Debug that we're returning a valid cache file
    echo "CACHE HIT - returning from cache" >> "${CACHE_DIR}/last_lookup.log"

    # Return cached content
    cat "$cache_file"
    return 0
  else
    # Log cache miss
    log_cache_miss "$entity_type" "$query"

    # Debug the cache miss reason
    if [[ ! -f "$cache_file" ]]; then
      echo "CACHE MISS - file does not exist" >> "${CACHE_DIR}/last_lookup.log"
    else
      echo "CACHE MISS - file is too old" >> "${CACHE_DIR}/last_lookup.log"
    fi

    return 1
  fi
}

# Save results to cache
save_cache() {
  local entity_type="$1"
  local query="$2"
  local additional_params="$3"
  local results="$4"

  # Create cache key from query and params
  local cache_key="${query}_${additional_params}"
  if [[ -z "$query" ]]; then
    cache_key="all_${additional_params}"
  fi

  # Create safe filename from cache key
  local safe_key=$(echo "$cache_key" | sed 's/[^a-zA-Z0-9]/_/g')

  # Set cache file based on entity type
  local cache_file=""

  case "$entity_type" in
    "project")
      cache_file="${CACHE_DIR}/projects/${safe_key}.cache"
      ;;
    "folder")
      cache_file="${CACHE_DIR}/folders/${safe_key}.cache"
      ;;
    "tag")
      cache_file="${CACHE_DIR}/tags/${safe_key}.cache"
      ;;
    "perspective")
      cache_file="${CACHE_DIR}/perspectives/${safe_key}.cache"
      ;;
    "task")
      if [[ "$additional_params" == *"completed:true"* ]]; then
        cache_file="${CACHE_DIR}/completed_tasks/${safe_key}.cache"
      else
        cache_file="${CACHE_DIR}/tasks/${safe_key}.cache"
      fi
      ;;
    "inbox")
      cache_file="${CACHE_DIR}/inbox/${safe_key}.cache"
      ;;
    "note")
      cache_file="${CACHE_DIR}/notes/${safe_key}.cache"
      ;;
  esac

  # Save results to cache file
  echo "$results" > "$cache_file"

  # Debug info
  echo "Cache saved to: $cache_file" > "${CACHE_DIR}/last_save.log"
  echo "Time: $(date)" >> "${CACHE_DIR}/last_save.log"
  echo "Entity: $entity_type" >> "${CACHE_DIR}/last_save.log"
  echo "Query: $query" >> "${CACHE_DIR}/last_save.log"
  echo "Params: $additional_params" >> "${CACHE_DIR}/last_save.log"

  # Create a small marker file to track
  touch "${CACHE_DIR}/last_save.tmp"
}

# Clear all cache
clear_all_cache() {
  rm -rf "${CACHE_DIR}"/*
  mkdir -p "${CACHE_DIR}/projects"
  mkdir -p "${CACHE_DIR}/folders"
  mkdir -p "${CACHE_DIR}/tags"
  mkdir -p "${CACHE_DIR}/perspectives"
  mkdir -p "${CACHE_DIR}/tasks"
  mkdir -p "${CACHE_DIR}/completed_tasks"
  mkdir -p "${CACHE_DIR}/inbox"
  mkdir -p "${CACHE_DIR}/notes"
}

# Clear cache for a specific entity type
clear_entity_cache() {
  local entity_type="$1"

  case "$entity_type" in
    "project"|"projects")
      rm -rf "${CACHE_DIR}/projects"/*
      mkdir -p "${CACHE_DIR}/projects"
      ;;
    "folder"|"folders")
      rm -rf "${CACHE_DIR}/folders"/*
      mkdir -p "${CACHE_DIR}/folders"
      ;;
    "tag"|"tags")
      rm -rf "${CACHE_DIR}/tags"/*
      mkdir -p "${CACHE_DIR}/tags"
      ;;
    "perspective"|"perspectives")
      rm -rf "${CACHE_DIR}/perspectives"/*
      mkdir -p "${CACHE_DIR}/perspectives"
      ;;
    "task"|"tasks")
      rm -rf "${CACHE_DIR}/tasks"/*
      mkdir -p "${CACHE_DIR}/tasks"
      ;;
    "completed_task"|"completed_tasks"|"completed")
      rm -rf "${CACHE_DIR}/completed_tasks"/*
      mkdir -p "${CACHE_DIR}/completed_tasks"
      ;;
    "inbox")
      rm -rf "${CACHE_DIR}/inbox"/*
      mkdir -p "${CACHE_DIR}/inbox"
      ;;
    "note"|"notes")
      rm -rf "${CACHE_DIR}/notes"/*
      mkdir -p "${CACHE_DIR}/notes"
      ;;
    *)
      clear_all_cache
      ;;
  esac
}

# Cache statistics logging
log_cache_hit() {
  local entity_type="$1"
  local query="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') HIT $entity_type $query" >> "${CACHE_DIR}/cache_stats.log"
  # Debug line to check if hit is registered
  touch "${CACHE_DIR}/last_hit.tmp"
}

log_cache_miss() {
  local entity_type="$1"
  local query="$2"
  echo "$(date '+%Y-%m-%d %H:%M:%S') MISS $entity_type $query" >> "${CACHE_DIR}/cache_stats.log"
  # Debug line to check if miss is registered
  touch "${CACHE_DIR}/last_miss.tmp"
}

# Display cache statistics
cache_stats() {
  if [[ -f "${CACHE_DIR}/cache_stats.log" ]]; then
    local total_queries=$(wc -l < "${CACHE_DIR}/cache_stats.log")
    local hits=$(grep "HIT" "${CACHE_DIR}/cache_stats.log" | wc -l)
    local hit_rate=$(awk "BEGIN { printf \"%.1f\", ($hits / $total_queries) * 100 }")

    echo "Cache Statistics:"
    echo "Total Queries: $total_queries"
    echo "Cache Hits: $hits"
    echo "Hit Rate: ${hit_rate}%"

    # Entity-specific stats
    echo ""
    echo "Entity-specific hit rates:"
    for entity in project folder tag perspective task inbox note; do
      local entity_queries=$(grep " $entity " "${CACHE_DIR}/cache_stats.log" | wc -l)
      if [[ $entity_queries -gt 0 ]]; then
        local entity_hits=$(grep "HIT $entity " "${CACHE_DIR}/cache_stats.log" | wc -l)
        local entity_hit_rate=$(awk "BEGIN { printf \"%.1f\", ($entity_hits / $entity_queries) * 100 }")
        echo "  $entity: ${entity_hit_rate}% ($entity_hits/$entity_queries)"
      fi
    done
  else
    echo "No cache statistics available"
  fi
}

# Rebuild cache with common queries
rebuild_cache() {
  local query="$1" # Can be empty for all entities

  # Clear existing cache
  if [[ -z "$query" ]]; then
    clear_all_cache
  else
    clear_entity_cache "$query"
  fi

  if [[ -z "$query" || "$query" == "task" || "$query" == "tasks" ]]; then
    # Warm up tasks cache
    echo "Rebuilding tasks cache..."

    # Active tasks (no query - all active tasks)
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "" "false" "false" "true")
    local xml_output=$(generate_xml_output "task" "$results")
    save_cache "task" "" "completed:false_flagged:false_active:true" "$xml_output"

    # Flagged tasks
    results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "" "false" "true" "true")
    xml_output=$(generate_xml_output "task" "$results")
    save_cache "task" "" "completed:false_flagged:true_active:true" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "completed" || "$query" == "completed_tasks" ]]; then
    # Warm up completed tasks cache (recent ones)
    echo "Rebuilding completed tasks cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.applescript" "" "true" "false" "false")
    local xml_output=$(generate_xml_output "task" "$results")
    save_cache "task" "" "completed:true_flagged:false_active:false" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "project" || "$query" == "projects" ]]; then
    # Warm up projects cache
    echo "Rebuilding projects cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_projects.applescript" "" "true")
    local xml_output=$(generate_xml_output "project" "$results")
    save_cache "project" "" "active:true" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "tag" || "$query" == "tags" ]]; then
    # Warm up tags cache
    echo "Rebuilding tags cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tags.applescript" "")
    local xml_output=$(generate_xml_output "tag" "$results")
    save_cache "tag" "" "" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "folder" || "$query" == "folders" ]]; then
    # Warm up folders cache
    echo "Rebuilding folders cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_folders.applescript" "")
    local xml_output=$(generate_xml_output "folder" "$results")
    save_cache "folder" "" "" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "perspective" || "$query" == "perspectives" ]]; then
    # Warm up perspectives cache
    echo "Rebuilding perspectives cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/get_perspectives.applescript" "")
    local xml_output=$(generate_xml_output "perspective" "$results")
    save_cache "perspective" "" "" "$xml_output"
  fi

  if [[ -z "$query" || "$query" == "inbox" ]]; then
    # Warm up inbox cache
    echo "Rebuilding inbox cache..."
    local results=$(/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_inbox.applescript" "")
    local xml_output=$(generate_xml_output "task" "$results")
    save_cache "inbox" "" "" "$xml_output"
  fi

  echo "Cache rebuild complete."
}