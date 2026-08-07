# Duskshell — Reference Guide

Everything Duskshell installs, why, and how to change it.
Developed on Windows 11 Pro 26100 · PowerShell 7.6.4 · Windows Terminal

---

## 1. Quick orientation

| Layer | Choice |
|---|---|
| Terminal emulator | Windows Terminal |
| Shell | PowerShell 7.6.4 (`pwsh`) — default profile |
| Prompt | oh-my-posh (**native binary**), custom Tokyo Night theme |
| Font | JetBrainsMono NFM (Nerd Font Mono), 11pt, ligatures on |
| Colour scheme | Tokyo Night (`#1a1b26` base) |
| Line editor | PSReadLine 2.4.5, ListView predictions |
| Startup cost | **~1.8–2.1 s** (down from 4.73 s) |
| Prompt render | **~133 ms** per Enter (down from 262 ms) |

Three commands worth memorising first:

```powershell
reload      # re-source the profile after editing it
ep          # open the profile in an editor
Get-StartupTime   # milliseconds to launch a new shell
```

---

## 2. File map

| What | Path |
|---|---|
| PowerShell profile | `$PROFILE` |
| Prompt theme | `$HOME\.config\oh-my-posh\tokyonight.omp.json` |
| oh-my-posh binary | `%LOCALAPPDATA%\Programs\oh-my-posh\bin\oh-my-posh.exe` |
| Windows Terminal settings | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| Git config | `$HOME\.gitconfig` |
| PS modules | `$HOME\Documents\PowerShell\Modules\` |
| This guide | `docs/GUIDE.md` |

**Backups.** `install.ps1` copies every file it is about to overwrite to
`<name>.bak-<yyyyMMdd-HHmmss>` beside the original. Nothing is replaced without
a backup, and re-running the installer writes a fresh one.

> The profile and modules live under **OneDrive** because Windows redirects
> `Documents` there. This was measured and is *not* a performance problem —
> loading modules from a local path tested no faster. It does mean your profile
> syncs across machines, which is usually what you want.

---

## 3. Keyboard reference

### 3.1 Windows Terminal (window, tabs, panes)

| Keys | Action |
|---|---|
| `Ctrl+C` / `Ctrl+V` | Copy / paste (falls through to SIGINT when nothing is selected) |
| `Ctrl+Shift+F` | Find in buffer |
| `Ctrl+Shift+L` | Clear buffer entirely |
| `Ctrl+Shift+Enter` | Focus mode (hide tabs/title bar) |
| `Ctrl+Shift+,` | Open `settings.json` |
| **Panes** | |
| `Alt+Shift+→` | Split pane right |
| `Alt+Shift+↓` | Split pane down |
| `Alt+Shift+D` | Duplicate current pane (auto direction) |
| `Alt+←↑↓→` | Move focus between panes |
| `Ctrl+Alt+←↑↓→` | Resize active pane |
| `Alt+Shift+Z` | Zoom pane to fill tab (toggle) |
| `Ctrl+Shift+W` | Close pane |

### 3.2 PSReadLine (editing the command line)

| Keys | Action |
|---|---|
| `↑` / `↓` | **History search by prefix** — type `git` then `↑` cycles only `git …` commands |
| `Tab` | Menu completion (grid of candidates, arrow to pick) |
| `→` | Accept the whole greyed-out suggestion (at end of line) |
| `Ctrl+→` | Accept whole suggestion (anywhere) |
| `Ctrl+F` | Accept **one word** of the suggestion |
| `Ctrl+W` | Delete word backwards |
| `Alt+Enter` | Newline without executing (multi-line input) |
| `F2` | Toggle prediction display: ListView ⇄ inline |
| `"` | Smart quote — inserts a pair, or steps over the closing one |

### 3.3 fzf (fuzzy finder — loads on first press)

| Keys | Action |
|---|---|
| `Ctrl+R` | Fuzzy-search command history |
| `Ctrl+T` | Fuzzy-pick a file path into the current line |

Inside fzf: type to filter, `↑`/`↓` to move, `Enter` to accept, `Esc` to cancel.

---

## 4. Command reference

### 4.1 Listing files (`eza`)

