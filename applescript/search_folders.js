#!/usr/bin/osascript -l JavaScript

/**
 * Search folders in OmniFocus (JXA version - optimized)
 *
 * Parameters:
 *   1. query (string): search text
 *
 * Returns:
 *   Delimited string of folders in format: id|name|projectCount###id|name|projectCount...
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

    // Get matching folders
    let matchingFolders;
    if (query !== '') {
      matchingFolders = doc.flattenedFolders.whose({ name: { _contains: query } })();
    } else {
      matchingFolders = doc.flattenedFolders();
    }

    // Build project count map efficiently
    const allProjects = doc.flattenedProjects();
    const folderCountMap = new Map();

    for (let i = 0; i < allProjects.length; i++) {
      try {
        const project = allProjects[i];
        const projFolder = project.folder();
        if (projFolder && projFolder.id) {
          const folderId = projFolder.id();
          const count = folderCountMap.get(folderId) || 0;
          folderCountMap.set(folderId, count + 1);
        }
      } catch (e) {
        // Skip projects without folders
      }
    }

    // Process results
    const resultList = [];

    for (let i = 0; i < matchingFolders.length; i++) {
      const folder = matchingFolders[i];
      const folderId = folder.id();
      const folderName = folder.name() || '';

      // Get project count from map
      const projectCount = folderCountMap.get(folderId) || 0;

      // Format as: id|name|projectCount
      const folderString = folderId + ITEM_DELIMITER + folderName + ITEM_DELIMITER + projectCount;
      resultList.push(folderString);
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
