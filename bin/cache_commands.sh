#!/bin/bash

# Script to handle cache management commands in Alfred

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source config.sh to get access to caching functions
[ -f "${WORKFLOW_DIR}/bin/config.sh" ] && source "${WORKFLOW_DIR}/bin/config.sh"

# Check if caching is enabled
caching_status=$(is_caching_enabled)

# Generate XML for Alfred
echo '<?xml version="1.0" encoding="UTF-8"?>'
echo '<items>'

# If caching is disabled, show message and exit
if [[ "$caching_status" == "false" ]]; then
  echo '  <item uid="caching_disabled" valid="false">'
  echo '    <title>Caching is Disabled</title>'
  echo '    <subtitle>Enable caching in the workflow configuration to use cache commands</subtitle>'
  echo '    <icon>icons/error.png</icon>'
  echo '  </item>'
  echo '</items>'
  exit 0
fi

# Filter based on query
query="$1"
query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

# Define commands as separate variables since some bash versions don't support associative arrays
cmd_rebuild="Rebuild Cache|Rebuild the OmniFocus search cache for better performance|icons/refresh.png"
cmd_tasks="Rebuild Tasks Cache|Rebuild only the tasks cache|icons/active.png"
cmd_completed="Rebuild Completed Tasks Cache|Rebuild only the completed tasks cache|icons/completed.png"
cmd_projects="Rebuild Projects Cache|Rebuild only the projects cache|icons/project.png"
cmd_tags="Rebuild Tags Cache|Rebuild only the tags cache|icons/tag.png"
cmd_folders="Rebuild Folders Cache|Rebuild only the folders cache|icons/folder.png"
cmd_perspectives="Rebuild Perspectives Cache|Rebuild only the perspectives cache|icons/perspective.png"

# Function to check if command matches the query
matches_query() {
    local cmd="$1"
    local title="$2"

    if [[ -z "$query" ]]; then
        # Empty query matches everything
        return 0
    fi

    # Check if command or title contains query
    local title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
    if [[ "$cmd" == *"$query_lower"* || "$title_lower" == *"$query_lower"* ]]; then
        return 0
    fi

    return 1
}

# Function to output a command item
output_command() {
    local cmd="$1"
    local info="$2"

    IFS='|' read -r title subtitle icon <<< "$info"

    if matches_query "$cmd" "$title"; then
        echo "  <item uid=\"$cmd\" arg=\"$cmd\">"
        echo "    <title>$title</title>"
        echo "    <subtitle>$subtitle</subtitle>"
        echo "    <icon>$icon</icon>"
        echo "  </item>"
    fi
}

# Output all commands
output_command "rebuild" "$cmd_rebuild"
output_command "tasks" "$cmd_tasks"
output_command "completed" "$cmd_completed"
output_command "projects" "$cmd_projects"
output_command "tags" "$cmd_tags"
output_command "folders" "$cmd_folders"
output_command "perspectives" "$cmd_perspectives"

echo '</items>'