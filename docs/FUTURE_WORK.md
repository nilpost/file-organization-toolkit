# Future Work

This page describes general toolkit direction. It does not track a specific user's current cleanup status.

## Next Technical Steps

1. Create a reusable job configuration format.
2. Add commands for preparing, running, retrying, and summarizing batches.
3. Add generic report generation that can redact sensitive file paths.
4. Add a large-media workflow that runs at the end of a cleanup project.
5. Add a dry-run organization planner.

## Organization Steps

1. Refresh full inventory after duplicate cleanup.
2. Build organization proposal by time period, role, project, or material type.
3. Within each major category, classify:
   - internal material
   - external/customer/event material
   - research/reference/source material
4. Preserve package folders and app-managed containers.
5. Review proposed moves before applying.

## Possible Improvements

- Add a dashboard export in HTML.
- Add automatic retry grouping by error type.
- Add a large-media-only queue.
- Add a dry-run organization planner.
- Add cloud-side hash support if Microsoft Graph access becomes available.
- Generalize the toolkit beyond OneDrive with provider adapters:
  - OneDrive and SharePoint libraries.
  - Google Drive.
  - Dropbox.
  - Network/shared drives.
  - Offline/local folders.
- Move provider-specific paths and commands behind a configuration/provider layer.
