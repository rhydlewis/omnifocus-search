#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Format XML for a task item
format_task_item() {
  local id="$1"
  local name="$2"
  local project="$3"
  local status="$4"  # active, completed, flagged, on-hold

  # Escape XML special characters
  name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
  project=$(echo "$project" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  # Determine icon based on status
  local icon="${WORKFLOW_DIR}/icons/active.png"
  if [[ "$status" == "completed" ]]; then
    icon="${WORKFLOW_DIR}/icons/completed.png"
  elif [[ "$status" == "flagged" ]]; then
    icon="${WORKFLOW_DIR}/icons/flagged.png"
  elif [[ "$status" == "on-hold" ]]; then
    icon="${WORKFLOW_DIR}/icons/on-hold.png"
  fi

  cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>$project</subtitle>
    <icon>$icon</icon>
  </item>
EOF
}

# Format XML for a project item
format_project_item() {
  local id="$1"
  local name="$2"
  local folder="$3"
  local status="$4"  # active, on-hold, completed

  # Escape XML special characters
  name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
  folder=$(echo "$folder" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  # Determine icon based on status
  local icon="${WORKFLOW_DIR}/icons/project.png"
  if [[ "$status" == "completed" ]]; then
    icon="${WORKFLOW_DIR}/icons/project-completed.png"
  elif [[ "$status" == "on-hold" ]]; then
    icon="${WORKFLOW_DIR}/icons/project-on-hold.png"
  fi

  cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>$folder</subtitle>
    <icon>$icon</icon>
  </item>
EOF
}

# Format XML for a tag item
format_tag_item() {
  local id="$1"
  local name="$2"
  local count="$3"

  # Escape XML special characters
  name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>Tag ($count tasks)</subtitle>
    <icon>${WORKFLOW_DIR}/icons/tag.png</icon>
  </item>
EOF
}

# Format XML for a folder item
format_folder_item() {
  local id="$1"
  local name="$2"

  # Escape XML special characters
  name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>Folder</subtitle>
    <icon>${WORKFLOW_DIR}/icons/folder.png</icon>
  </item>
EOF
}

# Format XML for a perspective item
format_perspective_item() {
  local id="$1"
  local name="$2"
  local type="$3"

  # Escape XML special characters
  name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
  type=$(echo "$type" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>Perspective ($type)</subtitle>
    <icon>${WORKFLOW_DIR}/icons/perspective.png</icon>
  </item>
EOF
}

# Generate Alfred XML output for results
generate_xml_output() {
  local type="$1"
  local input="$2"

  # Split input on ### delimiter - convert to array
  IFS='###' read -r -a items <<< "$input"

  # Filter out empty items
  local filtered_items=()
  for item in "${items[@]}"; do
    if [[ -n "$item" ]]; then
      filtered_items+=("$item")
    fi
  done

  local count=${#filtered_items[@]}

  echo '<?xml version="1.0"?>'
  echo '<items>'

  if [[ $count -eq 0 ]]; then
    # No results found
    cat << EOF
  <item>
    <title>No results found</title>
    <subtitle>Try a different search term</subtitle>
    <icon>${WORKFLOW_DIR}/icons/error.png</icon>
  </item>
EOF
  else
    # Process each result based on the type
    for item in "${filtered_items[@]}"; do
      IFS='|' read -r id name extra status <<< "$item"

      case "$type" in
        "task")
          format_task_item "$id" "$name" "$extra" "$status"
          ;;
        "project")
          format_project_item "$id" "$name" "$extra" "$status"
          ;;
        "tag")
          format_tag_item "$id" "$name" "$extra"
          ;;
        "folder")
          format_folder_item "$id" "$name"
          ;;
        "perspective")
          format_perspective_item "$id" "$name" "$extra"
          ;;
        *)
          # Generic item format as fallback
          cat << EOF
  <item uid="$id" arg="$id">
    <title>$name</title>
    <subtitle>$extra</subtitle>
    <icon>${WORKFLOW_DIR}/icons/active.png</icon>
  </item>
EOF
          ;;
      esac
    done
  fi

  echo '</items>'
}

# Show a simple message in Alfred XML format
show_message() {
  local title="$1"
  local subtitle="$2"
  local icon="$3"

  if [[ -z "$icon" ]]; then
    icon="${WORKFLOW_DIR}/icons/info.png"
  fi

  # Escape XML special characters
  title=$(echo "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
  subtitle=$(echo "$subtitle" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')

  cat << EOF
<?xml version="1.0"?>
<items>
  <item>
    <title>$title</title>
    <subtitle>$subtitle</subtitle>
    <icon>$icon</icon>
  </item>
</items>
EOF
}