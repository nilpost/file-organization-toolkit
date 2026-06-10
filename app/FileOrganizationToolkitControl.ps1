Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'SilentlyContinue'

$ScriptFolder = if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    Split-Path -Parent $PSCommandPath
} else {
    Get-Location
}

$ConfigPath = Join-Path $ScriptFolder 'FileOrganizationToolkit.config.json'

$DefaultConfig = [pscustomobject]@{
    BasePath = '<path-to-work-folder>'
    RunnerScript = '<path-to-runner-script.ps1>'
    WorkerScript = '<path-to-worker-script.ps1>'
    ManifestPath = '<path-to-current-manifest.csv>'
    OutputPath = '<path-to-current-output.csv>'
    LogPath = '<path-to-current-log.log>'
    MinFreeGB = 20
    SliceSize = 3
    FileTimeoutSeconds = 1800
    MaxHours = 168
}

function Save-Config($Config) {
    $Config | ConvertTo-Json | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

function Load-Config {
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        Save-Config $DefaultConfig
        return $DefaultConfig
    }

    try {
        return Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        Save-Config $DefaultConfig
        return $DefaultConfig
    }
}

$Config = Load-Config

function Get-TaskNameFromPath {
    param([string]$Path)
    $leaf = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    if ($leaf -match 'batch[_-]?(\d+).*retry') {
        return "Batch $([int]$matches[1]) Error Retry"
    }
    if ($leaf -match 'batch[_-]?(\d+)') {
        return "Batch $([int]$matches[1]) Hashing"
    }
    return 'File Organization Task'
}

function Get-ActiveTaskName {
    if (-not [string]::IsNullOrWhiteSpace($Config.ManifestPath)) {
        return Get-TaskNameFromPath $Config.ManifestPath
    }
    if (-not [string]::IsNullOrWhiteSpace($Config.OutputPath)) {
        return Get-TaskNameFromPath $Config.OutputPath
    }
    return 'File Organization Task'
}

function Get-FreeGB {
    [math]::Round((Get-PSDrive -Name C).Free / 1GB, 2)
}

function Get-RunnerProcesses {
    Get-CimInstance Win32_Process -Filter "name = 'powershell.exe' or name = 'pwsh.exe'" |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine -like "*$($Config.RunnerScript)*" -and
            ($_.CommandLine -like "*$($Config.ManifestPath)*" -or $_.CommandLine -like "*$($Config.OutputPath)*")
        }
}

function Get-Counts {
    $manifestRows = if (Test-Path -LiteralPath $Config.ManifestPath) { @(Import-Csv -LiteralPath $Config.ManifestPath) } else { @() }
    $resultRows = if (Test-Path -LiteralPath $Config.OutputPath) { @(Import-Csv -LiteralPath $Config.OutputPath) } else { @() }

    [pscustomobject]@{
        Total = $manifestRows.Count
        Done = $resultRows.Count
        Hashed = @($resultRows | Where-Object { $_.Status -eq 'Hashed' }).Count
        Errors = @($resultRows | Where-Object { $_.Status -eq 'Error' }).Count
        Remaining = [math]::Max(0, $manifestRows.Count - $resultRows.Count)
        OutputLastWrite = if (Test-Path -LiteralPath $Config.OutputPath) { (Get-Item -LiteralPath $Config.OutputPath).LastWriteTime } else { $null }
    }
}

function Get-LastLog {
    if (-not (Test-Path -LiteralPath $Config.LogPath)) {
        return 'Log not created yet.'
    }
    $lines = @(Get-Content -LiteralPath $Config.LogPath -Tail 25)
    (($lines -join "`r`n") -replace "`0", '').Trim()
}

