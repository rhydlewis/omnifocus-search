-- Search inbox tasks in OmniFocus
-- Parameters:
--   1. query (string): search text

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	-- Search inbox tasks in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get all inbox tasks
				set inboxTasks to inbox tasks

				-- Filter by name/query if provided
				set matchingTasks to {}
				if query is not "" then
					repeat with t in inboxTasks
						if name of t contains query then
							set end of matchingTasks to t
						end if
					end repeat
				else
					set matchingTasks to inboxTasks
				end if

				-- Process results
				set resultList to {}
				repeat with t in matchingTasks
					set taskId to id of t as string
					set taskName to name of t

					-- Determine status
					set taskStatus to "active"
					if flagged of t then
						set taskStatus to "flagged"
					end if

					-- Format as: id|name|Inbox|status
					set taskString to taskId & "|" & taskName & "|Inbox|" & taskStatus
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