# ─────────────────────────────────────────────────────────────────────────────
#  PowerShell profile — Tokyo Night
#  Reload with:  reload        Edit with:  ep
# ─────────────────────────────────────────────────────────────────────────────

# Everything below is guarded, so a missing tool degrades quietly
# instead of throwing a wall of red at every new shell.
#
# These 9 probes cost ~230 ms total. Measured alternatives were both WORSE on
# this machine (38 PATH dirs): a Test-Path loop cost ~890 ms, [IO.File]::Exists
# ~330 ms. Get-Command's native PATH cache wins — do not "optimise" this.
function Test-Tool([string]$Name) { $null -ne (Get-Command $Name -ErrorAction SilentlyContinue) }


# ── PSReadLine edit mode — MUST come before oh-my-posh ───────────────────────
# Set-PSReadLineOption -EditMode resets every key handler to that mode's
# defaults. oh-my-posh's init binds Enter to OhMyPoshEnterKeyHandler, which is
# what drives the transient prompt, so setting EditMode *after* init silently
# throws that handler away — no error, the feature just stops working.
#
# Verified both ways:
#   init then EditMode  ->  Enter = AcceptLine              (transient broken)
#   EditMode then init  ->  Enter = OhMyPoshEnterKeyHandler (transient works)
#
# Do not move this below the Prompt section.
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Windows


# ── Prompt ───────────────────────────────────────────────────────────────────
if (Test-Tool oh-my-posh) {
    $theme = "$HOME\.config\oh-my-posh\tokyonight.omp.json"
    if (Test-Path $theme) {
        oh-my-posh init pwsh --config $theme | Invoke-Expression
        # Transient prompt (finished prompts collapse to a bare ❯ so scrollback
        # stays readable) comes from the "transient_prompt" block in the theme
        # JSON. oh-my-posh v30 has no Enable-PoshTransientPrompt cmdlet.
    }
}


# ── PSReadLine: history-aware autosuggestions ────────────────────────────────
# Predictions need a real console; skip them when output is redirected
# (CI, `pwsh -Command ... | ...`) or PSReadLine throws "The handle is invalid".
if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
}
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -ShowToolTips

Set-PSReadLineOption -Colors @{
    Command                = '#7aa2f7'
    Parameter              = '#bb9af7'
    Operator               = '#89ddff'
    Variable               = '#c0caf5'
    String                 = '#9ece6a'
    Number                 = '#ff9e64'
    Type                   = '#2ac3de'
    Comment                = '#565f89'
    Keyword                = '#bb9af7'
    Error                  = '#f7768e'
    InlinePrediction       = '#565f89'
    ListPrediction         = '#565f89'
    Selection              = "$([char]0x1b)[48;2;40;52;87m"
}

# Arrows filter history by what you've already typed — the single biggest win.
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+w    -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Ctrl+f    -Function ForwardWord          # accept one word of the suggestion
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptSuggestion
Set-PSReadLineKeyHandler -Key F2        -Function SwitchPredictionView # ListView <-> InlineView
Set-PSReadLineKeyHandler -Key Alt+Enter -Function AddLine              # multi-line without running

# Wrap the current line in quotes / brackets on keypress.
Set-PSReadLineKeyHandler -Chord '"' -BriefDescription SmartQuote -ScriptBlock {
    param($key, $arg)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line[$cursor] -eq '"') {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('""')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}


# ── Modules ──────────────────────────────────────────────────────────────────
# Terminal-Icons (+1.4s) and posh-git (+0.9s) are installed but NOT imported:
#   Terminal-Icons  - redundant now that ls/ll/la use `eza --icons`.
#   posh-git        - only adds `git ` tab-completion; oh-my-posh already
#                     renders branch/status in the prompt.
# Together they were 2.3s of a 4.7s startup. Uncomment if you want them back:
#   Import-Module Terminal-Icons
#   Import-Module posh-git

# CompletionPredictor 0.1.1 is installed but deliberately NOT imported: on this
# machine it deadlocks pwsh on import (reproduced repeatedly, hangs >90s).
# PredictionSource=HistoryAndPlugin below works fine with no plugin registered.
# If a later version fixes it, re-enable by uncommenting:
#   Import-Module CompletionPredictor

