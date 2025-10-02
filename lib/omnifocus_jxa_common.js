#!/usr/bin/osascript -l JavaScript

/**
 * Common JXA Library for OmniFocus Search Workflow
 *
 * This library provides utility functions for JXA scripts that interact with OmniFocus.
 * It includes wrappers for common operations, error handling, and performance monitoring.
 */

// OmniFocus application reference
const OmniFocus = Application('OmniFocus');
OmniFocus.includeStandardAdditions = true;

// Constants
const ITEM_DELIMITER = '|';
const RECORD_DELIMITER = '•••';
const DEFAULT_TIMEOUT = 30; // seconds

/**
 * Error handling utilities
 */
const ErrorHandler = {
  /**
   * Creates a standardized error message
   * @param {string} operation - The operation that failed
   * @param {Error} error - The error object
   * @returns {string} Formatted error message
   */
  formatError(operation, error) {
    return `Error during ${operation}: ${error.message}`;
  },

  /**
   * Logs an error to stderr
   * @param {string} message - Error message
   */
  logError(message) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    try {
      app.doShellScript(`echo "[ERROR] ${message}" >&2`);
    } catch (e) {
      // If logging fails, fail silently
    }
  },

  /**
   * Wraps a function with error handling
   * @param {Function} fn - Function to wrap
   * @param {string} operation - Operation name for error messages
   * @returns {Function} Wrapped function
   */
  withErrorHandling(fn, operation) {
    return function(...args) {
      try {
        return fn.apply(this, args);
      } catch (error) {
        const errorMsg = ErrorHandler.formatError(operation, error);
        ErrorHandler.logError(errorMsg);
        throw new Error(errorMsg);
      }
    };
  }
};

/**
 * Performance monitoring utilities
 */
const Performance = {
  /**
   * Measures execution time of a function
   * @param {Function} fn - Function to measure
   * @param {string} label - Label for the measurement
   * @returns {any} Result of the function
   */
  measure(fn, label) {
    const startTime = new Date().getTime();
    try {
      const result = fn();
      const endTime = new Date().getTime();
      const duration = endTime - startTime;
      this.log(label, duration);
      return result;
    } catch (error) {
      const endTime = new Date().getTime();
      const duration = endTime - startTime;
      this.log(`${label} (failed)`, duration);
      throw error;
    }
  },

  /**
   * Logs performance data
   * @param {string} operation - Operation name
   * @param {number} duration - Duration in milliseconds
   */
  log(operation, duration) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    try {
      app.doShellScript(`echo "[PERF] ${operation}: ${duration}ms" >&2`);
    } catch (e) {
      // If logging fails, fail silently
    }
  }
};

/**
 * Logging utilities
 */
const Logger = {
  /**
   * Logs a debug message
   * @param {string} message - Message to log
   */
  debug(message) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    try {
      app.doShellScript(`echo "[DEBUG] ${message}" >&2`);
    } catch (e) {
      // If logging fails, fail silently
    }
  },

  /**
   * Logs an info message
   * @param {string} message - Message to log
   */
  info(message) {
    const app = Application.currentApplication();
    app.includeStandardAdditions = true;
    try {
      app.doShellScript(`echo "[INFO] ${message}" >&2`);
    } catch (e) {
      // If logging fails, fail silently
    }
  }
};

/**
 * OmniFocus utility functions
 */
