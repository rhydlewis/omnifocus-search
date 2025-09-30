-- Search projects in OmniFocus
-- Parameters:
--   1. query (string): search text
--   2. active_only (string): "true" or "false"

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	set activeOnly to true
	if (count of argv) >= 2 then
		set activeOnly to (item 2 of argv is "true")
	end if

	-- Search projects in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get initial set of projects
				set matchingProjects to flattened projects

				-- Filter by name/query if provided
				if query is not "" then
					set filteredProjects to {}
					repeat with p in matchingProjects
						if name of p contains query then
							set end of filteredProjects to p
						end if
					end repeat
					set matchingProjects to filteredProjects
				end if

				-- Filter by active status if needed
				if activeOnly then
					set filteredProjects to {}
					repeat with p in matchingProjects
						if status of p is active and completed of p is false then
							set end of filteredProjects to p
						end if
					end repeat
					set matchingProjects to filteredProjects
				end if

				-- Process results
				set resultList to {}
				repeat with p in matchingProjects
					set projectId to id of p as string
					set projectName to name of p

					-- Get folder name
					set folderName to ""
					try
						set parentFolder to folder of p
						if parentFolder is not missing value then
							set folderName to name of parentFolder
						end if
					end try

					-- Determine status
					set projectStatus to "active"
					if completed of p then
						set projectStatus to "completed"
					else if status of p is on hold then
						set projectStatus to "on-hold"
					end if

					-- Format as: id|name|folder|status
					set projectString to projectId & "|" & projectName & "|" & folderName & "|" & projectStatus
					set end of resultList to projectString
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