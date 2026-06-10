# Scripts

The working scripts are currently maintained in the local project folder because they contain machine-specific paths and operational state.

Local scripts created for the workflow:

- `OneDriveBatchControl.ps1`
- `OneDrive Batch Control.cmd`
- `Invoke-OneDriveLocalHashBatch.ps1`
- `Run-OneDriveHashBatchOvernight.ps1`
- `Prepare-OneDriveNextBatch.ps1`

Before publishing runnable script copies here, sanitize:

- user profile path
- OneDrive root path
- report folder path
- batch names tied to current machine state

Use placeholders or a configuration file for all paths.

