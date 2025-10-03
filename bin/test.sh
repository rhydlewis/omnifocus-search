#!/bin/bash

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Get query from argument
query="$1"

echo "Testing with query: $query"
echo "WORKFLOW_DIR: $WORKFLOW_DIR"
echo "Script path: ${WORKFLOW_DIR}/applescript/search_tasks.js"

# Run the JXA script directly
/usr/bin/osascript "${WORKFLOW_DIR}/applescript/search_tasks.js" "$query"