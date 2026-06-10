# File Organization Toolkit

This repository documents and maintains a safe, batch-based process for cleaning and organizing large file collections without requiring all content to be available locally at once.

The first implementation was created for a cloud-backed OneDrive folder. The design is intentionally broader: it can later be adapted for other cloud providers or offline folders. The workflow processes files in small, resumable batches, confirms duplicates by content hash, moves only older confirmed duplicates, and asks for approval before every move step.

## Status

This repository is a public, provider-agnostic toolkit and documentation project. It does not track the live status of any specific cleanup job. Project-specific progress should stay in local/private reports.

## What Was Built

- A safe batch hashing workflow for OneDrive Files On-Demand.
- A one-screen Windows control app for start, stop, refresh, log, and progress.
- An Overall Progress screen showing completed batches, remaining tasks, and later organization phases.
- A Configuration screen for changing safety limits without editing scripts.
- A fast-first batch preparation strategy to avoid spending days blocked on large media files.
- Documentation for architecture, operations, configuration, progress, and safety.

The public version uses generic examples and placeholder paths. Real inventories, logs, local configuration files, and organization-specific folder names are intentionally excluded.

## Main Rules

- Never delete files.
- Confirm duplicates by content hash, not by name.
- Keep the newest/main copy in its current location.
- Move only older confirmed duplicates into nearby `_older_duplicates` folders.
- Preserve app-managed folders such as Attachments, Documents, Pictures, Desktop, Teams, OneNote, and similar containers.
- Do not split CAD, application, license, metadata, readme, or package folders.
- In case of doubt, treat the folder container as one package.
- Defer large videos and very large files until the end.

## Documentation

- [Project Page](docs/PROJECT_PAGE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Workflow](docs/WORKFLOW.md)
- [Roadmap and TODO](docs/ROADMAP.md)
- [Configuration](docs/CONFIGURATION.md)
- [Control App](docs/CONTROL_APP.md)
- [Safety and Privacy](docs/SAFETY_AND_PRIVACY.md)
- [Future Work](docs/FUTURE_WORK.md)

## Repository Scope

This repository intentionally does not include raw inventories, hash CSVs, logs, or file lists from the actual OneDrive. Those artifacts can contain sensitive personal or company filenames. The repository contains the process, architecture, summarized metrics, and maintenance notes.

## Roadmap Note

Future versions should support provider adapters for OneDrive, Google Drive, Dropbox, SharePoint libraries, network drives, and offline/local folders.