| Command | Meaning |
|---|---|
| `ls` | Compact listing, icons, dirs first, git status column |
| `ll` | Long listing, human-readable sizes |
| `la` | Long listing **including hidden** files |
| `lt` | Tree view, 2 levels deep |

All four pass through extra flags: `ll -s modified`, `lt --level=4`, etc.

### 4.2 Navigation

| Command | Meaning |
|---|---|
| `z <partial>` | **Jump to a directory by fuzzy name** — learns from where you actually go |
| `zi` | Interactive picker over the zoxide database |
| `..` `...` `....` | Up 1 / 2 / 3 levels |
| `~` | Go home |
| `mkcd <dir>` | Create a directory and cd into it |

`z` is the highest-leverage command here. Visit a directory normally once or
twice, then `z api` gets you there from anywhere.

### 4.3 Git shortcuts

| Command | Runs |
|---|---|
| `gs` | `git status --short --branch` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `ga` | `git add` |
| `gcmt "msg"` | `git commit -m "msg"` |
| `gpsh` | `git push` |
| `glog` | `git log --oneline --graph --decorate --all -20` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `lg` | **lazygit** — full terminal UI for staging, history, branches |

> **Why `gcmt` / `gpsh` / `glog` and not `gc` / `gp` / `gl`?**
> Those three are *ReadOnly built-in aliases* for `Get-Content`,
> `Get-ItemProperty` and `Get-Location`. Overriding them would silently break
> any script that uses the short forms. See §7.

### 4.4 Utilities

| Command | Meaning |
|---|---|
| `grep <pattern>` | ripgrep — recursive, gitignore-aware, fast |
| `bat <file>` | Syntax-highlighted file view with line numbers |
| `fd <pattern>` | Find files by name (gitignore-aware) |
| `which <cmd>` | Print the resolved path of a command |
| `touch <file>` | Create file, or bump its timestamp |
| `open [path]` | Open in Explorer / default app (defaults to `.`) |
| `duh` | Sizes of subdirectories in MB, largest first |
| `reload` | Re-source the profile |
| `ep` | Edit the profile |
| `Get-StartupTime` | Measure shell startup in ms |

### 4.5 The new CLI tools

| Tool | Replaces | Notes |
|---|---|---|
| `eza` | `ls` | Icons, git column, tree mode |
| `bat` | `cat` for reading | Paging, syntax highlighting, git gutter |
| `rg` (ripgrep) | `grep` / `Select-String` | Orders of magnitude faster |
| `fd` | `find` / `Get-ChildItem -Recurse` | Sane defaults, respects `.gitignore` |
| `fzf` | — | Generic fuzzy picker; powers `Ctrl+R` / `Ctrl+T` |
| `zoxide` | `cd` | Frecency-ranked directory jumping |
| `delta` | `git diff` pager | Side-by-side capable, syntax highlighted |
| `lazygit` | — | Full-screen git TUI |
| `gh` | — | GitHub CLI (was already installed) |

---

## 5. Reading the prompt

```
╭─ ~  projects  api   main ≢  ~1  +1   26.5.1              19:14
╰─❯
```

> The frame uses **rounded** corners `╭ ╰` (switched 2026-08-07). The earlier
> sharp `┌ └` were chosen because rounded box-drawing glyphs render somewhat
> thin in JetBrainsMono at 11pt — if they ever look cramped, that is why, and
> reverting is three `template` edits in the theme (two `prompt` blocks plus
> `secondary_prompt`) or `Copy-Item tokyonight.omp.json.bak-<stamp> …`.
>
> **Editing the theme requires `oh-my-posh cache clear`.** oh-my-posh caches the
> parsed config under `%LOCALAPPDATA%\oh-my-posh`, and a stale cache silently
> serves the *old* prompt even though the JSON on disk is correct — including
> for `oh-my-posh print primary`. If an edit appears to do nothing, clear the
> cache before assuming the edit is wrong.

| Segment | Colour | Shows |
|---|---|---|
| Path | blue `#7aa2f7` | Shortened path, max 3 levels |
| Git | green / **yellow** / cyan / orange | Branch + status. Yellow = uncommitted changes, cyan = ahead of remote, orange = behind |
| Runtime versions | per-language | node / python / go / rust / dotnet — **only in directories that use them** |
| Duration | dim | Appears only when a command took **> 2 s** |
| Clock | dim, right edge | Current time |
| `❯` | purple / **red** | Turns red when the last command exited non-zero |

