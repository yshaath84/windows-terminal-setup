#Requires -Version 7.0
<#
.SYNOPSIS
    Verifies install.ps1 merges into Windows Terminal settings without
    destroying anything the user already had.

.DESCRIPTION
    Builds a synthetic settings.json describing a machine this repo has never
    seen — a WSL distro, a hand-written profile, a different colour scheme, a
    custom keybinding — merges into it, and asserts every one of those survives.

    Touches nothing outside this directory: all other install steps are skipped.

.EXAMPLE
    .\tests\Test-Merge.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$tmp  = Join-Path $PSScriptRoot 'fake-settings.json'

$fake = [ordered]@{
    '$schema'      = 'https://aka.ms/terminal-profiles-schema'
    defaultProfile = '{aaaaaaaa-1111-1111-1111-111111111111}'
    copyOnSelect   = $true
    theme          = 'light'
    profiles = [ordered]@{
        defaults = [ordered]@{ font = [ordered]@{ face = 'Cascadia Code'; size = 14 } }
        list = @(
            [ordered]@{ name = 'PowerShell';     guid = '{aaaaaaaa-1111-1111-1111-111111111111}'; commandline = 'pwsh.exe' }
            [ordered]@{ name = 'Ubuntu';         guid = '{bbbbbbbb-2222-2222-2222-222222222222}'; source = 'Windows.Terminal.Wsl' }
            [ordered]@{ name = 'My Custom Prof'; guid = '{cccccccc-3333-3333-3333-333333333333}'; commandline = 'cmd.exe' }
        )
    }
    schemes     = @( [ordered]@{ name = 'Campbell'; background = '#0C0C0C'; foreground = '#CCCCCC' } )
    keybindings = @( [ordered]@{ keys = 'ctrl+shift+p'; command = 'commandPalette' } )
    actions     = @()
}
$fake | ConvertTo-Json -Depth 20 | Set-Content $tmp -Encoding utf8

$installArgs = @(
    '-SkipTools', '-SkipFont', '-SkipOhMyPosh', '-SkipProfile', '-SkipGit'
    '-WindowsTerminalSettings', $tmp
)
& pwsh -NoProfile -File (Join-Path $repo 'install.ps1') @installArgs | Out-Null
$r = Get-Content $tmp -Raw | ConvertFrom-Json

$pass = 0; $fail = 0
function Check {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) { Write-Host "  PASS  $Name" -ForegroundColor Green; $script:pass++ }
    else            { Write-Host "  FAIL  $Name  $Detail" -ForegroundColor Red;  $script:fail++ }
}

Write-Host "`nMerge safety`n" -ForegroundColor Cyan
Check 'all 3 original profiles survive'  ($r.profiles.list.Count -eq 3) "got $($r.profiles.list.Count)"
Check 'WSL Ubuntu profile survives'      ([bool]($r.profiles.list | Where-Object name -eq 'Ubuntu'))
Check 'hand-written profile survives'    ([bool]($r.profiles.list | Where-Object name -eq 'My Custom Prof'))
Check 'their Campbell scheme kept'       ([bool]($r.schemes | Where-Object name -eq 'Campbell'))
Check 'their ctrl+shift+p kept'          ([bool]($r.keybindings | Where-Object keys -eq 'ctrl+shift+p'))
Check 'backup written'                   ([bool](Get-ChildItem $PSScriptRoot -Filter 'fake-settings.json.bak-*'))

Write-Host "`nSettings applied`n" -ForegroundColor Cyan
Check 'Tokyo Night scheme added'         ([bool]($r.schemes | Where-Object name -eq 'Tokyo Night'))
Check 'our keybindings added'            ($r.keybindings.Count -gt 1) "count $($r.keybindings.Count)"
Check 'font set to JetBrainsMono NFM'    ($r.profiles.defaults.font.face -eq 'JetBrainsMono NFM') "got $($r.profiles.defaults.font.face)"
Check 'theme set to tokyonight'          ($r.theme -eq 'tokyonight') "got $($r.theme)"
Check 'opacity applied'                  ($r.profiles.defaults.opacity -eq 92)
$dupes = $r.keybindings | Group-Object keys | Where-Object Count -gt 1
Check 'no duplicate keybindings'         ($dupes.Count -eq 0) "$($dupes.Name -join ', ')"
# Must resolve to THEIR pwsh guid: profile GUIDs differ per machine and install source.
Check 'defaultProfile = their pwsh guid' ($r.defaultProfile -eq '{aaaaaaaa-1111-1111-1111-111111111111}') "got $($r.defaultProfile)"

Write-Host "`nIdempotency`n" -ForegroundColor Cyan
& pwsh -NoProfile -File (Join-Path $repo 'install.ps1') @installArgs | Out-Null
$r2 = Get-Content $tmp -Raw | ConvertFrom-Json
Check 'profile count stable'     ($r2.profiles.list.Count -eq $r.profiles.list.Count)
Check 'scheme count stable'      ($r2.schemes.Count      -eq $r.schemes.Count)
Check 'keybinding count stable'  ($r2.keybindings.Count  -eq $r.keybindings.Count)

Remove-Item $tmp, (Join-Path $PSScriptRoot 'fake-settings.json.bak-*') -Force -ErrorAction SilentlyContinue

Write-Host "`n  $pass passed, $fail failed`n" -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })
if ($fail) { exit 1 }
