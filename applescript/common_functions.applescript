-- Common functions for OmniFocus search scripts

-- Convert a list to a delimited string
on joinList(theList, delimiter)
  set AppleScript's text item delimiters to delimiter
  set theString to theList as string
  set AppleScript's text item delimiters to ""
  return theString
end joinList

-- Safely get a property that might be missing
on safeGet(obj, propertyName, defaultValue)
  try
    tell application "OmniFocus"
      set theValue to obj's propertyName
      if theValue is missing value then
        return defaultValue
      else
        return theValue
      end if
    end tell
  on error
    return defaultValue
  end try
end safeGet

-- Get project name for a task
on getProjectName(theTask)
  tell application "OmniFocus"
    tell default document
      try
        set theProject to containing project of theTask
        if theProject is not missing value then
          return name of theProject
        else
          if theTask is in inbox then
            return "Inbox"
          else
            return "(No Project)"
          end if
        end if
      on error
        if theTask is in inbox then
          return "Inbox"
        else
          return "(No Project)"
        end if
      end try
    end tell
  end tell
end getProjectName

-- Get task status (active, completed, flagged, on-hold)
on getTaskStatus(theTask)
  tell application "OmniFocus"
    if completed of theTask then
      return "completed"
    else if flagged of theTask then
      return "flagged"
    else
      try
        set containingProject to containing project of theTask
        if containingProject is not missing value then
          if status of containingProject is on hold then
            return "on-hold"
          end if
        end if
      end try
      return "active"
    end if
  end tell
end getTaskStatus

-- Get project status (active, completed, on-hold)
on getProjectStatus(theProject)
  tell application "OmniFocus"
    if completed of theProject then
      return "completed"
    else if status of theProject is on hold then
      return "on-hold"
    else
      return "active"
    end if
  end tell
end getProjectStatus

-- Clean string for output (replace delimiters with spaces)
on cleanString(theString)
  if theString is missing value then
    return ""
  end if

  -- Replace item separator with space
  set cleanedStr to my replaceString(theString, "|", " ")
  -- Replace record separator with space
  set cleanedStr to my replaceString(cleanedStr, "•••", " ")

  return cleanedStr
end cleanString

-- Replace all occurrences of a substring
on replaceString(theText, oldString, newString)
  set AppleScript's text item delimiters to oldString
  set theTextItems to text items of theText
  set AppleScript's text item delimiters to newString
  set theText to theTextItems as string
  set AppleScript's text item delimiters to ""
  return theText
end replaceString