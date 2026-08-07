# Windows Terminal Setup — Tokyo Night

A fast, complete Windows Terminal + PowerShell 7 environment. One command,
sane defaults, and every performance claim measured rather than assumed.

```
╭─ ~  projects  api   main ≢  ~1  +1   26.5.1              19:14
╰─❯
```

- **Tokyo Night** throughout — terminal scheme, prompt, tab bar, and `delta` diffs
- **oh-my-posh** prompt with git status, runtime versions, exit-code colouring, and a transient prompt that collapses old lines
- **Modern CLI tools** — `eza`, `bat`, `ripgrep`, `fd`, `fzf`, `zoxide`, `delta`, `lazygit`
- **~2 s shell startup**, down from 4.7 s on the reference machine, via lazy loading and one non-obvious fix (see [Performance](#performance))
- **Non-destructive installer** — merges into your Windows Terminal config instead of replacing it, and backs up everything it touches

## Install

Requires Windows 10/11, PowerShell 7+, and winget.

```powershell
git clone https://github.com/yshaath84/windows-terminal-setup.git
cd windows-terminal-setup
.\install.ps1
```

Preview without changing anything:

```powershell
.\install.ps1 -WhatIf
```

**Then close Windows Terminal completely and reopen it** — not a new tab. Windows
Terminal caches the environment it launched with and every tab inherits that
copy, so a new tab will not see the `PATH` changes.

### Options

| Flag | Effect |
|---|---|
| `-WhatIf` | Show every change without writing |
| `-SkipTools` | Don't install the winget CLI packages |
| `-SkipFont` | Don't install the Nerd Font |
| `-SkipOhMyPosh` | Leave the prompt and theme alone |
| `-SkipProfile` | Don't touch `$PROFILE` |
| `-SkipGit` | Don't change any git config |

## What you get

**Navigation** — `z <partial>` jumps to any directory you've visited by fuzzy
name, `zi` picks interactively, `..` / `...` / `....` go up, `mkcd` creates and
enters.

**Listing** — `ls` `ll` `la` `lt` are `eza` with icons, a git status column, and
tree mode.

**Git** — `gs` `gd` `gds` `ga` `gcmt` `gpsh` `glog` `gco` `gb`, plus `lg` for
lazygit. Diffs render through `delta` side-by-side with syntax highlighting.

**Search** — `grep` is ripgrep, `fd` finds files, `Ctrl+R` fuzzy-searches
history, `Ctrl+T` inserts a file path.

**Editing** — history search by prefix on `↑`, menu completion on `Tab`,
`→` to accept an inline suggestion, `Ctrl+F` to accept one word.

Full reference: **[docs/GUIDE.md](docs/GUIDE.md)** — keybindings, every command,
the colour palette, design rationale, and troubleshooting.

## What it will not touch

Deliberate limits, because an installer that rearranges your machine is not a
gift:

- **Your git identity.** `user.name` and `user.email` are never written. Only
  diff and pager behaviour is configured.
- **Your Windows Terminal profiles.** The `profiles.list` array — your WSL
  distros, developer prompts, custom entries — is left exactly as-is. Only
  `profiles.defaults`, the colour scheme, the theme, and keybindings are merged
  in. Your own keybindings survive; ours are added alongside and only replace a
  binding on an exact key conflict.
- **Anything, without a backup.** Every overwritten file is first copied to
  `<name>.bak-<timestamp>` in the same directory.

The merge behaviour is covered by [tests/Test-Merge.ps1](tests/Test-Merge.ps1),
which builds a synthetic settings file containing profiles this repo has never
seen and asserts they survive.

## Performance

Startup went 4,730 ms → ~2,000 ms, and the prompt renders in ~133 ms instead of
262 ms. The two changes that mattered:

**Lazy loading.** `Terminal-Icons` and `posh-git` cost 1.4 s and 0.9 s and are
redundant once `eza` draws icons and the prompt shows git status, so they are
installed but not imported. `PSFzf` costs 0.8 s and is bound to stub keybindings
that import it on first `Ctrl+R` / `Ctrl+T` press.

**Not installing oh-my-posh from winget.** This is the non-obvious one. The
winget/Store package is an MSIX, so `oh-my-posh.exe` is not a real binary — it is
an app-execution-alias stub resolved through the app-container layer on every
launch. The prompt binary runs *once per Enter keypress*, so that indirection is
paid constantly. The installer removes the MSIX if present and downloads the
standalone binary instead: identical appearance, roughly twice as fast.

Two other optimisations were tried, measured, and **reverted** — replacing
`Get-Command` probes with a manual `PATH` scan (slower: 330 ms vs 230 ms, because
`PATH` has 38 entries) and caching `zoxide init` output (no gain, plus a
stale-cache failure mode). Both are documented in §11 of the guide so nobody
re-attempts them.

Measure your own with `Get-StartupTime`. Take a median of five — single samples
on Windows are noise.

## Uninstall

```powershell
# restore the most recent backup of each file
Get-ChildItem $HOME\.config\oh-my-posh\*.bak-* | Sort-Object LastWriteTime | Select-Object -Last 1
```

Restore any `.bak-<timestamp>` file over its original, remove
`%LOCALAPPDATA%\Programs\oh-my-posh` from your user `PATH`, and `winget
uninstall` whichever tools you no longer want.

## Credits

Prompt by [oh-my-posh](https://ohmyposh.dev). Palette from
[Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme). The CLI tools
are the work of their respective authors — this repo only wires them together.

## License

MIT — see [LICENSE](LICENSE).
