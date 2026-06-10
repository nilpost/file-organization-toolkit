# Approvals and Operating Steps

This page defines the approval gates and operating checklist for running the toolkit without an assistant.

## Goal

The executable/control app should guide the user through safe batch preparation, hashing, review, approval, movement, verification, and later organization.

## Approval Gates

| Gate | Action | Approval Requirement |
|---|---|---|
| A1 | Start or resume hashing/retry batch | Allowed after app verifies scripts, manifest, free space, and process state |
| A2 | Move confirmed older duplicates | Requires explicit user approval after reviewing duplicate move candidates |
| A3 | Retry failed/error files | Requires user decision when errors/timeouts remain |
| A4 | Prepare next fast-first batch | Safe metadata/report action; no download, hash, move, or delete |
| A5 | Move non-duplicate content for organization | Requires reviewed folder map and explicit approval |

## Standard Batch Steps

1. Refresh inventory.
2. Exclude already handled files and `_older_duplicates`.
3. Preserve package/application/container folders.
4. Build same-extension/same-size candidate groups.
5. Apply fast-first rule:
   - small/medium non-media first
   - videos and large files deferred
6. Prepare manifest.
7. Start/resume hashing from the app.
8. Hydrate a small slice, hash SHA256, and write result rows.
9. Request free-up-space after each file where supported.
10. Generate duplicate review from matching SHA256 groups.
11. Ask for user approval before moving older duplicates.
12. Move approved older duplicates into nearby `_older_duplicates`.
13. Verify move result.
14. Update reports.
15. Continue the next batch.

## Verification Before Starting

- Runner script exists.
- Worker/hash script exists.
- Manifest exists.
- Free space is above the configured stop limit.
- No matching batch process is already running.
- Active task title is detected from manifest/output.

## Verification Before Moving Duplicates

- Duplicate review exists.
- Each candidate has a matching SHA256 duplicate group.
- Newest/main copy is identified.
- Suggested destination is inside a nearby `_older_duplicates` folder.
- User explicitly approves the move.

## Verification After Moving

- Moved destination exists.
- Old source path no longer exists.
- Main/newest copy still exists.
- Move errors are zero.
- Move summary and execution log are written.

## Never Automatic

- Do not delete files.
- Do not move non-duplicates without an approved organization plan.
- Do not split package folders, CAD/app folders, licenses, metadata, readme files, or similar containers.
- Do not move main/newest duplicate copies.
- Do not publish raw inventories, logs, hashes, or sensitive filenames.

## Self-Service TODO

- Add `Generate Duplicate Review` button.
- Add `Review Pending Moves` screen.
- Add `Approve and Move Selected Duplicates` button with confirmation.
- Add post-move verification screen.
- Add `Retry Errors` manifest generator.
- Add `Merge Retry Results` button.
- Add `Prepare Next Batch` job-name selector.
- Add organization planning screen after duplicate cleanup.

