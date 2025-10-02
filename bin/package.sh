#!/bin/bash

# Package script for creating the Alfred workflow file
# Usage: ./bin/package.sh

# Get the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
cd "$WORKFLOW_DIR"

# Set the output filename
OUTPUT_FILE="omnifocus-search.alfredworkflow"

# Make scripts executable
echo "Making scripts executable..."
chmod +x bin/*.sh

# Create the zip file
echo "Creating Alfred workflow package..."
zip -r "$OUTPUT_FILE" \
    applescript/*.js \
    bin/config.sh \
    bin/error_handler.sh \
    bin/format_xml.sh \
    bin/main.sh \
    bin/cache_manager.sh \
    bin/cache_commands.sh \
    bin/progress_handler.sh \
    bin/update_checker.sh \
    bin/update_installer.sh \
    icons/*.png \
    lib/constants.sh \
    lib/omnifocus_jxa_common.js \
    help.html \
    icon.png \
    info.plist \
    README.md

# Check if the package was created successfully
if [ $? -eq 0 ]; then
    echo "Alfred workflow package created successfully: $OUTPUT_FILE"
    echo "You can now import this file into Alfred."
else
    echo "Error creating the workflow package."
    exit 1
fi

echo "Done!"
