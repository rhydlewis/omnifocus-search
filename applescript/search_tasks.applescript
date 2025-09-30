-- Search tasks in OmniFocus
-- Parameters:
--   1. query (string): search text
--   2. completed (string): "true" or "false"
--   3. flagged (string): "true" or "false"
--   4. active_only (string): "true" or "false"

on run argv
	-- Parse arguments
	if (count of argv) ³ 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if
	
	set isCompleted to false
	if (count of argv) ³ 2 then
		set isCompleted to (item 2 of argv is "true")
	end if
	
	set isFlagged to false
	if (count of argv) ³ 3 then
		set isFlagged to (item 3 of argv is "true")
	end if
	
	set activeOnly to true
	if (count of argv) ³ 4 then
		set activeOnly to (item 4 of argv is "true")
	end if
	
	-- Search tasks in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get initial set of tasks based on completion status
				if isCompleted then
					set matchingTasks to (flattened tasks where completed is true)
				else
					set matchingTasks to (flattened tasks where completed is false)
				end if
				
				-- Filter by name/query if provided
				if query is not "" then
					set filteredTasks to {}
					repeat with t in matchingTasks
						if name of t contains query then
							set end of filteredTasks to t
						end if
					end repeat
					set matchingTasks to filteredTasks
				end if
				
				-- Filter by flagged status if needed
				if isFlagged then
					set filteredTasks to {}
					repeat with t in matchingTasks
						if flagged of t is true then
							set end of filteredTasks to t
						end if
					end repeat
					set matchingTasks to filteredTasks
				end if
				
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
					
					-- Determine status
					set taskStatus to "active"
					if completed of t then
						set taskStatus to "completed"
					else if flagged of t then
						set taskStatus to "flagged"
					end if
					
					-- Format as: id|name|project|status
					set taskString to taskId & "|" & taskName & "|" & projectName & "|" & taskStatus
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