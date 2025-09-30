#!/bin/bash

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Get query from argument
query="$1"

# Generate a simple XML output for testing
cat << EOF
<?xml version="1.0"?>
<items>
  <item uid="test-id" arg="test-id">
    <title>Test Item: $query</title>
    <subtitle>Test Project</subtitle>
    <icon>${WORKFLOW_DIR}/icons/active.png</icon>
  </item>
</items>
EOF