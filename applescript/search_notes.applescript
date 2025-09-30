-- Search for tasks with matching notes in OmniFocus
-- Parameters:
--   1. query (string): search text

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	-- Search notes in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get all active tasks
				set allTasks to (flattened tasks where completed is false)

				-- Filter by note content
				set matchingTasks to {}
				repeat with t in allTasks
					set taskNote to note of t
					if taskNote contains query then
						set end of matchingTasks to t
					end if
				end repeat

				-- Process results
				set resultList to {}
				repeat with t in matchingTasks
					set taskId to id of t as string
					set taskName to name of t

					-- Get project name
					set projectName to "Unknown"
					try
						set proj to containing project of t
						if proj is not missing value then
							set projectName to name of proj
						else
							if t is in inbox then
								set projectName to "Inbox"
							else
								set projectName to "(No Project)"
							end if
						end if
					on error
						if t is in inbox then
							set projectName to "Inbox"
						else
							set projectName to "(No Project)"
						end if
					end try

					-- Get note excerpt
					set taskNote to note of t
					if length of taskNote > 50 then
						set noteExcerpt to text 1 thru 50 of taskNote & "..."
					else
						set noteExcerpt to taskNote
					end if

					-- Determine status
					set taskStatus to "active"
					if flagged of t then
						set taskStatus to "flagged"
					end if

					-- Format as: id|name|project|status|note
					set taskString to taskId & "|" & taskName & "|" & projectName & "|" & taskStatus & "|" & noteExcerpt
					set end of resultList to taskString
				end repeat

				-- Join results with record separator and return
				if (count of resultList) > 0 then
					set AppleScript's text item delimiters to "###"
					set resultText to resultList as string
					set AppleScript's text item delimiters to ""
					return resultText
				else
					return ""
				end if
			on error errMsg
				return "ERROR: " & errMsg
			end try
		end tell
	end tell
end run