# Security policy

## Supported versions

Only the current default branch is supported.

## Reporting vulnerabilities

Report vulnerabilities privately through GitHub private vulnerability reporting or another private owner-approved channel. Do not disclose vulnerabilities through public GitHub issues. Redact credentials and sensitive filenames or logs.

## Security expectations

Review configuration and script paths before execution, do not run the control application elevated unless required, restrict write access to its directory and configuration, preserve explicit approval gates for file moves, and keep inventories and logs private.

# Security & Privacy Remediation Backlog

The standard scan found no validated vulnerabilities in the reviewed current-tree scope. The local configuration is trusted operator input and the reviewed control application does not itself delete or move files.