if ((Get-Module -ListAvailable PSFzf) -and (Test-Tool fzf)) {
    # PSFzf costs ~0.8s to import, so it is loaded on first use instead of at
    # startup: the Ctrl+t / Ctrl+r handlers below import it, hand off to the
    # real handler, and Set-PsFzfOption then rebinds the keys directly.
    function Initialize-PSFzf {
        if ($script:PSFzfReady) { return }
        Import-Module PSFzf -ErrorAction Stop
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Set-PsFzfOption -TabExpansion
        $script:PSFzfReady = $true
    }
    # Ctrl+t = fuzzy-pick a file into the line.  Ctrl+r = fuzzy history search.
    Set-PSReadLineKeyHandler -Key Ctrl+t -BriefDescription 'FzfFindFile' -ScriptBlock {
        Initialize-PSFzf; Invoke-FzfPsReadlineHandlerProvider
    }
    Set-PSReadLineKeyHandler -Key Ctrl+r -BriefDescription 'FzfHistory' -ScriptBlock {
        Initialize-PSFzf; Invoke-FzfPsReadlineHandlerHistory
    }
    $env:FZF_DEFAULT_OPTS = @(
        '--height=45% --layout=reverse --border=rounded --info=inline'
        '--color=bg+:#292e42,bg:#1a1b26,spinner:#bb9af7,hl:#7aa2f7'
        '--color=fg:#c0caf5,header:#7aa2f7,info:#565f89,pointer:#bb9af7'
        '--color=marker:#9ece6a,fg+:#c0caf5,prompt:#bb9af7,hl+:#7dcfff'
        '--color=border:#565f89'
    ) -join ' '
    if (Test-Tool fd) { $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git' }
}

# zoxide: `z proj` jumps to the project dir you visit most. Learns as you go.
# Caching this init to a file was measured and did NOT help (891 ms cached vs
# 857 ms live) — dot-sourcing costs as much as the exe launch. Left as-is.
if (Test-Tool zoxide) {
    Invoke-Expression (& { (zoxide init powershell --cmd z | Out-String) })
}


# ── Better defaults for the classics ─────────────────────────────────────────
if (Test-Tool eza) {
    # Aliases outrank functions in PowerShell's resolution order, so the built-in
    # `ls` -> Get-ChildItem alias has to go before `function ls` can ever be hit.
    Remove-Alias ls -Force -ErrorAction SilentlyContinue

    $ezaArgs = @('--group-directories-first', '--icons=auto', '--git')
    function ll { eza -lh  @ezaArgs @args }              # long
    function la { eza -lha @ezaArgs @args }              # long + hidden
    function ls { eza      @ezaArgs @args }
    function lt { eza -lh --tree --level=2 @ezaArgs @args }
}

# `grep` isn't a real PowerShell command, so pointing it at ripgrep is free.
if (Test-Tool rg) { Set-Alias grep rg }

# NOTE: `cat` is deliberately left as Get-Content — it returns objects that
# scripts pipe into other cmdlets, and bat would turn those into plain strings.
# Use `bat file.ts` directly when you want syntax highlighting.

if (Test-Tool lazygit) { Set-Alias lg lazygit }
if (Test-Tool nvim)    { Set-Alias vim nvim }


# ── Navigation ───────────────────────────────────────────────────────────────
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function ~     { Set-Location $HOME }

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}


# ── Git shortcuts ────────────────────────────────────────────────────────────
# NOTE: gc / gp / gl are ReadOnly built-in aliases (Get-Content, Get-ItemProperty,
# Get-Location) that other scripts rely on, so the git equivalents are named
# gcmt / gpsh / glog rather than clobbering them.
function gs   { git status --short --branch @args }
function gd   { git diff @args }
function gds  { git diff --staged @args }
function ga   { git add @args }
function gcmt { git commit -m @args }
function gpsh { git push @args }
function glog { git log --oneline --graph --decorate --all -20 @args }
function gco  { git checkout @args }
function gb   { git branch @args }


# ── Small utilities ──────────────────────────────────────────────────────────
function which  { param([string]$Name) (Get-Command $Name -ErrorAction SilentlyContinue).Source }
function touch  { param([string]$Path) if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date } else { New-Item -ItemType File -Path $Path | Out-Null } }
function open   { param([string]$Path = '.') Invoke-Item $Path }
function reload { . $PROFILE }

# Picks whatever editor actually exists; falls back to notepad so `ep` never
# dies with "'code' is not recognized" on a machine with no editor installed.
function ep {
    if     (Test-Tool code) { code $PROFILE }
    elseif (Test-Tool nvim) { nvim $PROFILE }
    else                    { notepad $PROFILE }
}

# Directory sizes, largest first.
function duh {
    Get-ChildItem -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object Length -Sum).Sum
        [PSCustomObject]@{ Name = $_.Name; MB = [math]::Round($size / 1MB, 1) }
    } | Sort-Object MB -Descending
}

# How long did this shell take to start? Useful when the profile grows.
function Get-StartupTime {
    (Measure-Command { pwsh -NoLogo -Command exit }).TotalMilliseconds
}


# ── Environment ──────────────────────────────────────────────────────────────
$env:EDITOR = if (Test-Tool nvim) { 'nvim' } elseif (Test-Tool code) { 'code -w' } else { 'notepad' }
$PSStyle.FileInfo.Directory = "$([char]0x1b)[1;38;2;122;162;247m"   # blue, bold
