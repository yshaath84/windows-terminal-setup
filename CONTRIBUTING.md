# Contributing to Duskshell

Thanks for taking the time. This is a small project with one hard rule, so the
guidance is short.

## The one hard rule

`install.ps1` runs against machines that are not yours. It must never destroy
configuration the user already had.

Concretely, it must never:

- write `user.name` or `user.email` into git config
- replace the Windows Terminal `profiles.list` array
- overwrite any file without first copying it to `<name>.bak-<timestamp>`

If you touch the merge logic in the Windows Terminal section, run the tests:

```powershell
.\tests\Test-Merge.ps1
```

They must stay at zero failures. Add a new assertion if you add a new kind of
merge — the test fabricates a stranger's `settings.json` on purpose, so extend
that fixture rather than testing against your own machine.

## Before you open a PR

```powershell
.\install.ps1 -WhatIf          # must print changes and write nothing
.\tests\Test-Merge.ps1         # must be 0 failures
```

CI runs both on `windows-latest`, plus a parse check on every `.ps1`, JSON
validation on every config, and PSScriptAnalyzer at `Error` severity.

## Performance claims

Every number in the README and the guide was measured, and the methodology is in
§11 of [docs/GUIDE.md](docs/GUIDE.md). If you submit an optimisation, include
before and after figures from `Get-StartupTime`, and take a **median of five** —
single samples on Windows are noise.

Two "obvious" optimisations in this repo turned out slower when measured, and
are documented as reverted so nobody repeats them. Negative results are welcome
here; please add yours to that section rather than deleting it.

## Style

Match the surrounding code. In practice that means:

- comments explain *why*, not *what* — especially where the code looks wrong but
  is deliberate (the `Get-Command` probes, the non-winget oh-my-posh install)
- full cmdlet names in scripts, aliases only in the interactive profile
- check `Get-Alias <name>` before adding a shortcut; PowerShell resolves
  Alias → Function → Cmdlet, so a built-in alias silently shadows your function

## Reporting a bug

Include your PowerShell version (`$PSVersionTable.PSVersion`), Windows build,
and the output of `.\install.ps1 -WhatIf`. If the prompt renders wrongly, say
which font is set in Windows Terminal — most glyph issues are a non-Nerd font.
