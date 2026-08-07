## What this changes

<!-- One or two sentences. -->

## Why

<!-- What problem it solves. If it's a performance change, include before/after
     from Get-StartupTime, median of five. -->

## Checks

- [ ] `.\install.ps1 -WhatIf` prints the intended changes and writes nothing
- [ ] `.\tests\Test-Merge.ps1` passes with 0 failures
- [ ] No new file is overwritten without a `.bak-<timestamp>` copy first
- [ ] git `user.name` / `user.email` are still never written
- [ ] Windows Terminal `profiles.list` is still never replaced

<!-- If you changed the merge logic, say which assertion covers it. If you added
     a new kind of merge, add an assertion to the test fixture. -->
