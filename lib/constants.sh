#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Alfred workflow information
WORKFLOW_NAME="Search OmniFocus"
WORKFLOW_VERSION="2.0.0"
WORKFLOW_BUNDLE_ID="com.search.omnifocus"
WORKFLOW_CREATOR="Workflow Converter"

# Command prefixes
CMD_SEARCH_TASKS="s"
CMD_SEARCH_COMPLETED="sc"
CMD_SEARCH_PROJECTS="p"
CMD_SEARCH_INBOX="i"
CMD_SEARCH_TAGS="t"
CMD_SEARCH_FOLDERS="f"
CMD_SEARCH_PERSPECTIVES="v"
CMD_SEARCH_NOTES="n"
CMD_FIND_DATABASE="find-of-db"
CMD_SET_DATABASE="set-of-db"

# Status constants
STATUS_ACTIVE="active"
STATUS_COMPLETED="completed"
STATUS_FLAGGED="flagged"
STATUS_ON_HOLD="on-hold"

# Icon paths
ICON_ACTIVE="${WORKFLOW_DIR}/icons/active.png"
ICON_COMPLETED="${WORKFLOW_DIR}/icons/completed.png"
ICON_FLAGGED="${WORKFLOW_DIR}/icons/flagged.png"
ICON_ON_HOLD="${WORKFLOW_DIR}/icons/on-hold.png"
ICON_PROJECT="${WORKFLOW_DIR}/icons/project.png"
ICON_PROJECT_COMPLETED="${WORKFLOW_DIR}/icons/project-completed.png"
ICON_PROJECT_ON_HOLD="${WORKFLOW_DIR}/icons/project-on-hold.png"
ICON_TAG="${WORKFLOW_DIR}/icons/tag.png"
ICON_FOLDER="${WORKFLOW_DIR}/icons/folder.png"
ICON_PERSPECTIVE="${WORKFLOW_DIR}/icons/perspective.png"
ICON_ERROR="${WORKFLOW_DIR}/icons/error.png"
ICON_INFO="${WORKFLOW_DIR}/icons/info.png"
ICON_SUCCESS="${WORKFLOW_DIR}/icons/success.png"

# Default values
DEFAULT_OF4_DATABASE_PATH="$HOME/Library/Containers/com.omnigroup.OmniFocus4/Data/Library/Application Support/OmniFocus/OmniFocus.sqlite"
DEFAULT_OF3_DATABASE_PATH="$HOME/Library/Containers/com.omnigroup.OmniFocus3/Data/Library/Caches/com.omnigroup.OmniFocus3/OmniFocusDatabase2"

# AppleScript common result delimiters
ITEM_SEPARATOR="|"  # Separates properties of a single item
RECORD_SEPARATOR="•••" # Separates multiple items in a result list