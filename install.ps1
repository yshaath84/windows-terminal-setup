#Requires -Version 7.0
<#
.SYNOPSIS
    Installs the Tokyo Night Windows Terminal + PowerShell setup.

.DESCRIPTION
    Idempotent: safe to run repeatedly. Every file it overwrites is backed up
    first with a timestamped suffix.

    What it does NOT do, deliberately:
      * never writes git user.name / user.email
      * never replaces your Windows Terminal profile list
      * never installs oh-my-posh from winget (see -SkipOhMyPosh notes below)

.PARAMETER SkipTools
    Skip the winget package installs. Use if you already have the CLI tools.

.PARAMETER SkipFont
    Skip the Nerd Font install. The prompt renders as boxes without one.

.PARAMETER WindowsTerminalSettings
    Override the settings.json to merge into. Normally auto-detected; used by
    the test suite to merge against a throwaway copy.

.PARAMETER WhatIf
    Show what would change without writing anything.

.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -SkipTools -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SkipTools,
    [switch]$SkipFont,
    [switch]$SkipOhMyPosh,
    [switch]$SkipProfile,
    [switch]$SkipGit,
    [string]$WindowsTerminalSettings
)

$ErrorActionPreference = 'Stop'
$repo  = $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Write-Step { param($m) Write-Host "`n=== $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Write-Info { param($m) Write-Host "  $m" -ForegroundColor DarkGray }

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $bak = "$Path.bak-$stamp"
        Copy-Item $Path $bak -Force
        Write-Info "backed up -> $(Split-Path $bak -Leaf)"
    }
}

# ── Preflight ────────────────────────────────────────────────────────────────
Write-Step 'Preflight'

if (-not $IsWindows) { throw 'This setup is Windows-only.' }
Write-Ok "PowerShell $($PSVersionTable.PSVersion)"

$hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
if (-not $hasWinget -and -not $SkipTools) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, or re-run with -SkipTools.'
}

# ── 1. CLI tools ─────────────────────────────────────────────────────────────
# Each of these backs a command the profile defines. The profile probes with
# Get-Command and degrades gracefully, so a failed install is not fatal.
$packages = @(
    @{ Id = 'junegunn.fzf';               Gives = 'fzf     (Ctrl+R / Ctrl+T)' }
    @{ Id = 'ajeetdsouza.zoxide';         Gives = 'zoxide  (z / zi)'          }
    @{ Id = 'eza-community.eza';          Gives = 'eza     (ls / ll / la / lt)' }
    @{ Id = 'sharkdp.bat';                Gives = 'bat'                        }
    @{ Id = 'BurntSushi.ripgrep.MSVC';    Gives = 'rg      (grep)'             }
    @{ Id = 'sharkdp.fd';                 Gives = 'fd'                         }
    @{ Id = 'dandavison.delta';           Gives = 'delta   (git pager)'        }
    @{ Id = 'JesseDuffield.lazygit';      Gives = 'lazygit (lg)'               }
)

if ($SkipTools) {
    Write-Step 'CLI tools (skipped)'
} else {
    Write-Step "CLI tools ($($packages.Count) packages)"
    foreach ($p in $packages) {
        if ($PSCmdlet.ShouldProcess($p.Id, 'winget install')) {
            # --accept-*-agreements keeps this non-interactive; exit code 0x8A15002B
            # means "already installed", which is success for our purposes.
            winget install --id $p.Id --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Ok $p.Gives }
            else { Write-Info "already present or unavailable: $($p.Id)" }
        }
    }
}

# ── 2. Nerd Font ─────────────────────────────────────────────────────────────
if ($SkipFont) {
    Write-Step 'Nerd Font (skipped)'
} else {
    Write-Step 'JetBrainsMono Nerd Font'
    if ($PSCmdlet.ShouldProcess('DEVCOM.JetBrainsMonoNerdFont', 'winget install')) {
        winget install --id DEVCOM.JetBrainsMonoNerdFont --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        Write-Ok 'JetBrainsMono NFM'
        Write-Info 'Without a Nerd Font the prompt renders as empty boxes.'
    }
}

# ── 3. oh-my-posh — native binary, NOT winget ────────────────────────────────
# This is the single most important decision in the whole setup.
#
# The winget/Store package installs oh-my-posh as an MSIX, which means
# oh-my-posh.exe is not a real binary: it is an app-execution-alias stub that
# Windows resolves through the app-container layer on every launch. The prompt
# binary runs once per Enter keypress, so that indirection is paid constantly.
#
# Measured on the reference machine: 262 ms per prompt via MSIX vs 133 ms via
# the standalone binary. Same theme, identical appearance, ~2x faster.
Write-Step 'oh-my-posh (standalone binary)'

