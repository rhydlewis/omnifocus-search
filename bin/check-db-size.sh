sqlite3 ~/Library/Group\ Containers/34YW5XSRB7.com.omnigroup.OmniFocus/com.omnigroup.OmniFocus4/com.omnigroup.OmniFocusModel/OmniFocusDatabase.db "
SELECT
'Tasks (Total)' as metric, COUNT(*) as count FROM Task
UNION ALL
SELECT 'Tasks (Active)', COUNT(*) FROM Task WHERE dateCompleted IS NULL
UNION ALL
SELECT 'Tasks (Completed)', COUNT(*) FROM Task WHERE dateCompleted IS NOT NULL
UNION ALL
SELECT 'Tags', COUNT(*) FROM Context
UNION ALL
SELECT 'Folders', COUNT(*) FROM Folder;"