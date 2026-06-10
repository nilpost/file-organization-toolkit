# Project Page

## Background

The goal is to categorize and organize a large file collection while identifying duplicate files by content. The first implementation targets a OneDrive folder backed by OneDrive Files On-Demand, where downloading all files at once would exceed available local disk space.

The user requested a cautious workflow:

- Preserve the current folder logic instead of reorganizing from zero.
- Consider two main department eras:
  - Department/Role A: earlier work period.
  - Department/Role B: current work period.
- Separate internal material from external/customer/event material and research/reference/source material.
- Do not split CAD, app, metadata, license, readme, or package folders.
- Keep application-managed folder names in place, including Attachments, Documents, Pictures, Desktop, Teams, OneNote, and similar folders.
- Treat a folder container as one file/package when uncertain.

## Problem

The obvious method, downloading everything and hashing all files, is not viable because:

- OneDrive files are mostly cloud-only.
- Local disk space is limited.
- Some large media files take a long time to hydrate.
- Some cloud files time out or return sync-provider errors.
- Duplicate names are not reliable; duplicates must be confirmed by content.

## Solution

The solution is a staged, provider-aware pipeline:

1. Scan metadata without forcing full downloads when the provider supports cloud-only files.
2. Build same-extension/same-size candidate groups.
3. Exclude package folders, already handled files, and `_older_duplicates`.
4. Hydrate and hash candidates in small batches.
5. Mark files as online-only/free-up-space after hashing.
6. Generate a duplicate review.
7. Move older duplicates only after approval.
8. Verify destinations, source removal, and main-copy presence.
9. Repeat until candidate pools are exhausted or deferred.

## Important Change

After several days, the process was improved with a fast-first strategy:

- Small and medium non-media files are processed first.
- Large files and videos are deferred.
- Large media will be processed later in smaller, focused groups.

This avoids spending long periods blocked by large cloud video hydration.

## Current State

Three cleanup batches were completed and verified in the original implementation. A later retry batch remained resumable, and a fast-first batch was prepared using the improved strategy.

## Final Target

The final activity has two major phases:

1. Duplicate cleanup until remaining duplicate candidates are processed, skipped, or deferred.
2. Organization planning and movement by department era and material type.

No non-duplicate organization moves should occur until a proposed folder map is reviewed and approved.
