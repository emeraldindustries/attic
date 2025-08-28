## 📄 `docs/CONTRIBUTING.md`

# Contributing to Emerald Attic

Thanks for considering a contribution! This repo collects small, one‑off utilities published **as‑is** (see the [Support policy](./SUPPORT.md)). PRs are welcome, but reviews/merges aren’t guaranteed.

---

## ✅ Quick PR Checklist

- [ ] Keep the change **small & focused** (one tool or one fix).
- [ ] Works on **macOS** and **Ubuntu**; list any system/package requirements.
- [ ] No heavy deps; **document required tools** at the top of the script.
- [ ] Update README usage/examples for your tool.
- [ ] Clear commit message (Conventional Commits optional).
- [ ] License header present (MIT) and file is **executable** where applicable.

---

## 🧭 Scope & philosophy

- This repo is an **attic**: utilities that are handy, minimal, and low‑maintenance.
- Prefer **portable shell** (Bash 4+), minimal external commands.
- If cross‑platform portability is hard, **document limitations** up front.

---

## ➕ Adding a new tool

**Location**  
Place under `tools/<category>/<your-tool>.sh` (e.g., `tools/github/…`).

**Header block (required)**

```bash
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
```

---

## ✍️ Style guidelines

- Quote variables, check exits; avoid unsafe patterns like `rm -rf "$var"`.
- Prefer POSIX/GNU‑agnostic flags; if GNU‑only, **note it** in the header.
- Run `shellcheck` locally when possible.
- Parse args with a `case` loop; always provide `--help`.

---

## 📚 Docs

- Update the repo `README.md` with what the tool does, usage, examples, and caveats.

---

## 🔧 Changing an existing tool

- Keep behavior **backward‑compatible** when possible.
- If breaking changes are unavoidable, call them out in the PR and README.
- Add a brief **“Why”** in the PR description.

---

## 🧪 Testing

- Provide a simple **test plan** in the PR (commands you ran and expected output).
- Where safe, include a **dry‑run** mode to prevent destructive mistakes.

---

## 🔒 Security

- Avoid embedding secrets or account‑specific URLs.
- If you spot an obvious security issue, open a PR with a direct fix.

---

## ⚖️ Licensing

By contributing, you agree your contribution is licensed under the repo’s **MIT License** (see [`LICENSE`](../LICENSE)).

---

## 🧰 Maintainers

- Maintainers may tag snapshot releases for convenience.
- We may archive tools or the repo over time; forks are encouraged if you need ongoing changes.