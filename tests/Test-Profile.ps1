#Requires -Version 7.0
<#
.SYNOPSIS
    Guards ordering constraints in the shipped PowerShell profile.

.DESCRIPTION
    These are failures that produce no error message - the shell starts fine and
    a feature is just silently missing - so they are easy to reintroduce while
    tidying the profile. Each assertion below corresponds to a bug that actually
    happened.

.EXAMPLE
    .\tests\Test-Profile.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo    = Split-Path $PSScriptRoot -Parent
$profile = Join-Path $repo 'config\Microsoft.PowerShell_profile.ps1'
$lines   = Get-Content $profile

$pass = 0; $fail = 0
function Check {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')
    if ($Condition) { Write-Host "  PASS  $Name" -ForegroundColor Green; $script:pass++ }
    else            { Write-Host "  FAIL  $Name  $Detail" -ForegroundColor Red;  $script:fail++ }
}

function Find-Line {
    param([string]$Pattern)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $Pattern -and $lines[$i] -notmatch '^\s*#') { return $i + 1 }
    }
    return -1
}

Write-Host "`nProfile ordering`n" -ForegroundColor Cyan

$editMode = Find-Line 'Set-PSReadLineOption\s+-EditMode'
$ompInit  = Find-Line 'oh-my-posh\s+init'

Check 'EditMode is set somewhere'        ($editMode -gt 0) "not found"
Check 'oh-my-posh init is present'       ($ompInit  -gt 0) "not found"

# Set-PSReadLineOption -EditMode resets every key handler to that mode's
# defaults, discarding the Enter handler oh-my-posh binds for the transient
# prompt. Init must come after, or transient prompt silently stops working.
Check 'EditMode precedes oh-my-posh init' ($editMode -gt 0 -and $ompInit -gt 0 -and $editMode -lt $ompInit) `
      "EditMode on line $editMode, init on line $ompInit"

Write-Host "`nProfile hygiene`n" -ForegroundColor Cyan

Check 'no hardcoded user paths' (-not ($lines -match 'C:\\Users\\[^\\$]')) `
      "profile must stay portable - use `$HOME"

# Aliasing cat to bat breaks `cat file | Select-String` because Get-Content
# emits objects and bat emits formatted strings.
Check 'cat is not aliased to bat' (-not ($lines -match '(Set-Alias|New-Alias).*\bcat\b')) ''

# Predictions throw "The handle is invalid" when stdout is redirected.
Check 'predictions guarded on redirected output' ([bool]($lines -match 'IsOutputRedirected')) ''

$e = $null
[System.Management.Automation.Language.Parser]::ParseFile($profile, [ref]$null, [ref]$e) | Out-Null
Check 'profile parses cleanly' (-not $e) $(if ($e) { $e[0].Message })

Write-Host "`n  $pass passed, $fail failed`n" -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })
if ($fail) { exit 1 }
