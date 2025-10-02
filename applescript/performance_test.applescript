-- Performance test for searching completed tasks in OmniFocus
-- This script tests different approaches for performance comparison

on run
	-- Track time
	set startTime to current date

	-- Test original approach - get all completed tasks first
	tell application "OmniFocus"
		tell default document
			-- Get all completed tasks (potentially slow with large databases)
			set allCompleted to (flattened tasks where completed is true)

			-- Log the count
			set completedCount to count of allCompleted
			set endTime to current date
			set elapsedTime to endTime - startTime
			log "Found " & completedCount & " completed tasks in " & elapsedTime & " seconds"

			-- Test optimization 1: Get only recent completed tasks (last 30 days)
			set startTime to current date
			set thirtyDaysAgo to (current date) - (30 * days)
			set recentCompleted to (flattened tasks where completed is true and completion date ≥ thirtyDaysAgo)
			set recentCount to count of recentCompleted
			set endTime to current date
			set elapsedTime to endTime - startTime
			log "Found " & recentCount & " completed tasks from last 30 days in " & elapsedTime & " seconds"

			-- Test optimization 2: Limit to first 100 completed tasks
			set startTime to current date
			set limitedCompleted to {}
			set counter to 0
			repeat with t in (flattened tasks where completed is true)
				set end of limitedCompleted to t
				set counter to counter + 1
				if counter ≥ 100 then exit repeat
			end repeat
			set endTime to current date
			set elapsedTime to endTime - startTime
			log "Retrieved first 100 completed tasks in " & elapsedTime & " seconds"

			-- Test optimization 3: Get completed tasks with query directly in OmniFocus filter
			set startTime to current date
			set searchText to "test" -- Example search term
			set filteredCompleted to (flattened tasks where completed is true and name contains searchText)
			set filteredCount to count of filteredCompleted
			set endTime to current date
			set elapsedTime to endTime - startTime
			log "Found " & filteredCount & " completed tasks with '" & searchText & "' in name in " & elapsedTime & " seconds"

			return "Performance test completed. See log for results."
		end tell
	end tell
end run