Git detail markers: `+2` staged, `~1` modified, `≡` in sync with upstream,
a stash count when stashes exist.

**Transient prompt:** once a command finishes, its prompt collapses to a bare
`❯` so long scrollback stays readable. Configured by the `transient_prompt`
block in the theme JSON.

---

## 6. Colour palette (Tokyo Night)

Use these when adding segments, scripts, or any new tooling so everything matches.

| Role | Hex |
|---|---|
| Background | `#1a1b26` |
| Foreground | `#c0caf5` |
| Dim / comment | `#565f89` |
| Blue | `#7aa2f7` |
| Cyan | `#7dcfff` |
| Green | `#9ece6a` |
| Purple | `#bb9af7` |
| Red | `#f7768e` |
| Orange | `#ff9e64` |
| Yellow | `#e0af68` |

The theme JSON defines these once in a `palette` block and refers to them as
`p:blue`, `p:red`, etc. Change a colour there and it updates everywhere.

---

## 7. Design decisions & gotchas

Things that are deliberate. Don't "fix" them without reading this.

### Aliases outrank functions in PowerShell

Command resolution order is **Alias → Function → Cmdlet → Application**.
So `function ls { … }` is dead code while the built-in `ls → Get-ChildItem`
alias exists. The profile calls `Remove-Alias ls -Force` first.

The same trap applies to `gc`, `gp`, `gl`, `gci`, `gcm` — all built-in aliases.
Before naming a new shortcut, check it:

```powershell
Get-Alias yourname -ErrorAction SilentlyContinue
```

Anything returned is already taken. `ReadOnly` ones should be left alone.

### `cat` is still `Get-Content` — on purpose

Aliasing `cat → bat` is a popular tip and a bad idea in PowerShell.
`Get-Content` emits **objects** that pipe into other cmdlets; `bat` emits
formatted strings. Rebinding it silently breaks `cat file | Select-String …`.
Use `bat file.ts` explicitly when you want highlighting.

### CompletionPredictor is installed but NOT imported

Version 0.1.1 **deadlocks `pwsh` on import** on this machine — reproduced
repeatedly, hangs indefinitely (>90 s, never completes). The profile documents
this and skips it. Predictions still work from history.

Re-test after upgrading the module:

```powershell
Update-Module CompletionPredictor
# then, in a throwaway shell:
pwsh -NoProfile -NonInteractive -Command 'Import-Module CompletionPredictor; "ok"'
```

If that prints `ok` promptly, uncomment the import in the profile.

### Terminal-Icons and posh-git are installed but NOT imported

They cost **1.4 s** and **0.9 s** of startup respectively — together, half the
original 4.7 s. Both are redundant now:

- Terminal-Icons draws file icons → `eza --icons` already does, and `ls` is eza.
- posh-git adds `git ` tab-completion → the prompt already shows branch/status.

Uncomment their imports in the profile's Modules section if you miss them.

### PSFzf is lazy-loaded

Importing it costs ~0.8 s. Instead, `Ctrl+T` / `Ctrl+R` are bound to stubs that
import PSFzf on first press, then hand off. `Set-PsFzfOption` rebinds the keys
directly, so you pay the cost once per session and only if you use it.
**First press feels slightly slow; every press after is instant.**

### Predictions are guarded on redirected output

`Set-PSReadLineOption -PredictionSource` throws *"The handle is invalid"* when
stdout is redirected (CI, piping `pwsh -Command … | …`). The profile checks
`[Console]::IsOutputRedirected` first, so scripted use stays clean.

---

## 8. Git + delta

Configured globally:

```
core.pager            = delta
interactive.diffFilter = delta --color-only
delta.navigate        = true      # n / N jump between files in the diff
delta.line-numbers    = true
delta.side-by-side    = true      # split view; set false for unified
delta.syntax-theme    = Nord
delta.hyperlinks      = true
merge.conflictstyle   = zdiff3    # shows the common ancestor in conflicts
diff.colorMoved       = default   # moved code coloured differently from edits
```

