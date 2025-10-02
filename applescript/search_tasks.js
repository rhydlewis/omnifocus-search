#!/usr/bin/osascript -l JavaScript

/**
 * Search tasks in OmniFocus (JXA version - optimized for completed tasks)
 *
 * Parameters:
 *   1. query (string): search text for task names
 *   2. completed (string): "true" or "false"
 *   3. flagged (string): "true" or "false"
 *   4. active_only (string): "true" or "false" (currently not used but maintained for compatibility)
 *   5. days_limit (string, optional): number of days to look back for completed tasks (default: 30)
 *
 * Returns:
 *   Delimited string of tasks in format: id|name|project|status###id|name|project|status...
 *   or empty string if no results
 *   or "ERROR: <message>" on error
 */

function run(argv) {
  const MAX_RESULTS = 100;
  const ITEM_DELIMITER = '|';
  const RECORD_DELIMITER = '###';
  const DEFAULT_DAYS_LIMIT = 30;

  // Parse arguments
  const query = argv.length >= 1 ? String(argv[0]) : '';
  const isCompleted = argv.length >= 2 ? (String(argv[1]) === 'true') : false;
  const isFlagged = argv.length >= 3 ? (String(argv[2]) === 'true') : false;
  const activeOnly = argv.length >= 4 ? (String(argv[3]) === 'true') : true;

  let daysLimit = DEFAULT_DAYS_LIMIT;
  if (argv.length >= 5) {
    try {
      const parsed = parseInt(String(argv[4]), 10);
      if (!isNaN(parsed)) {
        daysLimit = parsed;
      }
    } catch (e) {
      // Keep default if parsing fails
    }
  }

  try {
    const OmniFocus = Application('OmniFocus');
    OmniFocus.includeStandardAdditions = false;

    if (!OmniFocus.running()) {
      return 'ERROR: OmniFocus is not running';
    }

    const doc = OmniFocus.defaultDocument();
    let matchingTasks = [];

    // Optimized query based on completion status
    if (isCompleted) {
      // For completed tasks, limit by date for performance
      const now = new Date();
      const dateLimit = new Date(now.getTime() - (daysLimit * 24 * 60 * 60 * 1000));

      // Build the query criteria
      const criteria = {
        completed: true,
        completionDate: {
          _greaterThanEquals: dateLimit
        }
      };

      // If query is provided, add it to initial filter for better performance
      if (query !== '') {
        criteria.name = {
          _contains: query
        };
      }

      matchingTasks = doc.flattenedTasks.whose(criteria)();

      // Apply flagged filter if needed (post-filter since OmniFocus query language limitations)
      if (isFlagged) {
        const filteredTasks = [];
        for (let i = 0; i < matchingTasks.length; i++) {
          if (matchingTasks[i].flagged()) {
            filteredTasks.push(matchingTasks[i]);
          }
        }
        matchingTasks = filteredTasks;
      }

    } else {
      // For incomplete tasks, use more targeted queries
      const criteria = { completed: false };

      // Add query filter if provided
      if (query !== '') {
        criteria.name = { _contains: query };
      }

      // Add flagged filter if specified
      if (isFlagged) {
        criteria.flagged = true;
      }

      matchingTasks = doc.flattenedTasks.whose(criteria)();
    }

    // Process results with limit, filtering out items that are actually projects
    const resultList = [];
    let processedCount = 0;

    for (let i = 0; i < matchingTasks.length && resultList.length < MAX_RESULTS; i++) {
      const task = matchingTasks[i];
      const taskId = task.id();
      const taskName = task.name() || '';

      // Filter out projects: if task.id === containingProject.id, this is a project, not a task
      let isProject = false;
      try {
        const project = task.containingProject();
        if (project && project.id() === taskId) {
          isProject = true;
        }
      } catch (e) {
        // If we can't check, assume it's not a project
      }

      // Skip projects
      if (isProject) {
        continue;
      }

      // Get project name
      let projectName = 'Unknown';
      try {
        const project = task.containingProject();
        if (project && project.name) {
          projectName = project.name();
        } else {
          // Check if in inbox
          const inboxTasks = doc.inboxTasks();
          let isInInbox = false;
          for (let j = 0; j < inboxTasks.length; j++) {
            if (inboxTasks[j].id() === taskId) {
              isInInbox = true;
              break;
            }
          }
          projectName = isInInbox ? 'Inbox' : '(No Project)';
        }
      } catch (e) {
        // Check if in inbox as fallback
        try {
          const inboxTasks = doc.inboxTasks();
          let isInInbox = false;
          for (let j = 0; j < inboxTasks.length; j++) {
            if (inboxTasks[j].id() === taskId) {
              isInInbox = true;
              break;
            }
          }
          projectName = isInInbox ? 'Inbox' : '(No Project)';
        } catch (err) {
          projectName = '(No Project)';
        }
      }

      // Determine status
      let taskStatus = 'active';
      if (task.completed()) {
        taskStatus = 'completed';
      } else if (task.flagged()) {
        taskStatus = 'flagged';
      }

      // Format as: id|name|project|status
      const taskString = taskId + ITEM_DELIMITER + taskName + ITEM_DELIMITER + projectName + ITEM_DELIMITER + taskStatus;
      resultList.push(taskString);
    }

    // Return results
    if (resultList.length > 0) {
      return resultList.join(RECORD_DELIMITER);
    } else {
      return '';
    }

  } catch (error) {
    return 'ERROR: ' + error.message;
  }
}
