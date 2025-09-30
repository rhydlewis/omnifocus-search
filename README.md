# OmniFocus Search Workflow for Alfred

This workflow allows you to quickly search and navigate OmniFocus data directly from Alfred. Easily find tasks, projects, tags, folders, and more using simple keyword commands.

## Installation

1. Download the latest `omnifocus-search.alfredworkflow` file from the releases
2. Double-click the downloaded file to import it into Alfred
3. Ensure OmniFocus is installed on your Mac

## Usage

The workflow provides multiple keyword commands to search different types of OmniFocus data:

- `.s [query]` - Search active tasks
- `.sc [query]` - Search completed tasks
- `.p [query]` - Search projects
- `.i [query]` - Search inbox items
- `.t [query]` - Search tags
- `.f [query]` - Search folders
- `.v [query]` - Search perspectives
- `.n [query]` - Search task notes

### Examples

- `.s meeting` - Find all active tasks containing "meeting"
- `.sc report` - Find completed tasks containing "report"
- `.p home` - Find projects containing "home"
- `.t work` - Find tags containing "work"
- `.i` - Show all inbox items (empty query shows all)

## Requirements

- macOS 10.14 or later
- Alfred 4 or later with Powerpack
- OmniFocus 3 or OmniFocus 4

## How It Works

This workflow uses AppleScript to communicate directly with OmniFocus. When you enter a query, the workflow:

1. Passes your query to the appropriate script
2. Searches OmniFocus for matching items
3. Returns the results to Alfred for display
4. When you select an item, OmniFocus opens and selects that item

## Credits

This workflow is a reimplementation of the original Node.js/SQLite-based Alfred-OmniFocus workflow, converted to use AppleScript and bash for better performance and compatibility.