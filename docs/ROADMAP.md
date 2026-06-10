# Roadmap and TODO

This page tracks general toolkit improvements. It intentionally does not include the live status of any user's folder cleanup project.

## Near-Term TODO

- Add a dry-run report generator for duplicate candidates.
- Add a generic batch-result summary command.
- Add a sanitized HTML dashboard export.
- Add a large-media-only queue.
- Add retry grouping by error type.
- Add a cleanup-job template so users can track their own private progress outside the public repository.

## Provider Support

- Keep the current local-folder and OneDrive Files On-Demand workflow.
- Add provider adapters:
  - OneDrive and SharePoint libraries.
  - Google Drive.
  - Dropbox.
  - network/shared drives.
  - offline/local folders.
- Move provider-specific behavior behind a configuration/provider layer.

## App Improvements

- Add a job selector so one app can manage multiple manifests.
- Add a provider selector.
- Add a safer configuration wizard.
- Add export buttons for sanitized reports.
- Add clearer paused, stopped, completed, and blocked states.
- Add optional notifications when a long-running batch completes.

## Duplicate Cleanup Improvements

- Add hash-cache reuse across batches.
- Add smarter prioritization:
  - small files first
  - documents before media
  - large videos last
  - package/application folders excluded by default
- Add a "manual review required" bucket.
- Add a compare-and-merge step for retry results.

## Organization Planner

- Add category proposal generation from metadata.
- Add rules for organization by time period, project, department, material type, or source.
- Add a dry-run move plan.
- Add a review UI before moving non-duplicate content.

## Safety

- Keep default behavior non-destructive.
- Move older duplicates to `_older_duplicates` instead of deleting.
- Require explicit approval before move operations.
- Add sensitive-filename scan before exporting reports.
- Add public/private report modes.
