# Windows setup — run this ON WINDOWS in PowerShell (NOT inside WSL).
# It self-elevates if not run as administrator.
#
#   powershell -ExecutionPolicy Bypass -File \\wsl.localhost\<distro>\home\<user>\.local\share\chezmoi\windows\setup.ps1
#
# (or from WSL, use the `windows-setup` alias)
#
# Idempotent: safe to re-run after editing choco-packages.txt or hotkeys.ahk.

$ErrorActionPreference = 'Stop'

# --- Self-elevate ------------------------------------------------------------
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Not running as administrator - relaunching elevated...'
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`""
    )
    exit
}

# --- Chocolatey --------------------------------------------------------------
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host '==> Installing Chocolatey'
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    $env:PATH = "$env:ProgramData\chocolatey\bin;$env:PATH"
}

Write-Host '==> Installing Chocolatey packages'
$packages = Get-Content (Join-Path $PSScriptRoot 'choco-packages.txt') |
    ForEach-Object { ($_ -split '#')[0].Trim() } |
    Where-Object { $_ }
choco install -y @packages

# --- AutoHotkey hotkeys ------------------------------------------------------
# Copy (not link): \\wsl.localhost isn't mounted until WSL starts, so a
# startup shortcut into the repo would silently fail at login.
Write-Host '==> Installing AutoHotkey hotkeys'
$hotkeyDir = Join-Path $env:LOCALAPPDATA 'hotkeys'
New-Item -ItemType Directory -Force -Path $hotkeyDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'hotkeys.ahk') (Join-Path $hotkeyDir 'hotkeys.ahk') -Force

$startup = [Environment]::GetFolderPath('Startup')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $startup 'hotkeys.lnk'))
$shortcut.TargetPath = (Join-Path $hotkeyDir 'hotkeys.ahk')
$shortcut.Save()

# Launch now so hotkeys work without relogging (requires AutoHotkey installed)
try {
    Start-Process (Join-Path $hotkeyDir 'hotkeys.ahk')
} catch {
    Write-Warning 'Could not launch hotkeys.ahk - it will start at next login.'
}

# --- Windows Terminal: quake mode on Ctrl+\ ----------------------------------
Write-Host '==> Configuring Windows Terminal quake hotkey (Ctrl+\)'
$wtSettings = Get-ChildItem "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($wtSettings) {
    $json = Get-Content $wtSettings.FullName -Raw | ConvertFrom-Json
    $binding = [pscustomobject]@{
        keys    = 'ctrl+\'
        command = [pscustomobject]@{ action = 'quakeMode' }
    }
    if (-not $json.PSObject.Properties['actions']) {
        $json | Add-Member -NotePropertyName actions -NotePropertyValue @()
    }
    # Drop any existing ctrl+\ binding, then add ours
    $json.actions = @($json.actions | Where-Object { $_.keys -ne 'ctrl+\' }) + $binding
    # Newer Windows Terminal splits keys into a "keybindings" array; drop any
    # conflicting ctrl+\ entry there too.
    if ($json.PSObject.Properties['keybindings']) {
        $json.keybindings = @($json.keybindings | Where-Object { $_.keys -ne 'ctrl+\' })
    }
    Copy-Item $wtSettings.FullName "$($wtSettings.FullName).bak" -Force
    $json | ConvertTo-Json -Depth 100 | Set-Content $wtSettings.FullName -Encoding UTF8
    Write-Host 'Ctrl+\ now toggles the quake terminal (backup saved as settings.json.bak).'
} else {
    Write-Warning 'Windows Terminal settings.json not found - open Windows Terminal once, then re-run.'
}

Write-Host ''
Write-Host 'Windows setup complete.'