function Start-Task {
    if (@(Get-RunnerProcesses).Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show('Task is already running.') | Out-Null
        return
    }
    if ((Get-FreeGB) -lt [double]$Config.MinFreeGB) {
        [System.Windows.Forms.MessageBox]::Show('Free space is below the configured stop threshold.') | Out-Null
        return
    }

    $args = @(
        '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', $Config.RunnerScript,
        '-Script', $Config.WorkerScript,
        '-Manifest', $Config.ManifestPath,
        '-Output', $Config.OutputPath,
        '-Log', $Config.LogPath,
        '-SliceSize', ([string]$Config.SliceSize),
        '-FileTimeoutSeconds', ([string]$Config.FileTimeoutSeconds),
        '-MinimumFreeGB', ([string]$Config.MinFreeGB),
        '-MaxHours', ([string]$Config.MaxHours)
    )
    Start-Process -FilePath 'powershell.exe' -ArgumentList $args -WindowStyle Hidden | Out-Null
}

function Stop-Task {
    $running = @(Get-RunnerProcesses)
    if ($running.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('No managed task is currently running.') | Out-Null
        return
    }

    $answer = [System.Windows.Forms.MessageBox]::Show('Stop the running task?', 'Confirm stop',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
        foreach ($p in $running) {
            Stop-Process -Id $p.ProcessId -Force
        }
    }
}

function Get-ApprovalsAndStepsText {
    @"
Approvals and Operating Steps

Approval Gates
  A1. Start/resume hashing: app verifies scripts, manifest, free space, and process state.
  A2. Move confirmed older duplicates: requires explicit approval after duplicate review.
  A3. Retry failed files: user decides retry vs defer.
  A4. Prepare next batch: safe metadata/report step; no files are moved.
  A5. Organization moves: require reviewed folder map and explicit approval.

Standard Batch Steps
  1. Refresh inventory.
  2. Exclude already handled files and _older_duplicates.
  3. Preserve package/application/container folders.
  4. Group same extension and exact byte size.
  5. Process small/medium non-media first; defer large media.
  6. Prepare manifest.
  7. Hash in controlled slices.
  8. Generate duplicate review from SHA256 matches.
  9. Request approval before moving older duplicates.
 10. Move approved older duplicates into nearby _older_duplicates.
 11. Verify destinations, old source paths, and main copies.

Never Automatic
  - Do not delete files.
  - Do not move non-duplicates without an approved organization plan.
  - Do not split package folders, app folders, licenses, metadata, or readme files.
  - Do not move main/newest duplicate copies.
  - Do not publish raw inventories, logs, hashes, or sensitive filenames.

Self-Service TODO
  - Generate Duplicate Review button.
  - Review Pending Moves screen.
  - Approve and Move Selected Duplicates button.
  - Post-move verification screen.
  - Retry Errors manifest generator.
  - Merge Retry Results button.
  - Organization planning screen.
"@
}

function Show-ApprovalsAndSteps {
    $stepsForm = New-Object System.Windows.Forms.Form
    $stepsForm.Text = 'Approvals and Steps'
    $stepsForm.Size = New-Object System.Drawing.Size(760, 620)
    $stepsForm.StartPosition = 'CenterParent'
    $stepsForm.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $stepsBox = New-Object System.Windows.Forms.TextBox
    $stepsBox.Location = New-Object System.Drawing.Point(16, 16)
    $stepsBox.Size = New-Object System.Drawing.Size(710, 520)
    $stepsBox.Multiline = $true
    $stepsBox.ScrollBars = 'Vertical'
    $stepsBox.ReadOnly = $true
    $stepsBox.Font = New-Object System.Drawing.Font('Consolas', 10)
    $stepsBox.Text = Get-ApprovalsAndStepsText
    $stepsForm.Controls.Add($stepsBox)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = 'Close'
    $closeButton.Location = New-Object System.Drawing.Point(16, 552)
    $closeButton.Size = New-Object System.Drawing.Size(110, 36)
    $closeButton.Add_Click({ $stepsForm.Close() })
    $stepsForm.Controls.Add($closeButton)

    [void]$stepsForm.ShowDialog($form)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'File Organization Toolkit Control'
$form.Size = New-Object System.Drawing.Size(980, 560)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = Get-ActiveTaskName
$title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(16, 14)
$title.Size = New-Object System.Drawing.Size(520, 34)
$form.Controls.Add($title)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 60)
$statusLabel.Size = New-Object System.Drawing.Size(920, 30)
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($statusLabel)

