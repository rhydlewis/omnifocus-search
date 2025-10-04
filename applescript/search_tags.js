#!/usr/bin/osascript -l JavaScript

/**
 * Search tags in OmniFocus (JXA version)
 *
 * Parameters:
 *   1. query (string): search text for tag names
 *
 * Returns:
 *   Delimited string of tags in format: id|name|taskCount###id|name|taskCount...
 *   or empty string if no results
 *   or "ERROR: <message>" on error
 */

function run(argv) {
  const MAX_RESULTS = 100;
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

    // Get all flattened tags
    const allTags = doc.flattenedTags();

    // Filter tags by query if provided
    let matchingTags = [];
    if (query !== '') {
      const lowerQuery = query.toLowerCase();
      for (let i = 0; i < allTags.length; i++) {
        const tag = allTags[i];
        const tagName = tag.name();
        if (tagName && tagName.toLowerCase().indexOf(lowerQuery) !== -1) {
          matchingTags.push(tag);
        }
      }
    } else {
      matchingTags = allTags;
    }

    // Limit results to prevent UI freezing
    if (matchingTags.length > MAX_RESULTS) {
      matchingTags = matchingTags.slice(0, MAX_RESULTS);
    }

    // Process results - get task count directly from each matched tag
    // This is much more efficient than iterating through all tasks
    const resultList = [];

    for (let i = 0; i < matchingTags.length; i++) {
      const tag = matchingTags[i];
      const tagId = tag.id();
      const tagName = tag.name() || '';

      // Get incomplete tasks for this specific tag only
      const tagTasks = tag.tasks.whose({ completed: false })();
      const taskCount = tagTasks.length;

      // Format as: id|name|taskCount
      const tagString = tagId + ITEM_DELIMITER + tagName + ITEM_DELIMITER + taskCount;
      resultList.push(tagString);
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
