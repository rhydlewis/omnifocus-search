-- Search tags in OmniFocus
-- Parameters:
--   1. query (string): search text

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if
	
	-- Search tags in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get all tags
				set allTags to flattened tags
				
				-- Filter by name/query if provided
				set matchingTags to {}
				if query is not "" then
					repeat with t in allTags
						if name of t contains query then
							set end of matchingTags to t
						end if
					end repeat
				else
					set matchingTags to allTags
				end if
				
				-- Build task count map in a single pass through all tasks
				set incompleteTasks to (flattened tasks where completed is false)
				set tagCountMap to {}

				repeat with tsk in incompleteTasks
					set taskTags to tags of tsk
					repeat with taskTag in taskTags
						set tagIdStr to id of taskTag as string

						-- Find or create entry in count map
						set foundIndex to 0
						repeat with i from 1 to count of tagCountMap
							if item 1 of item i of tagCountMap is tagIdStr then
								set foundIndex to i
								exit repeat
							end if
						end repeat

						if foundIndex > 0 then
							-- Increment existing count
							set item 2 of item foundIndex of tagCountMap to (item 2 of item foundIndex of tagCountMap) + 1
						else
							-- Add new entry
							set end of tagCountMap to {tagIdStr, 1}
						end if
					end repeat
				end repeat

				-- Process results using the count map
				set resultList to {}
				repeat with t in matchingTags
					set tagId to id of t as string
					set tagName to name of t

					-- Look up count from map
					set taskCount to 0
					repeat with mapEntry in tagCountMap
						if item 1 of mapEntry is tagId then
							set taskCount to item 2 of mapEntry
							exit repeat
						end if
					end repeat

					-- Format as: id|name|taskCount
					set tagString to tagId & "|" & tagName & "|" & taskCount
					set end of resultList to tagString
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