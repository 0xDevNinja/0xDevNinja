#!/usr/bin/env bash
# Counts your commits across all owned repos (public + private), all branches.
# Uses parallel bare clones with blob filter — fast, no working tree, no large blobs.
#
# Outputs two integers separated by space: <rolling_365d> <ytd>
set -euo pipefail

USER="${USER_LOGIN:-0xDevNinja}"
EMAIL_REGEX="${EMAIL_REGEX:-manmit0x@gmail\.com\|0xDevNinja@users\.noreply\.github\.com\|${USER}}"
PARALLEL="${PARALLEL:-12}"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

YEAR_AGO=$(date -u -d "365 days ago" +"%Y-%m-%d" 2>/dev/null || date -u -v-365d +"%Y-%m-%d")
YTD_START="$(date -u +"%Y")-01-01"

# Enumerate all owned repos (paginated)
gh api '/user/repos?per_page=100&affiliation=owner&visibility=all' --paginate \
  | jq -r '.[].full_name' > "$TMPDIR/repos"

# Worker: bare-clone, count commits in two windows, emit "<365d> <ytd>"
worker() {
  local repo=$1
  local dir="$TMPDIR/$(echo "$repo" | tr '/' '_').git"
  if ! git clone --quiet --bare --filter=blob:none \
       "https://x-access-token:${GH_TOKEN}@github.com/${repo}.git" "$dir" 2>/dev/null; then
    echo "0 0"
    return
  fi
  local r y
  r=$(git -C "$dir" log --all --author="$EMAIL_REGEX" --since="$YEAR_AGO" --pretty=oneline 2>/dev/null | wc -l)
  y=$(git -C "$dir" log --all --author="$EMAIL_REGEX" --since="$YTD_START" --pretty=oneline 2>/dev/null | wc -l)
  rm -rf "$dir"
  echo "$r $y"
}
export -f worker
export TMPDIR EMAIL_REGEX GH_TOKEN YEAR_AGO YTD_START

# Run in parallel, aggregate sums
xargs -P "$PARALLEL" -I{} bash -c 'worker "{}"' < "$TMPDIR/repos" \
  | awk 'BEGIN {r=0; y=0} {r+=$1; y+=$2} END {printf "%d %d\n", r, y}'
