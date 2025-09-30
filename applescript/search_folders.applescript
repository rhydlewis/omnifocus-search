-- Search folders in OmniFocus
-- Parameters:
--   1. query (string): search text

on run argv
	-- Parse arguments
	if (count of argv) >= 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	-- Search folders in OmniFocus
	tell application "OmniFocus"
		tell default document
			try
				-- Get all folders
				set allFolders to flattened folders

				-- Filter by name/query if provided
				set matchingFolders to {}
				if query is not "" then
					repeat with f in allFolders
						if name of f contains query then
							set end of matchingFolders to f
						end if
					end repeat
				else
					set matchingFolders to allFolders
				end if

				-- Build project count map in a single pass through all projects
				set allProjects to flattened projects
				set folderCountMap to {}

				repeat with proj in allProjects
					try
						set projFolder to folder of proj
						if projFolder is not missing value then
							set folderIdStr to id of projFolder as string

							-- Find or create entry in count map
							set foundIndex to 0
							repeat with i from 1 to count of folderCountMap
								if item 1 of item i of folderCountMap is folderIdStr then
									set foundIndex to i
									exit repeat
								end if
							end repeat

							if foundIndex > 0 then
								-- Increment existing count
								set item 2 of item foundIndex of folderCountMap to (item 2 of item foundIndex of folderCountMap) + 1
							else
								-- Add new entry
								set end of folderCountMap to {folderIdStr, 1}
							end if
						end if
					end try
				end repeat

				-- Process results using the count map
				set resultList to {}
				repeat with f in matchingFolders
					set folderId to id of f as string
					set folderName to name of f

					-- Look up count from map
					set projectCount to 0
					repeat with mapEntry in folderCountMap
						if item 1 of mapEntry is folderId then
							set projectCount to item 2 of mapEntry
							exit repeat
						end if
					end repeat

					-- Format as: id|name|projectCount
					set folderString to folderId & "|" & folderName & "|" & projectCount
					set end of resultList to folderString
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