$details = New-Object System.Windows.Forms.Label
$details.Location = New-Object System.Drawing.Point(20, 100)
$details.Size = New-Object System.Drawing.Size(920, 120)
$details.BorderStyle = 'FixedSingle'
$details.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($details)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Location = New-Object System.Drawing.Point(20, 226)
$progressLabel.Size = New-Object System.Drawing.Size(350, 22)
$form.Controls.Add($progressLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 250)
$progressBar.Size = New-Object System.Drawing.Size(920, 22)
$progressBar.Maximum = 100
$form.Controls.Add($progressBar)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = 'Start / Resume'
$startButton.Location = New-Object System.Drawing.Point(20, 286)
$startButton.Size = New-Object System.Drawing.Size(135, 42)
$startButton.Add_Click({ Start-Task; Start-Sleep -Seconds 1; Update-Status })
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = 'Stop'
$stopButton.Location = New-Object System.Drawing.Point(168, 286)
$stopButton.Size = New-Object System.Drawing.Size(95, 42)
$stopButton.Add_Click({ Stop-Task; Start-Sleep -Seconds 1; Update-Status })
$form.Controls.Add($stopButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = 'Refresh'
$refreshButton.Location = New-Object System.Drawing.Point(276, 286)
$refreshButton.Size = New-Object System.Drawing.Size(95, 42)
$refreshButton.Add_Click({ Update-Status })
$form.Controls.Add($refreshButton)

$stepsButton = New-Object System.Windows.Forms.Button
$stepsButton.Text = 'Approvals && Steps'
$stepsButton.Location = New-Object System.Drawing.Point(384, 286)
$stepsButton.Size = New-Object System.Drawing.Size(145, 42)
$stepsButton.Add_Click({ Show-ApprovalsAndSteps })
$form.Controls.Add($stepsButton)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 350)
$logBox.Size = New-Object System.Drawing.Size(920, 150)
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($logBox)

function Update-Status {
    $title.Text = Get-ActiveTaskName
    $running = @(Get-RunnerProcesses)
    $counts = Get-Counts
    $free = Get-FreeGB
    $pct = if ($counts.Total -gt 0) { [math]::Round(($counts.Done / $counts.Total) * 100) } else { 0 }

    $statusLabel.Text = if ($running.Count -gt 0) { "Running - process $($running[0].ProcessId)" } else { 'Not running' }
    $statusLabel.ForeColor = if ($running.Count -gt 0) { [System.Drawing.Color]::DarkGreen } else { [System.Drawing.Color]::DarkRed }
    $startButton.Enabled = ($running.Count -eq 0)
    $stopButton.Enabled = ($running.Count -gt 0)
    $progressBar.Value = [int]([math]::Min(100, [math]::Max(0, $pct)))
    $progressLabel.Text = "Current task progress: $($counts.Done) / $($counts.Total) ($pct%)"
    $last = if ($counts.OutputLastWrite) { $counts.OutputLastWrite.ToString('yyyy-MM-dd HH:mm:ss') } else { 'not created yet' }
    $details.Text = "Task files: $($counts.Total)`r`nProcessed: $($counts.Done)    Hashed: $($counts.Hashed)    Errors: $($counts.Errors)    Remaining: $($counts.Remaining)`r`nFree space: $free GB    Safety stop: $($Config.MinFreeGB) GB`r`nLast checked: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))    Last result update: $last"
    $logBox.Text = Get-LastLog
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 10000
$timer.Add_Tick({ Update-Status })
$timer.Start()

$form.Add_Shown({ Update-Status })
[void]$form.ShowDialog()
