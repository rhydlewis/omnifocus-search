function run(argv) {
  const query = (argv[0] || "").toLowerCase();

  const of = Application("OmniFocus");
  of.includeStandardAdditions = true;

  const now = new Date();
  now.setHours(0, 0, 0, 0); // Start of today

  const flattenedTasks = of.defaultDocument.flattenedTasks();
  const results = [];
  const blocked = {
    projectOnHold: 0,
    projectDeferred: 0,
    taskDeferred: 0,
    sequential: 0
  };

  // Cache for sequential project first incomplete tasks to avoid repeated lookups
  const sequentialProjectCache = new Map();

  for (let task of flattenedTasks) {
    // Skip completed and dropped tasks
    if (task.completed() || task.dropped()) {
      continue;
    }

    // Check if query matches (if provided)
    const name = task.name().toLowerCase();
    const note = (task.note() || "").toLowerCase();

    if (query && !name.includes(query) && !note.includes(query)) {
      continue;
    }

    // Check task defer date
    const taskDeferDate = task.deferDate();
    if (taskDeferDate && taskDeferDate > now) {
      blocked.taskDeferred++;
      continue;
    }

    // Get containing project
    const project = task.containingProject();

    // Tasks in inbox (no project) are always available
    if (!project) {
      results.push(createTaskResult(task, "Inbox"));
      continue;
    }

    // Check project status
    const projectStatus = project.status();
    if (projectStatus === "on hold") {
      blocked.projectOnHold++;
      continue;
    }

    if (projectStatus === "dropped" || project.completed()) {
      continue; // Skip dropped/completed projects entirely
    }

    // Check project defer date
    const projectDeferDate = project.deferDate();
    if (projectDeferDate && projectDeferDate > now) {
      blocked.projectDeferred++;
      continue;
    }

    // Check sequential project blocking
    if (project.sequential && project.sequential()) {
      // In sequential projects, only first incomplete task is available
      const projectId = project.id();
      let firstIncomplete = sequentialProjectCache.get(projectId);

      // Cache miss - find and cache the first incomplete task
      if (firstIncomplete === undefined) {
        const projectTasks = project.tasks();
        firstIncomplete = null;

        for (let pt of projectTasks) {
          if (!pt.completed() && !pt.dropped()) {
            firstIncomplete = pt;
            break;
          }
        }

        sequentialProjectCache.set(projectId, firstIncomplete);
      }

      if (firstIncomplete && firstIncomplete.id() !== task.id()) {
        blocked.sequential++;
        continue;
      }
    }

    // Task is available!
    results.push(createTaskResult(task, project.name()));
  }

  // Return results with blocked count metadata
  return JSON.stringify({
    tasks: results,
    blocked: blocked,
    totalAvailable: results.length,
    totalBlocked: blocked.projectOnHold + blocked.projectDeferred +
                  blocked.taskDeferred + blocked.sequential
  });
}

function createTaskResult(task, projectName) {
  const tags = task.tags();
  const tagNames = [];
  for (let tag of tags) {
    tagNames.push(tag.name());
  }

  return {
    id: task.id(),
    name: task.name(),
    note: task.note() || "",
    projectName: projectName,
    tags: tagNames,
    dueDate: task.dueDate() ? task.dueDate().toString() : "",
    flagged: task.flagged(),
    estimatedMinutes: task.estimatedMinutes() || 0,
    deferDate: task.deferDate() ? task.deferDate().toString() : ""
  };
}
