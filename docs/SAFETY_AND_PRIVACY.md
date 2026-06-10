# Safety and Privacy

## What Not To Commit

Do not commit:

- full file inventories
- hash result CSVs
- move logs
- raw error logs
- OneDrive paths with sensitive filenames
- local configuration containing personal paths

## Why

Even when file content is not included, filenames and folder names can reveal sensitive personal, company, customer, project, or research information.

## Safe To Commit

Safe repository content should be limited to:

- process documentation
- architecture diagrams
- summarized counts
- generalized scripts or templates
- operational checklists
- non-sensitive examples

## Move Safety

The process does not delete files. It moves older confirmed duplicates into nearby `_older_duplicates` folders. This keeps recovery simple and preserves context.

## Approval Rule

No duplicate movement or organization movement should happen without explicit user approval.

