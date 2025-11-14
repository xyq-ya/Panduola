<#
.\scripts\start_all.ps1
One-shot starter for Panduola (Windows PowerShell).

Usage examples:
  # Start with mock backend, don't install deps
  .\scripts\start_all.ps1 -Mock

  # Start with real backend (use ARK env), install python deps if missing
  .\scripts\start_all.ps1 -InstallDeps -ArkKey 'YOUR_KEY' -ArkBaseUrl 'https://ark.cn-beijing.volces.com/api/v3'

What it does:
 - Optionally installs python deps from flask/requirements.txt
 - Sets environment variables for the current session (ARK_API_KEY, ARK_BASE_URL, MOCK_BACKEND)
 - Starts Flask backend in background and waits for port 5000 to be ready
 - Runs `flutter run -d windows` in the foreground (so you can see logs and use hot reload)
 - When Flutter process exits, stops the background Flask process started by this script

Notes:
 - This script modifies env vars only for the current PowerShell session.
 - It does not write secrets to disk or to the repository.
 - Requires PowerShell running with enough rights to start/stop processes.
#>

param(
    [switch]$Mock,
    [switch]$InstallDeps,
    [string]$ArkKey,
    [string]$ArkBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3'
)

function Write-Log($m){ Write-Host "[start_all] $m" }

Push-Location $PSScriptRoot\..\

if ($InstallDeps) {
    Write-Log 'Installing Python requirements for backend (flask/requirements.txt)...'
    python -m pip install -r .\flask\requirements.txt
}

if ($Mock) {
    Write-Log 'Enabling MOCK_BACKEND for this session'
    $env:MOCK_BACKEND = '1'
} else {
    Remove-Item Env:MOCK_BACKEND -ErrorAction SilentlyContinue
}

if ($ArkKey) {
    Write-Log 'Setting ARK_API_KEY for this session (will NOT be saved)'
    $env:ARK_API_KEY = $ArkKey
    $env:ARK_BASE_URL = $ArkBaseUrl
}

# Ensure flask app will bind to 127.0.0.1:5000
Write-Log 'Starting Flask backend (in background)...'

$pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonExe) { Write-Error 'python not found in PATH'; Pop-Location; exit 2 }

$startInfo = Start-Process -FilePath python -ArgumentList '.\flask\app.py' -PassThru
$flaskPid = $startInfo.Id
Write-Log "Flask started (pid=$flaskPid)"

Write-Log 'Waiting for http://127.0.0.1:5000 to be available...'
while (-not (Test-NetConnection -ComputerName 127.0.0.1 -Port 5000).TcpTestSucceeded) {
    Start-Sleep -Seconds 1
}
Write-Log 'Backend appears ready.'

try {
    Write-Log 'Starting Flutter (this runs in the foreground). Use r for hot reload or q to quit.'
    flutter run -d windows
} finally {
    Write-Log 'Flutter exited; stopping Flask backend started by this script.'
    try { Stop-Process -Id $flaskPid -Force -ErrorAction SilentlyContinue } catch {}
    Pop-Location
}
