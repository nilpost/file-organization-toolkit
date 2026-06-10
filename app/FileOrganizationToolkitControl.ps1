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
    ActiveTaskName = 'Current File Organization Task'
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

$form = New-Object System.Windows.Forms.Form
$form.Text = 'File Organization Toolkit Control'
$form.Size = New-Object System.Drawing.Size(820, 560)
$form.StartPosition = 'CenterScreen'
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = $Config.ActiveTaskName
$title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(16, 14)
$title.Size = New-Object System.Drawing.Size(520, 34)
$form.Controls.Add($title)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 60)
$statusLabel.Size = New-Object System.Drawing.Size(760, 30)
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($statusLabel)

$details = New-Object System.Windows.Forms.Label
$details.Location = New-Object System.Drawing.Point(20, 100)
$details.Size = New-Object System.Drawing.Size(760, 120)
$details.BorderStyle = 'FixedSingle'
$details.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($details)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Location = New-Object System.Drawing.Point(20, 226)
$progressLabel.Size = New-Object System.Drawing.Size(350, 22)
$form.Controls.Add($progressLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 250)
$progressBar.Size = New-Object System.Drawing.Size(760, 22)
$progressBar.Maximum = 100
$form.Controls.Add($progressBar)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = 'Start / Resume'
$startButton.Location = New-Object System.Drawing.Point(20, 286)
$startButton.Size = New-Object System.Drawing.Size(150, 42)
$startButton.Add_Click({ Start-Task; Start-Sleep -Seconds 1; Update-Status })
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = 'Stop'
$stopButton.Location = New-Object System.Drawing.Point(184, 286)
$stopButton.Size = New-Object System.Drawing.Size(110, 42)
$stopButton.Add_Click({ Stop-Task; Start-Sleep -Seconds 1; Update-Status })
$form.Controls.Add($stopButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = 'Refresh'
$refreshButton.Location = New-Object System.Drawing.Point(308, 286)
$refreshButton.Size = New-Object System.Drawing.Size(110, 42)
$refreshButton.Add_Click({ Update-Status })
$form.Controls.Add($refreshButton)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(20, 350)
$logBox.Size = New-Object System.Drawing.Size(760, 150)
$logBox.Multiline = $true
$logBox.ScrollBars = 'Vertical'
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font('Consolas', 9)
$form.Controls.Add($logBox)

function Update-Status {
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

