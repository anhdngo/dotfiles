# Makes Windows Terminal the default terminal application, so console programs
# (cmd.exe, powershell.exe, the hotkeys) open in it instead of the legacy
# conhost window. Same as Settings > Startup > Default terminal application in
# the Terminal UI. Per-user, no admin. Windows 11 only - on Windows 10 the
# delegation feature doesn't exist and these values are ignored.
$ErrorActionPreference = 'Stop'

# Windows Terminal's delegation GUIDs (fixed, documented by microsoft/terminal)
$key = 'HKCU:\Console\%%Startup'
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name DelegationConsole  -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
Set-ItemProperty -Path $key -Name DelegationTerminal -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
Write-Host 'Windows Terminal set as the default terminal application.'
