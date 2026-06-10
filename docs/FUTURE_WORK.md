# Future Work

## Next Technical Steps

1. Finish Batch 3 error retry.
2. Merge successful retry hashes into the Batch 3 duplicate review.
3. Move any retry-confirmed older duplicates after approval.
4. Hash Batch 4 fast-first manifest.
5. Continue Batch 5, Batch 6, and later fast-first batches.
6. Process deferred large media at the end in small groups.

## Organization Steps

1. Refresh full inventory after duplicate cleanup.
2. Build organization proposal by department era:
   - Department/Role A
   - Department/Role B
3. Within each era, classify:
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
