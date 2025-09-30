-- Get perspectives from OmniFocus
-- Parameters:
--   1. query (string): search text

on run argv
	-- Parse arguments
	if (count of argv) ≥ 1 then
		set query to item 1 of argv
	else
		set query to ""
	end if

	-- Get perspectives from OmniFocus
	tell application "OmniFocus"
		try
			-- Simply use the manual approach which is more reliable
			set resultList to {}

			-- Handle built-in perspectives - specify each one by name and ID
			set builtInPerspectives to {{"Inbox", "Inbox"}, {"Projects", "Projects"}, {"Tags", "Tags"}, {"Forecast", "Forecast"}, {"Flagged", "Flagged"}, {"Review", "Review"}}

			-- Process built-in perspectives
			repeat with pItem in builtInPerspectives
				set perspectiveName to item 1 of pItem
				set perspectiveId to item 2 of pItem

				-- Only include if it matches the query
				if query is "" or perspectiveName contains query then
					set perspectiveType to "Built-in"
					set perspectiveString to perspectiveId & "|" & perspectiveName & "|" & perspectiveType
					set end of resultList to perspectiveString
				end if
			end repeat

			-- Get custom perspectives by trying to get all perspectives
			-- Then manually filter out the built-in ones
			try
				-- Get all perspectives
				set allPerspectives to every perspective

				-- Find the custom ones
				repeat with p in allPerspectives
					try
						-- Try to get the perspective name
						set perspectiveName to ""
						try
							set perspectiveName to name of p
						end try

						-- If we couldn't get a name, use a property from the perspective instead
						if perspectiveName is "" or perspectiveName is missing value then
							try
								set perspectiveName to id of p as string
								if perspectiveName does not start with "OmniFocus" then
									set perspectiveName to "Custom Perspective " & perspectiveName
								else
									set perspectiveName to "Custom Perspective"
								end if
							end try
						end if

						-- Skip built-in perspectives
						set isBuiltIn to false
						repeat with builtInItem in builtInPerspectives
							if perspectiveName is equal to item 2 of builtInItem then
								set isBuiltIn to true
								exit repeat
							end if
						end repeat

						-- Add if not built-in, has a valid name, and matches query
						if perspectiveName is not "" and perspectiveName is not missing value and not isBuiltIn and (query is "" or perspectiveName contains query) then
							set perspectiveId to perspectiveName
							set perspectiveType to "Custom"

							set perspectiveString to perspectiveId & "|" & perspectiveName & "|" & perspectiveType
							set end of resultList to perspectiveString
						end if
					on error
						-- Skip any perspective that causes an error
					end try
				end repeat
			on error
				-- Just continue with the built-in perspectives if this fails
			end try

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
end run