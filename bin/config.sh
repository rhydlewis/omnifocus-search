#!/bin/bash

# Path to the workflow directory
WORKFLOW_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

# Source the format_xml script for showing messages
source "${WORKFLOW_DIR}/bin/format_xml.sh"

# Workflow bundle ID - will be used to store/retrieve Alfred variables
WORKFLOW_BUNDLE_ID="com.search.omnifocus"

# Get workflow environment variable
get_workflow_var() {
  local var_name="$1"
  local default_value="$2"

  # Try to get the value from Alfred's workflow environment variable
  local value=$(/usr/bin/osascript -l JavaScript -e "
    ObjC.import('stdlib');
    ObjC.import('Foundation');
    var pref_file_path = $.getenv('HOME') + '/Library/Application Support/Alfred/prefs.json';
    var fm = $.NSFileManager.defaultManager;

    // Check if file exists
    if (fm.fileExistsAtPath(pref_file_path)) {
      var pref_data = fm.contentsAtPath(pref_file_path);
      if (pref_data) {
        var pref_str = $.NSString.alloc.initWithDataEncoding(pref_data, $.NSUTF8StringEncoding);
        var prefs = JSON.parse(pref_str.js);

        // Find current Alfred version directory
        var alfred_version_dir = '';
        for (var key in prefs.current) {
          alfred_version_dir = prefs.current[key];
          break;
        }

        if (alfred_version_dir) {
          var workflow_prefs_path = $.getenv('HOME') + '/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/user.workflow.' + alfred_version_dir + '/prefs.plist';

          if (fm.fileExistsAtPath(workflow_prefs_path)) {
            var dict = $.NSDictionary.dictionaryWithContentsOfFile(workflow_prefs_path);
            if (dict && dict.objectForKey('$var_name')) {
              dict.objectForKey('$var_name').js;
            } else {
              '';
            }
          } else {
            '';
          }
        } else {
          '';
        }
      } else {
        '';
      }
    } else {
      '';
    }
  ")

  # Return the value or the default if not found
  if [[ -z "$value" ]]; then
    echo "$default_value"
  else
    echo "$value"
  fi
}

# Set workflow environment variable
set_workflow_var() {
  local var_name="$1"
  local value="$2"

  # Use AppleScript to set Alfred workflow environment variable
  /usr/bin/osascript -l JavaScript -e "
    ObjC.import('stdlib');
    ObjC.import('Foundation');
    var pref_file_path = $.getenv('HOME') + '/Library/Application Support/Alfred/prefs.json';
    var fm = $.NSFileManager.defaultManager;

    // Check if file exists
    if (fm.fileExistsAtPath(pref_file_path)) {
      var pref_data = fm.contentsAtPath(pref_file_path);
      if (pref_data) {
        var pref_str = $.NSString.alloc.initWithDataEncoding(pref_data, $.NSUTF8StringEncoding);
        var prefs = JSON.parse(pref_str.js);

        // Find current Alfred version directory
        var alfred_version_dir = '';
        for (var key in prefs.current) {
          alfred_version_dir = prefs.current[key];
          break;
        }

        if (alfred_version_dir) {
          var workflow_prefs_path = $.getenv('HOME') + '/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/user.workflow.' + alfred_version_dir + '/prefs.plist';

          var dict;
          if (fm.fileExistsAtPath(workflow_prefs_path)) {
            dict = $.NSMutableDictionary.dictionaryWithContentsOfFile(workflow_prefs_path);
          } else {
            dict = $.NSMutableDictionary.alloc.init;
          }

          dict.setObject_forKey('$value', '$var_name');
          dict.writeToFile_atomically(workflow_prefs_path, true);
        }
      }
    }
  "

  # Check if the operation was successful
  if [[ $? -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# Auto-detect OmniFocus database path
find_omnifocus_database() {
  # Try to find the OmniFocus database in the default location
  local db_path=""

  # Check OmniFocus 4 database location first
  local of4_path="$HOME/Library/Containers/com.omnigroup.OmniFocus4/Data/Library/Application Support/OmniFocus/OmniFocus.sqlite"
  if [[ -f "$of4_path" ]]; then
    db_path="$of4_path"
  else
    # Check OmniFocus 3 database location
    local of3_path="$HOME/Library/Containers/com.omnigroup.OmniFocus3/Data/Library/Caches/com.omnigroup.OmniFocus3/OmniFocusDatabase2"
    if [[ -d "$of3_path" ]]; then
      db_path="$of3_path"
    fi
  fi

  # Set the database path in Alfred workflow variables if found
  if [[ -n "$db_path" ]]; then
    if set_workflow_var "OF_DATABASE_PATH" "$db_path"; then
      show_message "OmniFocus Database Found" "Path: $db_path" "${WORKFLOW_DIR}/icons/success.png"
    else
      show_message "Error Setting Database Path" "Could not save the path to Alfred workflow variables" "${WORKFLOW_DIR}/icons/error.png"
    fi
  else
    show_message "OmniFocus Database Not Found" "Please set the database path manually with 'of set-db-path [path]'" "${WORKFLOW_DIR}/icons/error.png"
  fi
}

# Set OmniFocus database path manually
set_omnifocus_database_path() {
  local path="$1"

  # Validate the path exists
  if [[ ! -e "$path" ]]; then
    show_message "Invalid Path" "The specified path does not exist: $path" "${WORKFLOW_DIR}/icons/error.png"
    return 1
  fi

  # Set the path in Alfred workflow variables
  if set_workflow_var "OF_DATABASE_PATH" "$path"; then
    show_message "Database Path Set" "Path: $path" "${WORKFLOW_DIR}/icons/success.png"
    return 0
  else
    show_message "Error Setting Database Path" "Could not save the path to Alfred workflow variables" "${WORKFLOW_DIR}/icons/error.png"
    return 1
  fi
}

# Get the OmniFocus database path
get_omnifocus_database_path() {
  local default_path="$HOME/Library/Containers/com.omnigroup.OmniFocus4/Data/Library/Application Support/OmniFocus/OmniFocus.sqlite"
  get_workflow_var "OF_DATABASE_PATH" "$default_path"
}