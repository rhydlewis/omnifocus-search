#!/bin/bash

WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
source "${WORKFLOW_DIR}/bin/format_xml.sh"

format_available_tasks() {
  local json_data="$1"
  local show_verbose="$2"

  # Extract tasks and blocked counts
  local tasks=$(echo "$json_data" | jq -r '.tasks')
  local total_available=$(echo "$json_data" | jq -r '.totalAvailable')
  local total_blocked=$(echo "$json_data" | jq -r '.totalBlocked')

  local blocked_on_hold=$(echo "$json_data" | jq -r '.blocked.projectOnHold')
  local blocked_deferred=$(echo "$json_data" | jq -r '.blocked.projectDeferred')
  local blocked_task_defer=$(echo "$json_data" | jq -r '.blocked.taskDeferred')
  local blocked_sequential=$(echo "$json_data" | jq -r '.blocked.sequential')

  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<items>'

  # Generate task items
  echo "$tasks" | jq -r '.[] | @json' | while read -r task_json; do
    local id=$(echo "$task_json" | jq -r '.id')
    local name=$(echo "$task_json" | jq -r '.name')
    local project=$(echo "$task_json" | jq -r '.projectName')
    local flagged=$(echo "$task_json" | jq -r '.flagged')
    local due=$(echo "$task_json" | jq -r '.dueDate')

    local subtitle="$project"

    # Add due date if present
    if [[ -n "$due" && "$due" != "null" ]]; then
      local due_display=$(date -j -f "%a %b %d %Y %T" "$due" "+%b %d, %Y" 2>/dev/null || echo "$due")
      subtitle="$subtitle | Due: $due_display"
    fi

    # Add flag indicator
    local title="$name"
    if [[ "$flagged" == "true" ]]; then
      title="🚩 $title"
    fi

    # Escape XML special characters
    title=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
    subtitle=$(echo "$subtitle" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

    echo "  <item uid=\"$id\" arg=\"$id\">"
    echo "    <title>$title</title>"
    echo "    <subtitle>$subtitle</subtitle>"
    echo "    <icon>icons/active.png</icon>"
    echo "  </item>"
  done

  # Add summary footer if verbose or if there are blocked tasks
  if [[ "$show_verbose" == "true" || $total_blocked -gt 0 ]]; then
    echo "  <item uid=\"summary\" valid=\"false\">"
    echo "    <title>Available: $total_available | Blocked: $total_blocked</title>"

    local details=""
    if [[ $blocked_on_hold -gt 0 ]]; then
      details="${details}On Hold: $blocked_on_hold | "
    fi
    if [[ $blocked_deferred -gt 0 ]]; then
      details="${details}Project Deferred: $blocked_deferred | "
    fi
    if [[ $blocked_task_defer -gt 0 ]]; then
      details="${details}Task Deferred: $blocked_task_defer | "
    fi
    if [[ $blocked_sequential -gt 0 ]]; then
      details="${details}Sequential: $blocked_sequential"
    fi

    # Remove trailing separator
    details=$(echo "$details" | sed 's/ | $//')

    echo "    <subtitle>$details</subtitle>"
    echo "    <icon>icons/info.png</icon>"
    echo "  </item>"
  fi

  # Show helpful message if no results
  if [[ $total_available -eq 0 ]]; then
    echo "  <item uid=\"no_results\" valid=\"false\">"
    echo "    <title>No available tasks found</title>"
    if [[ $total_blocked -gt 0 ]]; then
      echo "    <subtitle>$total_blocked tasks are blocked by project status or defer dates</subtitle>"
    else
      echo "    <subtitle>No tasks match your search criteria</subtitle>"
    fi
    echo "    <icon>icons/info.png</icon>"
    echo "  </item>"
  fi

  echo '</items>'
}

# If called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  json_data="$1"
  show_verbose="${2:-false}"
  format_available_tasks "$json_data" "$show_verbose"
fi