`zdiff3` is worth knowing: in a merge conflict it shows the **original** text
alongside both sides, which usually makes the correct resolution obvious.

**Side-by-side is on** (enabled 2026-08-07). It needs width: each side gets
roughly half the terminal, so in a narrow split pane long lines wrap hard and
unified is easier to read. Toggle per-invocation without changing the global:

```powershell
git -c delta.side-by-side=false diff     # unified, just this once
git config --global delta.side-by-side false   # or switch back for good
```

---

## 9. Maintenance

### Edit and reload

```powershell
ep          # edit
reload      # apply without restarting
```

`reload` re-runs the whole profile in the current session. Some things
(`Remove-Alias ls`) are idempotent-with-a-warning on re-run — harmless.

### Measure startup after changes

```powershell
Get-StartupTime
```

Anything under ~1 s is excellent, under 2.5 s is fine. If it jumps, bisect by
timing each import individually:

```powershell
Measure-Command { pwsh -NoLogo -NoProfile -Command 'Import-Module SomeModule' }
```

Compare against the bare baseline (`… -Command 'exit'`, ~544 ms here) — the
difference is that module's true cost.

### Update everything

```powershell
winget upgrade --all
Update-Module            # PowerShell modules
```

> **oh-my-posh is no longer managed by winget.** It was deliberately removed
> from winget (see §11) and installed as a standalone binary, so
> `winget upgrade --all` will silently skip it. Update it by re-downloading:
>
> ```powershell
> $exe = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
> $ProgressPreference = 'SilentlyContinue'
> Invoke-WebRequest -UseBasicParsing -OutFile $exe `
>   'https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-windows-amd64.exe'
> oh-my-posh --version
> ```
>
> Close other terminals first — the running binary is locked while in use.

### Add a new CLI tool

```powershell
winget search <name>
winget install --id <Publisher.Package> --exact --silent
```

Then **open a new terminal** — winget updates `PATH`, but existing shells keep
the old copy.

### Revert

```powershell
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-Item "$wt.bak-<stamp>" $wt -Force
Copy-Item "$PROFILE.bak-<stamp>" $PROFILE -Force
```

---

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Prompt shows `□` boxes or garbled glyphs | Font isn't a Nerd Font. Set face to `JetBrainsMono NFM` in Windows Terminal settings. |
| `ls` shows plain output, no icons | `eza` not on PATH — open a new terminal after install. |
| Wall of red on shell start | Run `pwsh -NoProfile`, then `. $PROFILE` to see the real errors. |
| A shortcut runs the wrong thing | An alias is shadowing your function. `Get-Alias <name>` — see §7. |
| Shell hangs on launch | Comment out the Modules section, then re-add one at a time. |
| **Installed a tool, but new tabs can't find it** | Windows Terminal caches the environment it was launched with, and every tab inherits it. Installing anything that edits `PATH` requires **restarting Windows Terminal itself** — a new tab is not enough. Verify with `$env:Path -split ';'`. |
| Colours look washed out | Acrylic is at 92% opacity. Set `"opacity": 100` or `"useAcrylic": false`. |
| Prompt feels laggy | Known — see §11. |
| **Edited the theme, prompt didn't change** | oh-my-posh cached the parsed config. Run `oh-my-posh cache clear`, then open a new shell. See §5. |

Reset PSReadLine history if it gets polluted:

```powershell
Remove-Item (Get-PSReadLineOption).HistorySavePath
```

---

## 11. Performance log

**Status: resolved.** No open items.

### The MSIX problem (fixed)

oh-my-posh was originally installed as an **MSIX package**, so `oh-my-posh.exe`
was not a real binary — it was an app-execution-alias stub under
`AppData\Local\Microsoft\WindowsApps\` that Windows resolved through the
app-container layer on every launch. Since the prompt binary runs **once per
Enter keypress**, that indirection was paid constantly.

Fixed by uninstalling the winget/MSIX package and installing the standalone
binary from GitHub releases to `%LOCALAPPDATA%\Programs\oh-my-posh\bin`, with
that directory prepended to the user `PATH`.

| Metric | Before | After |
|---|---|---|
| Prompt render (per Enter) | 262 ms | **133 ms** |
| Shell startup | 2,259 ms | **2,106 ms** |

Isolated benchmarks put the native binary at 95 ms vs 262 ms; the 133 ms figure
is the steady-state median under normal load. Either way it is a **~2x**
improvement, and the theme is unchanged — appearance is identical.

The startup gain was smaller than the per-prompt gain would suggest, because
`oh-my-posh init` does more than one exe launch and most of its cost is script
generation and `Invoke-Expression` compilation, not process start.

### Full startup history

| Stage | Median |
|---|---|
| Original (all modules eagerly imported) | 4,730 ms |
| Dropped Terminal-Icons + posh-git, lazy PSFzf | 2,259 ms |
| Native oh-my-posh binary | 2,106 ms |
| Re-measured 2026-08-07, after VS Code + theme changes | **1,844 ms** |
| *(bare `pwsh -NoProfile` floor)* | *552 ms* |

The 2026-08-07 re-measure (5 samples, median; same `Get-StartupTime`
methodology) is **not** an improvement to claim — nothing that day could plausibly
have made startup faster, and adding VS Code's `bin` to PATH makes the
`Get-Command` probes marginally *slower* if anything. Read it as run-to-run
variance: startup is stable in the **1.8–2.1 s** band. Treat a single sample as
noise; take a median of 5 before concluding anything moved.

### Two optimisations that were tried and REVERTED

Recorded so they don't get re-attempted:

**1. Replacing `Get-Command` probes with a manual PATH scan.** The 9 `Test-Tool`
probes cost ~230 ms, and `Get-Command` rescans PATH each call — so a direct
file-existence check *should* be faster. It is not, because PATH here has 38
directories and each probe becomes 114 filesystem checks:

| Strategy | Cost for 9 probes |
|---|---|
| `Get-Command` (current) | **~230 ms** |
| `[IO.File]::Exists` loop | ~330 ms |
| `Test-Path` loop | ~890 ms |

`Test-Path` is a cmdlet with per-call pipeline overhead, which is why it is by
far the worst. Get-Command's internal PATH cache beats both. **Left as-is.**

**2. Caching `zoxide init` output to a file.** Its output is deterministic, so
generating once and dot-sourcing should skip an exe launch. Measured: 891 ms
cached vs 857 ms live — no gain, arguably worse, and it adds a stale-cache
failure mode. **Reverted.**

The lesson both times: *measure before and after*. Two changes that were
obviously-correct on paper both made things slower.

### If you ever want it faster still

`starship` is installed natively and benchmarks at **47 ms** per render — about
3x faster than native oh-my-posh. The cost is rewriting the theme in starship's
TOML format, which can get very close to the current look but not identical.
Not currently worth it; 133 ms is below the threshold where lag is noticeable.

---

## 12. Inventory

**Installed by `install.ps1` via winget:** JetBrainsMono Nerd Font, fzf, zoxide, eza,
bat, ripgrep, fd, delta, lazygit.

**Installed as a standalone binary:** oh-my-posh, latest GitHub release —
**not** winget-managed, see §9 for how to update it.

**Already present:** git, gh, starship, winget, Windows Terminal,
PowerShell 7.6.4.

**Removed if present:** the oh-my-posh MSIX package (replaced by the native binary, §11).

**PowerShell modules:** PSReadLine 2.4.5 *(active)*, PSFzf 2.7.12 *(lazy)*,
Terminal-Icons 0.11.0 *(dormant)*, posh-git 1.1.0 *(dormant)*,
CompletionPredictor 0.1.1 *(dormant — deadlocks, §7)*.

**Editor:** VS Code (if installed), typically system-wide at
`C:\Program Files\Microsoft VS Code`. Its `bin\` is on the **machine** PATH
(`HKLM\…\Session Manager\Environment`), not the user PATH — worth knowing when
auditing PATH, since checking only `HKCU:\Environment` will report it missing.

`ep` and `$env:EDITOR` detect it at runtime via `Test-Tool`, so both upgraded
with no profile edit: `$env:EDITOR` is now `code -w`, and `ep` opens the profile
in VS Code. `nvim` still wins over `code` if you ever install it (see the
`$env:EDITOR` line in the profile's Environment section).





