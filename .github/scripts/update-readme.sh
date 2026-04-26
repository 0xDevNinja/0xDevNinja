#!/usr/bin/env bash
set -euo pipefail

USER="0xDevNinja"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Projects: top 6 non-fork, non-profile public repos sorted by pushed_at ---
gh api "users/$USER/repos?per_page=100&sort=pushed&type=owner" \
  | jq -r --arg user "$USER" '
      [.[] | select(.fork == false and .name != $user and .private == false)][:7]
      | map("| [\(.name)](\(.html_url)) | \((.description // "—") | gsub("\\|"; "\\|")) | \(.language // "—") | Active |")
      | .[]' > "$TMPDIR/projects_rows"

{
  echo "| Project | Description | Stack | Status |"
  echo "| --- | --- | --- | --- |"
  cat "$TMPDIR/projects_rows"
} > "$TMPDIR/projects.md"

# --- Ecosystem: external PRs grouped by repo, with titles + repo links ---
gh search prs --author="$USER" --limit=100 --json repository,title,url,state \
  | jq -r --arg user "$USER" '
      [.[] | select(.repository.nameWithOwner | startswith($user + "/") | not)]
      | group_by(.repository.nameWithOwner)
      | map({
          repo: .[0].repository.nameWithOwner,
          count: length,
          prs: [.[] | {
            num: (.url | split("/") | .[-1]),
            url: .url,
            title: .title,
            state: .state
          }]
        })
      | sort_by(-.count)
      | map(
          "<details open>\n"
          + "<summary><b><a href=\"https://github.com/" + .repo + "\">"
            + (.repo | gsub("/"; " / "))
          + "</a></b> &middot; "
          + (.count | tostring) + " PR" + (if .count > 1 then "s" else "" end)
          + " &middot; <a href=\"https://github.com/" + .repo + "/pulls?q=author%3A" + $user + "+is%3Apr\">view all →</a>"
          + "</summary>\n\n"
          + (.prs | map("- [`#" + .num + "`](" + .url + ") — " + .title) | join("\n"))
          + "\n\n</details>"
        )
      | join("\n\n")' > "$TMPDIR/ecosystem.md"

if [ ! -s "$TMPDIR/ecosystem.md" ]; then
  echo "_No external PRs found._" > "$TMPDIR/ecosystem.md"
fi

# --- Recent Activity: true commit count via parallel bare clones (all branches) ---
YEAR_NOW=$(date -u +"%Y")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# count-commits.sh outputs "<rolling_365d> <ytd>" by cloning every owned repo
# (public + private) with --filter=blob:none and grepping git log across all branches.
# Much more accurate than GraphQL contributionsCollection (which inflates ~6x by
# counting branch-pushes rather than unique commits).
read -r ROLLING YTD < <(USER_LOGIN="$USER" bash "$SCRIPT_DIR/count-commits.sh")

# Format with thousands separator (locale-independent)
fmt() { echo "$1" | sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta'; }
ROLLING_FMT=$(fmt "$ROLLING")
YTD_FMT=$(fmt "$YTD")

cat > "$TMPDIR/activity.md" <<EOF
_Unique commits authored across public + private repos, all branches. Auto-refreshed twice daily._

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
