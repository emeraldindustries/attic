#!/usr/bin/env bash
set -euo pipefail

# Name: retarget-remotes.sh
# Purpose: Bulk-update Git remotes from <old owner> to <new owner> across many repos
# Author: Emerald Industries
# License: MIT
# Requires: bash 3.2+, git, (optional) gh
# Usage: ./retarget-remotes.sh --old foo --new emeraldindustries --path ~/Stacks --apply

OLD_OWNER=""
NEW_OWNER=""
ROOT="."
APPLY=0
DO_PUSH=0
ASSUME_YES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --old)   OLD_OWNER="${2:-}"; shift 2 ;;
    --new)   NEW_OWNER="${2:-}"; shift 2 ;;
    --path)  ROOT="${2:-}"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --push)  DO_PUSH=1; shift ;;
    --yes)   ASSUME_YES=1; shift ;;
    -h|--help) sed -n '1,200p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$OLD_OWNER" || -z "$NEW_OWNER" ]] && { echo "❌ Missing --old/--new"; exit 1; }
[[ -d "$ROOT" ]] || { echo "❌ Path not found: $ROOT"; exit 1; }

echo "🔎 Scanning: $ROOT"
echo "🧭 github.com/$OLD_OWNER/*  →  github.com/$NEW_OWNER/*"
echo "🧪 Mode: $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"
[[ $DO_PUSH -eq 1 ]] && echo "⤴️  Post-action: push --all + --tags"
echo

count_total=0
count_changed=0
count_pushed=0

# Use -print0 to tolerate spaces; bash 3-friendly read loop
while IFS= read -r -d '' gitdir; do
  repo="${gitdir%/.git}"
  ((count_total++)) || true

  origin_url="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  [[ -n "$origin_url" ]] || continue

  # Rewrite only the owner segment after github.com[:/]
  new_url="$(printf '%s' "$origin_url" | sed -E "s#(github\.com[:/])${OLD_OWNER}/#\1${NEW_OWNER}/#")"

  # Skip if no change
  if [[ "$new_url" == "$origin_url" ]]; then
    continue
  fi

  echo "📦 $(basename "$repo")"
  echo "   • origin:"
  echo "     - from: $origin_url"
  echo "     - to  : $new_url"

  proceed=1
  if [[ $APPLY -eq 1 && $ASSUME_YES -ne 1 ]]; then
    read -r -p "   Apply change? [y/N] " ans
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] || proceed=0
  fi

  if [[ $proceed -eq 1 ]]; then
    if [[ $APPLY -eq 1 ]]; then
      git -C "$repo" remote set-url origin "$new_url"
      ((count_changed++)) || true
      echo "   ✅ origin updated."
      if [[ $DO_PUSH -eq 1 ]]; then
        echo "   ⤴️  Pushing branches and tags …"
        git -C "$repo" push --all origin || true
        git -C "$repo" push --tags origin || true
        ((count_pushed++)) || true
      fi
    else
      echo "   🧪 (dry-run) would run: git -C \"$repo\" remote set-url origin \"$new_url\""
    fi
  else
    echo "   ↩️  skipped"
  fi
  echo
done < <(find "$ROOT" -type d -name .git -print0)

echo "——— Summary ———"
echo "Total repos scanned : $count_total"
echo "Remotes updated     : $count_changed"
[[ $DO_PUSH -eq 1 ]] && echo "Repos pushed         : $count_pushed"
echo "Mode                : $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"