const OFUtils = {
  /**
   * Joins an array into a delimited string
   * @param {Array} list - Array to join
   * @param {string} delimiter - Delimiter to use
   * @returns {string} Joined string
   */
  joinList(list, delimiter = ITEM_DELIMITER) {
    return list.join(delimiter);
  },

  /**
   * Safely gets a property from an object, returning a default value if missing
   * @param {Object} obj - Object to get property from
   * @param {string} propertyName - Name of the property
   * @param {any} defaultValue - Default value if property is missing
   * @returns {any} Property value or default
   */
  safeGet(obj, propertyName, defaultValue = '') {
    try {
      const value = obj[propertyName];
      return (value === null || value === undefined) ? defaultValue : value;
    } catch (error) {
      return defaultValue;
    }
  },

  /**
   * Gets the project name for a task
   * @param {Object} task - OmniFocus task object
   * @returns {string} Project name
   */
  getProjectName(task) {
    try {
      const project = task.containingProject();
      if (project && project.name()) {
        return project.name();
      }

      // Check if task is in inbox
      const doc = OmniFocus.defaultDocument();
      const inboxTasks = doc.inboxTasks();
      const taskId = task.id();

      for (let i = 0; i < inboxTasks.length; i++) {
        if (inboxTasks[i].id() === taskId) {
          return 'Inbox';
        }
      }

      return '(No Project)';
    } catch (error) {
      return '(No Project)';
    }
  },

  /**
   * Gets the status of a task
   * @param {Object} task - OmniFocus task object
   * @returns {string} Status (active, completed, flagged, on-hold)
   */
  getTaskStatus(task) {
    try {
      if (task.completed()) {
        return 'completed';
      } else if (task.flagged()) {
        return 'flagged';
      } else {
        try {
          const project = task.containingProject();
          if (project && project.status() === 'on hold') {
            return 'on-hold';
          }
        } catch (e) {
          // Project might not exist
        }
        return 'active';
      }
    } catch (error) {
      return 'active';
    }
  },

  /**
   * Gets the status of a project
   * @param {Object} project - OmniFocus project object
   * @returns {string} Status (active, completed, on-hold)
   */
  getProjectStatus(project) {
    try {
      if (project.completed()) {
        return 'completed';
      } else if (project.status() === 'on hold') {
        return 'on-hold';
      } else {
        return 'active';
      }
    } catch (error) {
      return 'active';
    }
  },

  /**
   * Cleans a string for output by replacing delimiters
   * @param {string} str - String to clean
   * @returns {string} Cleaned string
   */
  cleanString(str) {
    if (!str || str === null || str === undefined) {
      return '';
    }

    let cleaned = String(str);
    // Replace item delimiter with space
    cleaned = cleaned.replace(/\|/g, ' ');
    // Replace record delimiter with space
    cleaned = cleaned.replace(/•••/g, ' ');

    return cleaned;
  },

  /**
   * Replaces all occurrences of a substring
   * @param {string} text - Text to process
   * @param {string} oldString - String to replace
   * @param {string} newString - Replacement string
   * @returns {string} Processed text
   */
  replaceString(text, oldString, newString) {
    if (!text) return '';
    return String(text).split(oldString).join(newString);
  },

  /**
   * Gets the default document
   * @returns {Object} OmniFocus default document
   */
  getDefaultDocument() {
    return OmniFocus.defaultDocument();
  },

  /**
   * Checks if OmniFocus is running
   * @returns {boolean} True if running
   */
  isRunning() {
    return OmniFocus.running();
  },

  /**
   * Formats a date as ISO string or returns empty string
   * @param {Date} date - Date to format
   * @returns {string} Formatted date or empty string
   */
  formatDate(date) {
    if (!date || date === null) {
      return '';
    }
    try {
      return date.toISOString();
    } catch (error) {
      return '';
    }
  },

  /**
   * Converts OmniFocus task to output format
   * @param {Object} task - OmniFocus task
   * @returns {string} Formatted task string
   */
  taskToString(task) {
    try {
      const name = this.cleanString(task.name());
      const project = this.cleanString(this.getProjectName(task));
      const note = this.cleanString(this.safeGet(task, 'note', ''));
      const id = task.id();
      const status = this.getTaskStatus(task);

      return this.joinList([name, project, note, id, status], ITEM_DELIMITER);
    } catch (error) {
      ErrorHandler.logError(`Error converting task to string: ${error.message}`);
      return '';
    }
  },

  /**
   * Converts OmniFocus project to output format
   * @param {Object} project - OmniFocus project
   * @returns {string} Formatted project string
   */
  projectToString(project) {
    try {
      const name = this.cleanString(project.name());
      const note = this.cleanString(this.safeGet(project, 'note', ''));
      const id = project.id();
      const status = this.getProjectStatus(project);

      return this.joinList([name, note, id, status], ITEM_DELIMITER);
    } catch (error) {
      ErrorHandler.logError(`Error converting project to string: ${error.message}`);
      return '';
    }
  }
};

/**
 * Export utilities for use in other scripts
 */
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    OmniFocus,
    ErrorHandler,
    Performance,
    Logger,
    OFUtils,
    ITEM_DELIMITER,
    RECORD_DELIMITER
  };
}
