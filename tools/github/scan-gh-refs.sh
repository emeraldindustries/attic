#!/usr/bin/env bash
set -euo pipefail

# Name: scan-gh-refs.sh
# Purpose: Scan + (optional) fix github.com/<OLD>/… references across many repos
# Author: Emerald Industries
# License: MIT
# Requires: bash 3.2+, git, perl, grep, file(1)
# Usage: ./scan-gh-refs.sh --old foo --new emeraldindustries --path ~/Stacks [--apply]

OLD_OWNER=""; NEW_OWNER=""; ROOT="."
TRACKED_ONLY=0; INCLUDE_UNTRACKED=1
APPLY=0; ASSUME_YES=0; MAKE_BACKUPS=1
EXT_LIST=".md,.markdown,.txt,.json,.yaml,.yml,.xml,.ini,.toml,.conf,.php,.phtml,.html,.css,.scss,.js,.cjs,.mjs,.ts,.tsx,.jsx,.vue,.sh,.bash,.zsh,.py,.rb,.go,.rs,.java,.kt,.swift,.cs,.Dockerfile,.make,.mk,.env,.sql,.tpl,.njk,.twig"
EXCLUDE_DIRS="node_modules,vendor,dist,build,.idea,.vscode,.husky"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --old) OLD_OWNER="${2:-}"; shift 2 ;;
    --new) NEW_OWNER="${2:-}"; shift 2 ;;
    --path) ROOT="${2:-}"; shift 2 ;;
    --tracked-only) TRACKED_ONLY=1; INCLUDE_UNTRACKED=0; shift ;;
    --include-untracked) INCLUDE_UNTRACKED=1; shift ;;
    --ext) EXT_LIST="${2:-}"; shift 2 ;;
    --exclude) EXCLUDE_DIRS="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --no-backup) MAKE_BACKUPS=0; shift ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) sed -n '1,200p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$OLD_OWNER" || -z "$NEW_OWNER" ]] && { echo "❌ Missing --old / --new"; exit 1; }
[[ -d "$ROOT" ]] || { echo "❌ Path not found: $ROOT"; exit 1; }

# Build extension regex (portable)
IFS=',' read -r -a EXT_ARR <<< "$EXT_LIST"
EXT_REGEX="("
for i in "${!EXT_ARR[@]}"; do
  ext="${EXT_ARR[$i]}"
  [[ "$ext" == .* ]] || ext=".$ext"
  ext_esc="${ext//./\\.}"
  EXT_REGEX+="${ext_esc}"
  [[ $i -lt $((${#EXT_ARR[@]}-1)) ]] && EXT_REGEX+="|"
done
EXT_REGEX+=")$"

IFS=',' read -r -a EXC_ARR <<< "$EXCLUDE_DIRS"

echo "🔎 Root            : $ROOT"
echo "👤 Old → New       : $OLD_OWNER → $NEW_OWNER"
echo "🧪 Mode            : $([[ $APPLY -eq 1 ]] && echo APPLY || echo REPORT-ONLY)"
echo "📄 Extensions      : $EXT_LIST"
echo "🚫 Exclude dirs    : $EXCLUDE_DIRS"
echo

SEARCH_REGEX="github\\.com[/:]${OLD_OWNER}/"

total_repos=0; repos_with_hits=0; total_files=0; total_hits=0; total_fixed=0

# Collect repos without mapfile
repos=()
while IFS= read -r d; do repos+=("${d%/}") ; done < <(
  find "$ROOT" -type d -name ".git" -prune -print | sed 's|/.git$||' | sort
)

for repo in "${repos[@]}"; do
  ((total_repos++)) || true
  cd "$repo" || continue
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || continue

  # Collect candidate files (portable)
  files=()
  if [[ $TRACKED_ONLY -eq 1 ]]; then
    while IFS= read -r f; do files+=("$f"); done < <(git ls-files)
  else
    while IFS= read -r f; do files+=("$f"); done < <(git ls-files --cached --others --exclude-standard)
    if [[ ${#EXC_ARR[@]} -gt 0 ]]; then
      filtered=()
      for f in "${files[@]}"; do
        skip=0
        for ex in "${EXC_ARR[@]}"; do
          [[ "$f" == "$ex/"* || "$f" == */"$ex"/* ]] && { skip=1; break; }
        done
        [[ $skip -eq 0 ]] && filtered+=("$f")
      done
      files=("${filtered[@]}")
    fi
  fi

  # Filter by extension + text-ish
  filtered=()
  for f in "${files[@]}"; do
    [[ "$f" =~ $EXT_REGEX ]] || continue
    if command -v file >/dev/null 2>&1; then
      mime=$(file --mime -b "$f" 2>/dev/null || true)
      [[ "$mime" != text/* && "$mime" != *"charset="* ]] && continue
    fi
    filtered+=("$f")
  done
  files=("${filtered[@]}")
  [[ ${#files[@]} -eq 0 ]] && continue

  repo_hits=0; repo_fixed=0; file_list_with_hits=()

  for f in "${files[@]}"; do
    occ=$(grep -o -E -I "$SEARCH_REGEX" "$f" 2>/dev/null | wc -l | tr -d ' ') || true
    [[ "$occ" -gt 0 ]] || continue
    file_list_with_hits+=("$f:$occ")
    ((repo_hits+=occ)) || true

    if [[ $APPLY -eq 1 ]]; then
      if [[ $MAKE_BACKUPS -eq 1 ]]; then
        perl -0777 -pi.bak -e "s|(github\\.com[/:])${OLD_OWNER}/|\${1}${NEW_OWNER}/|g" "$f"
      else
        perl -0777 -pi -e "s|(github\\.com[/:])${OLD_OWNER}/|\${1}${NEW_OWNER}/|g" "$f"
      fi
      if git -c color.ui=never diff --name-only -- "$f" | grep -q .; then
        ((repo_fixed++)) || true
      fi
    fi
  done

  if [[ $repo_hits -gt 0 ]]; then
    ((repos_with_hits++)) || true
    ((total_hits+=repo_hits)) || true
    ((total_files+=${#file_list_with_hits[@]})) || true
    ((total_fixed+=repo_fixed)) || true

    echo "📦 $(basename "$repo") — hits: $repo_hits  files: ${#file_list_with_hits[@]}"
    for line in "${file_list_with_hits[@]}"; do
      f="${line%%:*}"; occ="${line##*:}"
      echo "   • $f  ($occ)"
      grep -n -E -I "$SEARCH_REGEX" "$f" | head -n 1 | sed 's/^/     ↳ /'
    done
    if [[ $APPLY -eq 1 ]]; then
      echo "   ✅ Files changed here: $repo_fixed"
    fi
    echo
  fi

  if [[ $APPLY -eq 1 && $ASSUME_YES -ne 1 ]]; then
    read -r -p "Continue to next repo? [Y/n] " ans
    [[ "${ans,,}" == "n" || "${ans,,}" == "no" ]] && break
  fi
done

echo "——— Summary ———"
echo "Repos scanned        : $total_repos"
echo "Repos with matches   : $repos_with_hits"
echo "Files with matches   : $total_files"
echo "Total occurrences    : $total_hits"
[[ $APPLY -eq 1 ]] && echo "Files changed (sum)  : $total_fixed"
echo "Mode                 : $([[ $APPLY -eq 1 ]] && echo APPLY || echo REPORT-ONLY)"
