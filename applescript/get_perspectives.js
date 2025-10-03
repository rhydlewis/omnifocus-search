#!/usr/bin/osascript -l JavaScript

/**
 * Get perspectives from OmniFocus (JXA version)
 *
 * Parameters:
 *   1. query (string): search text
 *
 * Returns:
 *   Delimited string of perspectives in format: id|name|type###id|name|type...
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

    const resultList = [];

    // Built-in perspectives
    const builtInPerspectives = [
      { id: 'Inbox', name: 'Inbox' },
      { id: 'Projects', name: 'Projects' },
      { id: 'Tags', name: 'Tags' },
      { id: 'Forecast', name: 'Forecast' },
      { id: 'Flagged', name: 'Flagged' },
      { id: 'Review', name: 'Review' }
    ];

    // Process built-in perspectives
    const lowerQuery = query.toLowerCase();
    for (let i = 0; i < builtInPerspectives.length; i++) {
      const perspective = builtInPerspectives[i];
      if (query === '' || perspective.name.toLowerCase().includes(lowerQuery)) {
        const perspectiveString = perspective.id + ITEM_DELIMITER + perspective.name + ITEM_DELIMITER + 'Built-in';
        resultList.push(perspectiveString);
      }
    }

    // Get custom perspectives
    try {
      const allPerspectives = OmniFocus.perspectives();
      const builtInNames = new Set(builtInPerspectives.map(p => p.name));

      for (let i = 0; i < allPerspectives.length; i++) {
        try {
          const perspective = allPerspectives[i];
          let perspectiveName = '';

          try {
            perspectiveName = perspective.name();
          } catch (e) {
            // Try to get ID as fallback
            try {
              const perspectiveId = perspective.id();
              if (perspectiveId && !perspectiveId.startsWith('OmniFocus')) {
                perspectiveName = 'Custom Perspective ' + perspectiveId;
              } else {
                perspectiveName = 'Custom Perspective';
              }
            } catch (err) {
              // Skip this perspective
              continue;
            }
          }

          // Skip if no valid name or is built-in
          if (!perspectiveName || builtInNames.has(perspectiveName)) {
            continue;
          }

          // Only include if it matches the query
          if (query === '' || perspectiveName.toLowerCase().includes(lowerQuery)) {
            const perspectiveString = perspectiveName + ITEM_DELIMITER + perspectiveName + ITEM_DELIMITER + 'Custom';
            resultList.push(perspectiveString);
          }
        } catch (e) {
          // Skip any perspective that causes an error
        }
      }
    } catch (e) {
      // Continue with just built-in perspectives if custom perspectives fail
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
