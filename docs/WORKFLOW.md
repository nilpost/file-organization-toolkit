# Workflow

## Duplicate Cleanup Workflow

1. Refresh inventory.
2. Exclude:
   - `_older_duplicates`
   - already handled files
   - package/application folders
   - protected metadata/package contents
3. Group candidates by extension and exact byte size.
4. Apply fast-first rule:
   - non-media and small/medium files first
   - large files and videos deferred
5. Prepare a batch manifest.
6. Run hashing in controlled slices.
7. Request OneDrive free-up-space after hashing.
8. Generate duplicate review from matching SHA256 hashes.
9. Wait for approval.
10. Move older duplicates into nearby `_older_duplicates`.
11. Verify:
   - moved destination exists
   - old source path no longer exists
   - main/newest copy still exists
   - move errors are zero

## Error Retry Workflow

1. Collect error rows from the batch hash result.
2. Confirm all error file paths still exist.
3. Create retry manifest.
4. Run retry with smaller slice size and longer timeout.
5. Merge successful retry results into the batch final review.
6. Defer persistent cloud errors if they are large media or invalid cloud operations.

## Organization Workflow

Organization should start after duplicate cleanup has reduced the noise.

Planned top-level logic:

- Department/Role A: earlier work period.
- Department/Role B: current work period.

Within each era:

- Internal material.
- External/customer/event material.
- Research/reference/source material.
- Packages and application-managed folders preserved as containers.

