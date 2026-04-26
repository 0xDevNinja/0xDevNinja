#!/usr/bin/env bash
set -euo pipefail

USER="0xDevNinja"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Projects: top 6 non-fork, non-profile public repos sorted by pushed_at ---
gh api "users/$USER/repos?per_page=100&sort=pushed&type=owner" \
  | jq -r --arg user "$USER" '
      [.[] | select(.fork == false and .name != $user and .private == false)][:6]
      | map("| [\(.name)](\(.html_url)) | \((.description // "—") | gsub("\\|"; "\\|")) | \(.language // "—") | Active |")
      | .[]' > "$TMPDIR/projects_rows"

{
  echo "| Project | Description | Stack | Status |"
  echo "| --- | --- | --- | --- |"
  cat "$TMPDIR/projects_rows"
} > "$TMPDIR/projects.md"

# --- Ecosystem: external PRs grouped by repo (top PR title + count) ---
gh search prs --author="$USER" --limit=100 --json repository,title,url,state \
  | jq -r --arg user "$USER" '
      [.[] | select(.repository.nameWithOwner | startswith($user + "/") | not)]
      | group_by(.repository.nameWithOwner)
      | map({
          repo: .[0].repository.nameWithOwner,
          count: length,
          prs: [.[] | "[#" + (.url | split("/") | .[-1]) + "](" + .url + ")"]
        })
      | sort_by(-.count)
      | map(
          "- **" + .repo + "** — "
          + (.prs | join(" · "))
          + " (" + (.count | tostring) + " PR" + (if .count > 1 then "s" else "" end) + ")"
        )
      | .[]' > "$TMPDIR/ecosystem.md"

if [ ! -s "$TMPDIR/ecosystem.md" ]; then
  echo "_No external PRs found._" > "$TMPDIR/ecosystem.md"
fi

# --- Recent Activity: total commits (public + private) for two windows ---
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
YEAR_NOW=$(date -u +"%Y")
YTD_START="${YEAR_NOW}-01-01T00:00:00Z"

# Portable "365 days ago" — try GNU first, fall back to BSD
if YEAR_AGO=$(date -u -d "365 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null); then
  :
else
  YEAR_AGO=$(date -u -v-365d +"%Y-%m-%dT%H:%M:%SZ")
fi

read -r -d '' GQL <<'GRAPHQL' || true
query($login: String!, $from: DateTime!, $to: DateTime!) {
  user(login: $login) {
    contributionsCollection(from: $from, to: $to) {
      totalCommitContributions
      restrictedContributionsCount
    }
  }
}
GRAPHQL

fetch_commits() {
  local from=$1 to=$2
  gh api graphql -f query="$GQL" -F login="$USER" -F from="$from" -F to="$to" \
    | jq -r '.data.user.contributionsCollection
              | (.totalCommitContributions + .restrictedContributionsCount)'
}

ROLLING=$(fetch_commits "$YEAR_AGO" "$NOW")
YTD=$(fetch_commits "$YTD_START" "$NOW")

# Format with thousands separator (locale-independent)
fmt() { echo "$1" | sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta'; }
ROLLING_FMT=$(fmt "$ROLLING")
YTD_FMT=$(fmt "$YTD")

cat > "$TMPDIR/activity.md" <<EOF
_Total commits across public + private repos. Auto-refreshed twice daily._

| Window | Commits |
| --- | --- |
| Rolling 365 days | **$ROLLING_FMT** |
| ${YEAR_NOW} year-to-date | **$YTD_FMT** |
EOF

# --- Splice into README between markers ---
python3 - "$README" "$TMPDIR" <<'PY'
import re, sys, pathlib
readme_path, tmpdir = sys.argv[1], sys.argv[2]
data = pathlib.Path(readme_path).read_text()

for marker in ("projects", "ecosystem", "activity"):
    content = pathlib.Path(f"{tmpdir}/{marker}.md").read_text().rstrip()
    pat = re.compile(rf"(<!-- START:{marker} -->).*?(<!-- END:{marker} -->)", re.DOTALL)
    data = pat.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", data)

pathlib.Path(readme_path).write_text(data)
print(f"README updated: {readme_path}")
PY
