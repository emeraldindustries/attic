# Contributing to Emerald Attic

Thanks for considering a contribution! This repo collects small, one-off utilities published **as-is** (see `SUPPORT.md`). PRs are welcome, but reviews/merges are not guaranteed.

---

## Quick PR Checklist

- [ ] Keep the change **small and focused** (one tool or one fix).
- [ ] Works on **macOS** and **Ubuntu** (list any OS/package requirements).
- [ ] No heavy deps; **document any required tools** at the top of the script.
- [ ] Add/extend README usage examples for your tool.
- [ ] Include a clear commit message (Conventional Commits **optional**).
- [ ] License header present (MIT) and file is executable where applicable.

---

## Scope & Philosophy

- This repo is an **attic**: utilities that are handy, minimal, and low-maintenance.
- Prefer **portable shell** (Bash 4+), minimal external commands.
- If cross-platform portability is hard, **document limitations** up front.

---

## Adding a New Tool

**Location**
- Place under `tools/<category>/your-tool-name.sh` (e.g., `tools/github/…`).

**Header block (required)**

#!/usr/bin/env bash
set -euo pipefail
# Name: your-tool-name.sh
# Purpose: <one sentence>
# Author: Emerald Industries
# License: MIT
# Support: No-maintenance; PRs welcome
# Requires: bash 4+, git, <others>
# Tested on: macOS 12+, Ubuntu 22.04
# Usage: ./your-tool-name.sh --help


---

## Style guidelines

- Quote variables, check exits, avoid unsafe ```rm -rf "$var"``` patterns.
- Prefer POSIX/GNU-agnostic flags; if you must use GNU-only features, note it.
- Use ```shellcheck``` locally when possible.
- Parse args with a simple ```case``` loop; provide ```--help```.

---

## Docs

- Update ```README.md```: what it does, usage, examples, and any caveats.

---

## Changing an Existing Tool

- Keep behavior **backward-compatible** when possible.
- If breaking changes are unavoidable, call them out in the PR and README.
- Add a brief “**Why**” in the PR description.

---

## Testing

- Provide a simple **test plan** in the PR (commands you ran and expected output).
- Where safe, include a **dry-run mode** to prevent destructive mistakes.

---

## Security

- These are general-purpose scripts; avoid embedding secrets or account-specific URLs.
- If you spot an obvious security issue, open a PR with a direct fix.

---

## Licensing

- By contributing, you agree your contribution is licensed under the repo’s **MIT License**.

---

## Maintainers

- Maintainers may tag a snapshot release for convenience.
- We may archive tools or the repo over time; forks are encouraged if you need ongoing changes.