$ompDir = Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\bin'
$ompExe = Join-Path $ompDir 'oh-my-posh.exe'

if ($SkipOhMyPosh) {
    Write-Info 'skipped'
} elseif ($PSCmdlet.ShouldProcess($ompExe, 'download')) {
    # An MSIX install shadows the real binary on PATH. Remove it first.
    $msix = Get-AppxPackage -Name 'JanDeDobbeleer.OhMyPosh' -ErrorAction SilentlyContinue
    if ($msix) {
        Write-Warn 'Removing the MSIX oh-my-posh package (it is the slow one).'
        $msix | Remove-AppxPackage
    }

    New-Item -ItemType Directory -Force -Path $ompDir | Out-Null
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -UseBasicParsing -OutFile $ompExe `
            'https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe'
        Write-Ok "installed -> $ompExe"
    } catch {
        # The running binary is locked while any shell is using it.
        Write-Warn "Download failed: $($_.Exception.Message)"
        Write-Warn 'If it is locked, close every other terminal and re-run.'
    }

    # Prepend to the *user* PATH so it wins over any leftover stub.
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($userPath -notlike "*$ompDir*") {
        [Environment]::SetEnvironmentVariable('Path', "$ompDir;$userPath", 'User')
        Write-Ok 'prepended to user PATH'
    } else {
        Write-Info 'already on user PATH'
    }
    $env:Path = "$ompDir;$env:Path"
}

# ── 4. Prompt theme ──────────────────────────────────────────────────────────
Write-Step 'Prompt theme'

$themeDir = Join-Path $HOME '.config\oh-my-posh'
$themeDst = Join-Path $themeDir 'tokyonight.omp.json'

if ($SkipOhMyPosh) {
    Write-Info 'skipped'
} elseif ($PSCmdlet.ShouldProcess($themeDst, 'deploy theme')) {
    New-Item -ItemType Directory -Force -Path $themeDir | Out-Null
    Backup-File $themeDst
    Copy-Item (Join-Path $repo 'config\tokyonight.omp.json') $themeDst -Force
    Write-Ok $themeDst

    # oh-my-posh caches the parsed config. Without this, edits to the theme are
    # silently ignored and you debug the wrong thing.
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh cache clear 2>&1 | Out-Null
        Write-Info 'cleared oh-my-posh config cache'
    }
}

# ── 5. PowerShell profile ────────────────────────────────────────────────────
# Ask pwsh itself where its profile goes rather than assuming
# ~\Documents\PowerShell. Windows often redirects Documents into OneDrive, and
# hardcoding the literal path silently writes to a file that is never loaded.
Write-Step 'PowerShell profile'

$profilePath = & pwsh -NoProfile -NoLogo -Command '$PROFILE.CurrentUserCurrentHost'
if (-not $profilePath) { $profilePath = $PROFILE.CurrentUserCurrentHost }

if ($SkipProfile) {
    Write-Info 'skipped'
} elseif ($PSCmdlet.ShouldProcess($profilePath, 'deploy profile')) {
    New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null
    Backup-File $profilePath
    Copy-Item (Join-Path $repo 'config\Microsoft.PowerShell_profile.ps1') $profilePath -Force
    Write-Ok $profilePath
}

# ── 6. Windows Terminal settings (merge, never overwrite) ────────────────────
Write-Step 'Windows Terminal settings'

$wtCandidates = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
)
$wtPath = if ($WindowsTerminalSettings) { $WindowsTerminalSettings }
          else { $wtCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1 }

if (-not $wtPath) {
    Write-Warn 'Windows Terminal settings.json not found - skipping.'
    Write-Info 'Launch Windows Terminal once to create it, then re-run.'
} elseif ($PSCmdlet.ShouldProcess($wtPath, 'merge settings')) {

    $live    = Get-Content $wtPath -Raw | ConvertFrom-Json
    $partial = Get-Content (Join-Path $repo 'config\windows-terminal.partial.json') -Raw | ConvertFrom-Json

    Backup-File $wtPath

    # Merge named collections by name: ours replaces a same-named entry,
    # everything else the user has is left alone.
    function Merge-ByKey {
        param($Existing, $Incoming, [string]$Key)
        $out = [System.Collections.Generic.List[object]]::new()
        foreach ($e in @($Existing)) { if ($e) { $out.Add($e) } }
        foreach ($i in @($Incoming)) {
            if (-not $i) { continue }
            $match = $out | Where-Object { $_.$Key -eq $i.$Key } | Select-Object -First 1
            if ($match) { $out[$out.IndexOf($match)] = $i } else { $out.Add($i) }
        }
        , $out.ToArray()
    }

    # Scalars and appearance
    foreach ($k in 'copyFormatting','copyOnSelect','theme','useAcrylicInTabRow',
                   'showTabsInTitlebar','tabWidthMode','alwaysShowTabs','snapToGridOnResize') {
        $live | Add-Member -NotePropertyName $k -NotePropertyValue $partial.$k -Force
    }

    # profiles.defaults only. profiles.list is untouched on purpose: it holds
    # GUIDs for profiles that exist on this machine and not on ours (VS
    # developer prompts, WSL distros, Azure Cloud Shell). Copying it across
    # machines deletes profiles people actually use.
    if (-not $live.profiles) { $live | Add-Member -NotePropertyName profiles -NotePropertyValue ([pscustomobject]@{}) -Force }
    $live.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue $partial.profiles.defaults -Force

    $live | Add-Member -NotePropertyName schemes     -NotePropertyValue (Merge-ByKey $live.schemes     $partial.schemes     'name') -Force
    $live | Add-Member -NotePropertyName themes      -NotePropertyValue (Merge-ByKey $live.themes      $partial.themes      'name') -Force
    $live | Add-Member -NotePropertyName keybindings -NotePropertyValue (Merge-ByKey $live.keybindings $partial.keybindings 'keys') -Force
    $live | Add-Member -NotePropertyName actions     -NotePropertyValue (Merge-ByKey $live.actions     $partial.actions     'keys') -Force

    # Point defaultProfile at PowerShell 7 by *name*, because its GUID differs
    # per machine and per install source.
    $pwshProfile = $live.profiles.list | Where-Object { $_.name -match '^PowerShell$' -or $_.commandline -match 'pwsh' } | Select-Object -First 1
    if ($pwshProfile -and $pwshProfile.guid) {
        $live | Add-Member -NotePropertyName defaultProfile -NotePropertyValue $pwshProfile.guid -Force
        Write-Info "defaultProfile -> PowerShell 7"
    } else {
        Write-Warn 'PowerShell 7 profile not found in Windows Terminal - defaultProfile unchanged.'
    }

    $live | ConvertTo-Json -Depth 30 | Set-Content $wtPath -Encoding utf8
    Write-Ok "merged into $wtPath"
    Write-Info 'your existing tab profiles were preserved'
}

# ── 7. git + delta ───────────────────────────────────────────────────────────
# Only diff/pager behaviour. user.name and user.email are yours and are never
# touched by this script.
Write-Step 'git + delta'

if ($SkipGit) {
    Write-Info 'skipped'
} elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warn 'git not found - skipping.'
} elseif ($PSCmdlet.ShouldProcess('git config --global', 'apply delta settings')) {
    $gitSettings = [ordered]@{
        'core.pager'             = 'delta'
        'interactive.diffFilter' = 'delta --color-only'
        'delta.navigate'         = 'true'
        'delta.line-numbers'     = 'true'
        'delta.side-by-side'     = 'true'
        'delta.syntax-theme'     = 'Nord'
        'delta.hyperlinks'       = 'true'
        'merge.conflictstyle'    = 'zdiff3'
        'diff.colorMoved'        = 'default'
    }
    foreach ($kv in $gitSettings.GetEnumerator()) {
        git config --global $kv.Key $kv.Value
    }
    Write-Ok "$($gitSettings.Count) git settings applied"
    Write-Info 'user.name / user.email were not modified'
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Step 'Done'
Write-Host @"

  Close Windows Terminal completely and reopen it.

  Not a new tab - the whole application. Windows Terminal caches the
  environment it was launched with and every tab inherits that copy, so a
  new tab will not see the PATH changes made above.

  Then check:
    Get-StartupTime     # ~2 s is normal
    z                   # jump to a directory by fuzzy name
    Ctrl+R              # fuzzy history (first press loads PSFzf, then instant)
    lg                  # lazygit

  If the prompt shows boxes instead of icons, set the font face to
  "JetBrainsMono NFM" in Windows Terminal settings.

  Backups from this run carry the suffix .bak-$stamp

"@ -ForegroundColor White
