<div align="center">

# Duskshell

### PowerShell, after sundown.

A fast, beautiful Windows terminal — installed with one command,
and measured rather than guessed.

[![CI](https://github.com/yshaath84/duskshell/actions/workflows/ci.yml/badge.svg)](https://github.com/yshaath84/duskshell/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-7aa2f7?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-565f89?style=flat-square)](#requirements)
[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-9ece6a?style=flat-square)](https://github.com/PowerShell/PowerShell)
[![Theme: Tokyo Night](https://img.shields.io/badge/theme-Tokyo%20Night-bb9af7?style=flat-square)](#the-look)

![Duskshell: an eza file listing with icons, git status output, and a two-line
prompt showing branch, staged and modified file counts, and the project's Node
version](docs/screenshot.png)

</div>

---

Windows terminals are usually one of two things: the default, which is fine and
forgettable, or a dotfiles repo that dumps 400 lines into your `$PROFILE`,
overwrites your settings, and adds three seconds to every shell you open.

Duskshell is the third option. It is a complete environment — prompt, colours,
font, and nine modern CLI tools — that **starts in about two seconds**, renders
its prompt in **133 ms**, and **never overwrites anything you already had**.

Every performance claim on this page was measured with `Get-StartupTime`, and
the two optimisations that turned out *slower* are documented too.

## Install

```powershell
git clone https://github.com/yshaath84/duskshell.git
cd duskshell
.\install.ps1
```

Then **close Windows Terminal completely and reopen it** — not a new tab.
Windows Terminal caches the environment it launched with, so a new tab won't see
the `PATH` changes.

See exactly what would change, first:

```powershell
.\install.ps1 -WhatIf
```

### Requirements

Windows 10 or 11, PowerShell 7+, winget. That's it.

### Options

| Flag | Effect |
|---|---|
| `-WhatIf` | Print every change, write nothing |
| `-SkipTools` | Don't install the winget CLI packages |
| `-SkipFont` | Don't install the Nerd Font |
| `-SkipOhMyPosh` | Leave the prompt and theme alone |
| `-SkipProfile` | Don't touch `$PROFILE` |
| `-SkipGit` | Don't change any git config |

## What you actually get

Not a list of packages — a list of things that get faster.

**Stop typing paths.** `z api` jumps to that directory from anywhere, because
`zoxide` ranks by how often you actually go there. `zi` opens a picker over the
whole history.

```powershell
z dashboard        # ~/work/clients/acme/dashboard
..  ...  ....      # up one, two, three
mkcd new-service   # create and enter
```

**See your repo at a glance.** `ls` is `eza` with icons and a git status column.
The prompt already shows your branch, how many files are staged and modified,
and whether you're ahead of the remote — so you stop running `git status`
reflexively.

```powershell
gs                 # status, short + branch
gd  /  gds         # diff / staged diff, side-by-side via delta
glog               # graph log, all branches
lg                 # lazygit, full TUI
```

**Find things instantly.** `grep` is ripgrep. `fd` replaces recursive
`Get-ChildItem`. `Ctrl+R` fuzzy-searches your whole history; `Ctrl+T` drops a
file path onto the line you're typing.

**Type less.** `↑` searches history *by prefix* — type `git` then `↑` and you
cycle only your git commands. `→` accepts the greyed-out suggestion, `Ctrl+F`
accepts one word of it, `Tab` opens a completion grid.

**Read your prompt, not your scrollback.** Runtime versions appear only in
directories that use them. Command duration appears only when something took
longer than two seconds. The `❯` turns red when the last command failed.

📖 **[Full reference →](docs/GUIDE.md)** — every keybinding, every command, the
colour palette, and the reasoning behind each design decision.

## Why it's fast

Most terminal setups get slower as they get prettier. This one got faster, and
the reason is worth stealing even if you never install it.

**oh-my-posh should not be installed from winget.** The winget package is an
MSIX, which means `oh-my-posh.exe` isn't a real binary — it's an
app-execution-alias stub that Windows resolves through the app-container layer
on *every single launch*. The prompt binary runs once per Enter keypress, so you
pay that indirection constantly. Swapping to the standalone GitHub binary is
identical in appearance and roughly twice as fast.

**Modules you don't need are installed but never imported.** `Terminal-Icons`
costs 1.4 s and `posh-git` costs 0.9 s — together, half the original startup —
and both are redundant once `eza` draws icons and the prompt shows git status.
`PSFzf` costs 0.8 s and is lazy-loaded: `Ctrl+R` is bound to a stub that imports
it on first press.

| Stage | Startup |
|---|---|
| Everything eagerly imported | 4,730 ms |
| Lazy-loaded, redundant modules dropped | 2,259 ms |
| Native oh-my-posh binary | **~2,000 ms** |
| *(bare `pwsh -NoProfile` floor)* | *552 ms* |

Prompt render went from **262 ms → 133 ms** in the same work.

**And two things that didn't work.** Replacing `Get-Command` probes with a
manual `PATH` scan was *slower* (330 ms vs 230 ms — `PATH` has 38 entries, so
each probe became 114 filesystem checks). Caching `zoxide init` output saved
nothing and added a stale-cache failure mode. Both are written up in §11 of the
guide so nobody repeats them.

## What it will not touch

An installer that rearranges your machine isn't a gift. Three hard limits:

- **Your git identity.** `user.name` and `user.email` are never written. Only
  diff and pager behaviour is configured.
- **Your Windows Terminal profiles.** The `profiles.list` array — your WSL
  distros, developer prompts, custom entries — is left exactly as it was. Only
  `profiles.defaults`, the colour scheme, the theme, and keybindings are merged
  in. Your own keybindings survive; ours are added alongside and replace one
  only on an exact key conflict.
- **Anything, without a backup.** Every file it overwrites is first copied to
  `<name>.bak-<timestamp>` in the same directory.

This is enforced by tests, not promises. [`tests/Test-Merge.ps1`](tests/Test-Merge.ps1)
fabricates a settings file for a machine this repo has never seen — an Ubuntu
WSL profile, a hand-written profile, a Campbell colour scheme, a custom
`ctrl+shift+p` binding — merges into it, and asserts all of them survive.

```
PS> .\tests\Test-Merge.ps1
  PASS  all 3 original profiles survive
  PASS  WSL Ubuntu profile survives
  PASS  their Campbell scheme kept
  PASS  their ctrl+shift+p kept
  ...
  16 passed, 0 failed
```

## The look

[Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) throughout —
terminal scheme, prompt, tab bar, and `delta` diffs, so nothing clashes.
JetBrainsMono Nerd Font at 11pt with ligatures. The palette is defined once in
the theme's `palette` block; change a colour there and it updates everywhere.

| | |
|---|---|
| Background `#1a1b26` | Foreground `#c0caf5` |
| Blue `#7aa2f7` | Cyan `#7dcfff` |
| Green `#9ece6a` | Purple `#bb9af7` |
| Red `#f7768e` | Orange `#ff9e64` |

## Uninstall

Restore any `.bak-<timestamp>` file over its original, remove
`%LOCALAPPDATA%\Programs\oh-my-posh` from your user `PATH`, and `winget
uninstall` whatever you no longer want. Nothing else was changed.

## FAQ

**Will this break my existing setup?**
It backs up every file it touches and merges rather than overwrites. If you want
certainty first, run `.\install.ps1 -WhatIf` — it prints every change and writes
nothing.

**Why is `cat` still `Get-Content`?**
Aliasing `cat → bat` is a popular tip and a bad idea in PowerShell.
`Get-Content` emits objects that pipe into other cmdlets; `bat` emits formatted
strings. Rebinding it silently breaks `cat file | Select-String`. Use `bat`
explicitly when you want highlighting.

**Why `gcmt` instead of `gc` for commit?**
`gc`, `gp` and `gl` are ReadOnly built-in aliases for `Get-Content`,
`Get-ItemProperty` and `Get-Location`. Overriding them breaks scripts that use
the short forms.

**Can I use my own colours?**
Yes — edit the `palette` block in `config/tokyonight.omp.json`, then run
`oh-my-posh cache clear`. Skip the cache clear and your edit will appear to do
nothing.

**Does it work with Windows PowerShell 5.1?**
No. PowerShell 7+ only.

## Contributing

Issues and PRs welcome. If you change the Windows Terminal merge logic, run
`.\tests\Test-Merge.ps1` — it must stay at zero failures, since that's the code
path that can damage someone's config.

## Credits

Prompt by [oh-my-posh](https://ohmyposh.dev). Palette from
[Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme). The CLI tools
are the work of their authors — [eza](https://github.com/eza-community/eza),
[bat](https://github.com/sharkdp/bat), [ripgrep](https://github.com/BurntSushi/ripgrep),
[fd](https://github.com/sharkdp/fd), [fzf](https://github.com/junegunn/fzf),
[zoxide](https://github.com/ajeetdsouza/zoxide), [delta](https://github.com/dandavison/delta),
[lazygit](https://github.com/jesseduffield/lazygit). Duskshell only wires them
together and gets out of the way.

## License

MIT — see [LICENSE](LICENSE).
