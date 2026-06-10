# Configuration

The control app saves user settings in:

`OneDriveBatchControl.config.json`

This file is local and should not be committed if it contains personal paths or machine-specific settings.

## Current Defaults

| Setting | Default | Meaning |
|---|---:|---|
| `MinFreeGB` | 20 | Stop processing if free space drops below this value |
| `SliceSize` | 3 | Number of retry files processed per slice |
| `FileTimeoutSeconds` | 1800 | Timeout per file during retry |
| `MaxHours` | 168 | Maximum background run duration |
| `FastBatchSizeCapGB` | 8 | Maximum size of a prepared fast-first batch |
| `FastBatchMaxFiles` | 500 | Maximum number of files in a prepared fast-first batch |
| `MaxFastFileSizeMB` | 100 | Files above this size are deferred |
| `NextBatchName` | `local_hash_batch_04` | Name prefix for the next prepared batch |

## Recommended Values

- Keep `MinFreeGB` at 20 GB or higher.
- Keep retry `SliceSize` small for large media.
- Increase `MaxFastFileSizeMB` only if there is enough disk space.
- Use a new `NextBatchName` for each future batch.
- The control app detects the active task title from the current manifest/output name.
