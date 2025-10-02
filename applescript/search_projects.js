#!/usr/bin/osascript -l JavaScript

/**
 * Search projects in OmniFocus (JXA version - optimized)
 *
 * Parameters:
 *   1. query (string): search text
 *   2. active_only (string): "true" or "false"
 *
 * Returns:
 *   Delimited string of projects in format: id|name|folder|status###id|name|folder|status...
 *   or empty string if no results
 *   or "ERROR: <message>" on error
 */

function run(argv) {
  const ITEM_DELIMITER = '|';
  const RECORD_DELIMITER = '###';

  // Parse arguments
  const query = argv.length >= 1 ? String(argv[0]) : '';
  const activeOnly = argv.length >= 2 ? (String(argv[1]) === 'true') : true;

  try {
    const OmniFocus = Application('OmniFocus');
    OmniFocus.includeStandardAdditions = false;

    if (!OmniFocus.running()) {
      return 'ERROR: OmniFocus is not running';
    }

    const doc = OmniFocus.defaultDocument();

    // Get matching projects
    let matchingProjects;
    if (query !== '') {
      // Use whose clause for filtering when query is provided
      matchingProjects = doc.flattenedProjects.whose({ name: { _contains: query } })();
    } else {
      // Get all projects when no query
      matchingProjects = doc.flattenedProjects();
    }

    // Filter by active status if needed (post-filter since status check doesn't work in whose clause)
    if (activeOnly) {
      const filteredProjects = [];
      for (let i = 0; i < matchingProjects.length; i++) {
        const project = matchingProjects[i];
        const status = String(project.status());
        if (!project.completed() && status.includes('active')) {
          filteredProjects.push(project);
        }
      }
      matchingProjects = filteredProjects;
    }

    // Process results
    const resultList = [];

    for (let i = 0; i < matchingProjects.length; i++) {
      const project = matchingProjects[i];
      const projectId = project.id();
      const projectName = project.name() || '';

      // Get folder name
      let folderName = '';
      try {
        const parentFolder = project.folder();
        if (parentFolder && parentFolder.name) {
          folderName = parentFolder.name();
        }
      } catch (e) {
        // No folder
      }

      // Determine status
      let projectStatus = 'active';
      if (project.completed()) {
        projectStatus = 'completed';
      } else if (project.status() === 'on hold') {
        projectStatus = 'on-hold';
      }

      // Format as: id|name|folder|status
      const projectString = projectId + ITEM_DELIMITER + projectName + ITEM_DELIMITER + folderName + ITEM_DELIMITER + projectStatus;
      resultList.push(projectString);
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
