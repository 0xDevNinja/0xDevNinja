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

# --- Recent Activity: mixed feed (PRs + issues + commits), public only, last 5 by date ---
gh search prs --author="$USER" --sort=updated --order=desc --limit=20 \
  --json title,url,updatedAt,repository \
  | jq '[.[] | select(.repository.isPrivate == false)
        | {kind:"pr", date: .updatedAt[:10], title, url, repo: .repository.fullName}]' \
  > "$TMPDIR/prs.json"

gh search issues --author="$USER" --sort=updated --order=desc --limit=20 \
  --json title,url,updatedAt,repository -- is:issue \
  | jq '[.[] | select(.repository.isPrivate == false)
        | {kind:"issue", date: .updatedAt[:10], title, url, repo: .repository.fullName}]' \
  > "$TMPDIR/issues.json"

gh search commits --author="$USER" --sort=committer-date --order=desc --limit=20 \
  --json sha,commit,url,repository \
  | jq '[.[] | select(.repository.isPrivate == false)
        | {kind:"commit",
           date: (.commit.committer.date[:10]),
           title: (.commit.message | split("\n")[0]),
           url, repo: .repository.fullName}]' \
  > "$TMPDIR/commits.json"

jq -rs '
  add
  | sort_by(.date) | reverse | .[:5]
  | map(
      "- `" + .date + "` · "
      + (if .kind == "pr" then "PR"
         elif .kind == "issue" then "issue"
         else "commit" end)
      + " [" + (.title | gsub("\\|"; "\\|")) + "](" + .url + ") in `" + .repo + "`"
    )
  | .[]
' "$TMPDIR/prs.json" "$TMPDIR/issues.json" "$TMPDIR/commits.json" > "$TMPDIR/activity.md"

if [ ! -s "$TMPDIR/activity.md" ]; then
  echo "_No recent public activity._" > "$TMPDIR/activity.md"
fi

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
