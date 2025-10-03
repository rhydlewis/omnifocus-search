# OmniFocus Search Workflow for Alfred

This workflow allows you to quickly search and navigate OmniFocus data directly from Alfred. Easily find tasks, projects, tags, folders, and more using simple keyword commands.

## Installation

1. Download the latest `omnifocus-search.alfredworkflow` file from the releases
2. Double-click the downloaded file to import it into Alfred
3. Ensure OmniFocus is installed on your Mac

## Usage

The workflow provides multiple keyword commands to search different types of OmniFocus data:

- `.s [query]` - Search active tasks
- `.sa [query]` - Search available (unblocked) tasks - excludes tasks blocked by project status or defer dates
- `.sc [query]` - Search completed tasks
- `.p [query]` - Search projects
- `.lp` - List projects
- `.i [query]` - Search inbox items
- `.li` - List inbox items
- `.t [query]` - Search tags
- `.f [query]` - Search folders
- `.v [query]` - Search perspectives
- `.lt` - List tags
- `.lf` - List folders
- `.lv` - List perspectives
- `.n [query]` - Search task notes

### Examples

- `.s meeting` - Find all active tasks containing "meeting"
- `.sa urgent` - Find available tasks containing "urgent" (excludes blocked tasks)
- `.sc report` - Find completed tasks containing "report"
- `.p home` - Find projects containing "home"
- `.t work` - Find tags containing "work"

### Available Tasks

The `.sa` command searches only for tasks that are ready to work on now, filtering out:
- Tasks in projects that are on hold
- Tasks in projects with future defer dates
- Tasks with their own future defer dates
- Tasks blocked by sequential project ordering (only shows first incomplete task)

## Requirements

- macOS 10.14 or later
- Alfred 4 or later with Powerpack
- OmniFocus Pro

## How It Works

This workflow uses AppleScript to communicate directly with OmniFocus. When you enter a query, the workflow:

1. Passes your query to the appropriate script
2. Searches OmniFocus for matching items
3. Returns the results to Alfred for display
4. When you select an item, OmniFocus opens and selects that item

## Credits

This workflow is a reimplementation of the original [Node.js/SQLite-based Alfred-OmniFocus workflow](https://github.com/rhydlewis/alfred-search-omnifocus), converted to use AppleScript and bash for better compatibility.

Thanks to:

* [Marko Kaestner](https://github.com/markokaestner): I used
  the [in-depth workflow](https://github.com/markokaestner/of-task-actions) to provide some insight into how to search
  Omnifocus.
* [Danny Smith](https://github.com/dannysmith): for providing a new, and quite frankly, much improved workflow icon.
* [Font Awesome](https://fontawesome.com/): for the other icons used in this workflow