-- Search tasks in OmniFocus (optimized for completed tasks)
-- Parameters:
--   1. query (string): search text
--   2. completed (string): "true" or "false"
--   3. flagged (string): "true" or "false"
--   4. active_only (string): "true" or "false"
--   5. days_limit (string, optional): number of days to look back for completed tasks

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	set isCompleted to false
	if (count of argv) >= 2 then
		set isCompleted to (item 2 of argv is "true")
	end if

	set isFlagged to false
	if (count of argv) >= 3 then
		set isFlagged to (item 3 of argv is "true")
	end if

	set activeOnly to true
	if (count of argv) >= 4 then
		set activeOnly to (item 4 of argv is "true")
	end if

	-- New parameter: days to limit completed tasks search
	set daysLimit to 30 -- Default to 30 days
	if (count of argv) >= 5 then
		try
			set daysLimit to item 5 of argv as number
		on error
			-- Keep default if not a valid number
		end try
	end if

	-- Search tasks in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				set matchingTasks to {}

				-- Get tasks using optimized approach based on completion status
				if isCompleted then
					-- For completed tasks, limit by date and use more targeted filtering
					set dateLimit to (current date) - (daysLimit * days)

					-- Use more targeted initial query when possible
					if query is not "" then
						-- If we have a search term, include it in the initial database query
						set matchingTasks to (flattened tasks where completed is true and completion date ≥ dateLimit and name contains query)
					else
						-- If no search term, just filter by date
						set matchingTasks to (flattened tasks where completed is true and completion date ≥ dateLimit)
					end if

					-- Apply flagged filter if needed (OmniFocus doesn't support this in the initial query for completed tasks)
					if isFlagged then
						set filteredTasks to {}
						repeat with t in matchingTasks
							if flagged of t is true then
								set end of filteredTasks to t
							end if
						end repeat
						set matchingTasks to filteredTasks
					end if
				else
					-- For incomplete tasks, we can often use more targeted queries
					if query is not "" and isFlagged then
						-- Both query and flagged status specified
						set matchingTasks to (flattened tasks where completed is false and flagged is true and name contains query)
					else if isFlagged then
						-- Just flagged status specified
						set matchingTasks to (flattened tasks where completed is false and flagged is true)
					else if query is not "" then
						-- Just query specified
						set matchingTasks to (flattened tasks where completed is false and name contains query)
					else
						-- No filters
						set matchingTasks to (flattened tasks where completed is false)
					end if
				end if

				-- Process results
				set resultList to {}

				-- Limit results to 100 items to prevent excessive processing
				set maxResults to 100
				set counter to 0

				repeat with t in matchingTasks
					set counter to counter + 1
					if counter > maxResults then exit repeat

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