#!/usr/bin/osascript -l JavaScript

/**
 * Search inbox tasks in OmniFocus (JXA version - optimized)
 *
 * Parameters:
 *   1. query (string): search text
 *
 * Returns:
 *   Delimited string of tasks in format: id|name|Inbox|status###id|name|Inbox|status...
 *   or empty string if no results
 *   or "ERROR: <message>" on error
 */

function run(argv) {
  const ITEM_DELIMITER = '|';
  const RECORD_DELIMITER = '###';

  // Parse arguments
  const query = argv.length >= 1 ? String(argv[0]) : '';

  try {
    const OmniFocus = Application('OmniFocus');
    OmniFocus.includeStandardAdditions = false;

    if (!OmniFocus.running()) {
      return 'ERROR: OmniFocus is not running';
    }

    const doc = OmniFocus.defaultDocument();

    // Get inbox tasks
    const inboxTasks = doc.inboxTasks();

    // Filter by query if provided
    const matchingTasks = [];
    if (query !== '') {
      for (let i = 0; i < inboxTasks.length; i++) {
        const task = inboxTasks[i];
        const taskName = task.name() || '';
        if (taskName.includes(query)) {
          matchingTasks.push(task);
        }
      }
    } else {
      for (let i = 0; i < inboxTasks.length; i++) {
        matchingTasks.push(inboxTasks[i]);
      }
    }

    // Process results
    const resultList = [];

    for (let i = 0; i < matchingTasks.length; i++) {
      const task = matchingTasks[i];
      const taskId = task.id();
      const taskName = task.name() || '';

      // Determine status
      let taskStatus = 'active';
      try {
        if (task.flagged()) {
          taskStatus = 'flagged';
        }
      } catch (e) {
        // Keep default status
      }

      // Format as: id|name|Inbox|status
      const taskString = taskId + ITEM_DELIMITER + taskName + ITEM_DELIMITER + 'Inbox' + ITEM_DELIMITER + taskStatus;
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
