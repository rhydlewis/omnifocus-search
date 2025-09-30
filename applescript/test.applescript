-- Test AppleScript
-- This is a simple test script that doesn't require OmniFocus

on run argv
    -- Get the arguments
    if (count of argv) >= 1 then
        set query to item 1 of argv
    else
        set query to ""
    end if

    -- Create a simple test result
    set testResult to "TEST|Test Item: " & query & "|Test Project|active"

    return testResult
end run