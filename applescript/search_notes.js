#!/usr/bin/osascript -l JavaScript

/**
 * Search for tasks with matching notes in OmniFocus (JXA version - optimized)
 *
 * Parameters:
 *   1. query (string): search text
 *
 * Returns:
 *   Delimited string of tasks in format: id|name|project|status|note###id|name|project|status|note...
 *   or empty string if no results
 *   or "ERROR: <message>" on error
 */

function run(argv) {
  const ITEM_DELIMITER = '|';
  const RECORD_DELIMITER = '###';
  const MAX_NOTE_LENGTH = 50;

  // Parse arguments
  const query = argv.length >= 1 ? String(argv[0]) : '';

  if (query === '') {
    return '';
  }

  try {
    const OmniFocus = Application('OmniFocus');
    OmniFocus.includeStandardAdditions = false;

    if (!OmniFocus.running()) {
      return 'ERROR: OmniFocus is not running';
    }

    const doc = OmniFocus.defaultDocument();

    // Get all active tasks
    const allTasks = doc.flattenedTasks.whose({ completed: false })();

    // Filter by note content (must be done after retrieval in JXA)
    const matchingTasks = [];
    for (let i = 0; i < allTasks.length; i++) {
      const task = allTasks[i];
      try {
        const taskNote = task.note() || '';
        if (taskNote.includes(query)) {
          matchingTasks.push(task);
        }
      } catch (e) {
        // Skip tasks where note can't be read
      }
    }

    // Get inbox tasks for reference
    const inboxTasks = doc.inboxTasks();
    const inboxTaskIds = new Set();
    for (let i = 0; i < inboxTasks.length; i++) {
      inboxTaskIds.add(inboxTasks[i].id());
    }

    // Process results
    const resultList = [];

    for (let i = 0; i < matchingTasks.length; i++) {
      const task = matchingTasks[i];
      const taskId = task.id();
      const taskName = task.name() || '';

      // Get project name
      let projectName = 'Unknown';
      try {
        const project = task.containingProject();
        if (project && project.name) {
          projectName = project.name();
        } else {
          projectName = inboxTaskIds.has(taskId) ? 'Inbox' : '(No Project)';
        }
      } catch (e) {
        projectName = inboxTaskIds.has(taskId) ? 'Inbox' : '(No Project)';
      }

      // Get note excerpt
      let noteExcerpt = '';
      try {
        const taskNote = task.note() || '';
        if (taskNote.length > MAX_NOTE_LENGTH) {
          noteExcerpt = taskNote.substring(0, MAX_NOTE_LENGTH) + '...';
        } else {
          noteExcerpt = taskNote;
        }
      } catch (e) {
        noteExcerpt = '';
      }

      // Determine status
      let taskStatus = 'active';
      try {
        if (task.flagged()) {
          taskStatus = 'flagged';
        }
      } catch (e) {
        // Keep default status
      }

      // Format as: id|name|project|status|note
      const taskString = taskId + ITEM_DELIMITER + taskName + ITEM_DELIMITER + projectName + ITEM_DELIMITER + taskStatus + ITEM_DELIMITER + noteExcerpt;
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
