# Windows twin of ~/.local/bin/godot-update: installs or updates the latest
# stable Godot (standard + .NET) into %LOCALAPPDATA%\Programs\Godot and keeps
# only the current version. Windows can't do the symlink trick the Linux
# script uses, so stable entry points are rewritten on every update instead:
# godot.cmd / godotnet.cmd shims in this bin dir (put on the user PATH below),
# Start Menu shortcuts, and GODOT_PATH / GODOT_NET_PATH user env vars.
#
# Usage: godot-update [-Force]
#   -Force  reinstall even if the latest version is already installed
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue' # Invoke-WebRequest is very slow with the progress bar

$libDir = Join-Path $env:LOCALAPPDATA 'Programs\Godot'
$binDir = Join-Path $libDir 'bin'
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

Write-Host '==> Checking latest stable Godot release'
# The /releases/latest redirect ends in the tag name; this avoids parsing the
# GitHub API (rate-limited).
$req = [Net.WebRequest]::Create('https://github.com/godotengine/godot-builds/releases/latest')
$req.Method = 'HEAD'
$resp = $req.GetResponse()
$tag = $resp.ResponseUri.AbsoluteUri.TrimEnd('/').Split('/')[-1]
$resp.Close()
if ($tag -notlike '*-stable') {
    throw "could not determine the latest Godot release (got '$tag')"
}

$versionFile = Join-Path $libDir 'VERSION'
$current = if (Test-Path $versionFile) { Get-Content $versionFile -First 1 } else { '' }
if ($tag -eq $current -and -not $Force -and (Test-Path (Join-Path $binDir 'godot.cmd'))) {
    Write-Host "Godot $tag is already installed."
    exit 0
}

Write-Host "==> Installing Godot $tag"
$base = "https://github.com/godotengine/godot-builds/releases/download/$tag"
$stdZip = "Godot_v${tag}_win64.exe.zip"
$netZip = "Godot_v${tag}_mono_win64.zip"
$tmp = Join-Path $env:TEMP "godot-update-$PID"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$dest = Join-Path $libDir $tag
try {
    Invoke-WebRequest "$base/$stdZip" -OutFile (Join-Path $tmp $stdZip)
    Invoke-WebRequest "$base/$netZip" -OutFile (Join-Path $tmp $netZip)

    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Expand-Archive (Join-Path $tmp $stdZip) -DestinationPath $dest
    Expand-Archive (Join-Path $tmp $netZip) -DestinationPath $dest
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

$stdExe = Join-Path $dest "Godot_v${tag}_win64.exe"
$netExe = Join-Path $dest "Godot_v${tag}_mono_win64\Godot_v${tag}_mono_win64.exe"
# _console variants attach to the calling terminal, so godot/godotnet in a
# shell behave like the Linux binaries (stdout, exit codes)
$stdConsole = $stdExe -replace '\.exe$', '_console.exe'
$netConsole = $netExe -replace '\.exe$', '_console.exe'
foreach ($exe in $stdExe, $netExe, $stdConsole, $netConsole) {
    if (-not (Test-Path $exe)) { throw "expected binary not found after extraction: $exe" }
}

# Stable entry points (rewritten each update)
Set-Content -Path (Join-Path $binDir 'godot.cmd') -Value "@`"$stdConsole`" %*" -Encoding Ascii
Set-Content -Path (Join-Path $binDir 'godotnet.cmd') -Value "@`"$netConsole`" %*" -Encoding Ascii
[Environment]::SetEnvironmentVariable('GODOT_PATH', $stdExe, 'User')
[Environment]::SetEnvironmentVariable('GODOT_NET_PATH', $netExe, 'User')

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $binDir) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$binDir", 'User')
    Write-Host "Added $binDir to the user PATH (open a new terminal to pick it up)."
}

# Start Menu entries (the .desktop-file equivalent on Linux)
$shell = New-Object -ComObject WScript.Shell
$programs = [Environment]::GetFolderPath('Programs')
foreach ($item in @(@('Godot.lnk', $stdExe), @('Godot .NET.lnk', $netExe))) {
    $lnk = $shell.CreateShortcut((Join-Path $programs $item[0]))
    $lnk.TargetPath = $item[1]
    $lnk.Save()
}

# Remove previous versions — only the current one is kept
Get-ChildItem $libDir -Directory | Where-Object { $_.FullName -ne $dest -and $_.FullName -ne $binDir } |
    Remove-Item -Recurse -Force
Set-Content -Path $versionFile -Value $tag

# Godot reads editor_settings-<major.minor>.tres and starts fresh if it's
# missing. Link this version's filename to the newest existing settings file
# so the chezmoi-managed settings carry forward across Godot versions.
# (%APPDATA%\Godot is the chezmoi symlink into ~\.config\godot)
$minor = (($tag -replace '-stable$', '') -split '\.')[0..1] -join '.'
$godotCfg = Join-Path $env:APPDATA 'Godot'
$target = Join-Path $godotCfg "editor_settings-$minor.tres"
if ((Test-Path $godotCfg) -and -not (Test-Path $target)) {
    $newest = Get-ChildItem $godotCfg -Filter 'editor_settings-*.tres' |
        Sort-Object { [version](($_.BaseName -replace '^editor_settings-', '') + '.0') } |
        Select-Object -Last 1
    if ($newest) {
        try {
            New-Item -ItemType SymbolicLink -Path $target -Target $newest.Name | Out-Null
            Write-Host "Linked editor_settings-$minor.tres -> $($newest.Name)"
        } catch {
            # symlinks need Developer Mode / elevation; a copy still works
            Copy-Item $newest.FullName $target
            Write-Host "Copied $($newest.Name) -> editor_settings-$minor.tres (no symlink permission)"
        }
    }
}

Write-Host "Godot $tag installed. Run with: godot / godotnet"
