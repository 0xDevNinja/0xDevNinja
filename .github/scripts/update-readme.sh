#!/usr/bin/env bash
set -euo pipefail

USER="0xDevNinja"
README="README.md"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# --- Projects: top 6 non-fork, non-profile public repos sorted by pushed_at ---
# Get top 7 non-fork public repos sorted by pushed_at
gh api "users/$USER/repos?per_page=100&sort=pushed&type=owner" \
  | jq -r --arg user "$USER" '
      [.[] | select(.fork == false and .name != $user and .private == false)][:7]
      | .[] | "\(.full_name)|\(.html_url)|\((.description // "—") | gsub("\\|"; "\\|"))"' \
  > "$TMPDIR/repos_meta"

# Resolve "Stack" via /languages endpoint with smart priority + tooling filter.
# Priority order favors compiled / typed / blockchain langs over scripting & frontend.
# Tooling/markup languages (HTML, CSS, Shell, etc) are filtered out completely.
PRIORITY="Solidity Move Rust Go TypeScript Python Java Vyper Cairo Huff JavaScript Ruby PHP Swift Kotlin C C++"
SKIP_LANGS="HTML CSS SCSS Shell Dockerfile Makefile Procfile MDX Nix HCL Roff Batchfile PowerShell"

resolve_stack() {
  local repo=$1
  gh api "repos/$repo/languages" 2>/dev/null \
    | jq -r --arg priority "$PRIORITY" --arg skip "$SKIP_LANGS" '
        ($skip | split(" ")) as $skip_arr
        | ($priority | split(" ")) as $prio_arr
        | to_entries
        | map(select(.key as $k | $skip_arr | index($k) | not))
        | . as $langs
        | ([$prio_arr[] as $p | $langs[] | select(.key == $p) | .key]
            + ($langs | sort_by(-.value) | map(.key)))
        | reduce .[] as $k ([]; if any(.[]; . == $k) then . else . + [$k] end)
        | .[0:2]
        | join(", ")
      '
}

# Build project table rows
{
  echo "| Project | Description | Stack | Status |"
  echo "| --- | --- | --- | --- |"
  while IFS='|' read -r repo url desc; do
    stack=$(resolve_stack "$repo")
    [ -z "$stack" ] && stack="—"
    name="${repo#*/}"
    echo "| [$name]($url) | $desc | $stack | Active |"
  done < "$TMPDIR/repos_meta"
} > "$TMPDIR/projects.md"

# --- Ecosystem: external PRs grouped by repo, with titles + repo links ---
# Exclude own-repo PRs at search time via `-user:$USER` so the result budget
# isn't burned on self-authored PRs in personal repos. `gh search` max --limit
# is 1000; well above the realistic ceiling of external PRs/issues.
gh search prs --author="$USER" --limit=1000 --json repository,title,url,state -- "-user:$USER" \
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

# --- Issues: external issues authored, assigned, OR @-mentioned ---
# Three search calls (author + assignee + mentions) merged + deduped by URL,
# fetched once and partitioned by state into open/closed subsections.
# Captures: issues I filed, issues officially assigned to me, and issues where
# I'm @-tagged in body/comments. Excludes drive-by commenter noise.
# is:issue qualifier prevents PRs leaking in (search API treats PRs as issues).
{
  gh search issues --author="$USER"   --limit=1000 --json repository,title,url,state -- "-user:$USER" "is:issue"
  gh search issues --assignee="$USER" --limit=1000 --json repository,title,url,state -- "-user:$USER" "is:issue"
  gh search issues --mentions="$USER" --limit=1000 --json repository,title,url,state -- "-user:$USER" "is:issue"
} | jq -s --arg user "$USER" '
      add
      | unique_by(.url)
      | [.[] | select(.repository.nameWithOwner | startswith($user + "/") | not)]
    ' > "$TMPDIR/issues_all.json"

# Render one card-per-repo block for a given state. Cards collapsed by default
# (<details> without `open`) so the section stays compact in the rendered view.
render_issues() {
  local state=$1 out=$2
  jq -r --arg user "$USER" --arg state "$state" '
      [.[] | select((.state | ascii_downcase) == $state)]
      | group_by(.repository.nameWithOwner)
      | map({
          repo: .[0].repository.nameWithOwner,
          count: length,
          issues: [.[] | {
            num: (.url | split("/") | .[-1]),
            url: .url,
            title: .title
          }]
        })
      | sort_by(-.count)
      | map(
          "<details>\n"
          + "<summary><b><a href=\"https://github.com/" + .repo + "\">"
            + (.repo | gsub("/"; " / "))
          + "</a></b> &middot; "
          + (.count | tostring) + " issue" + (if .count > 1 then "s" else "" end)
          + " &middot; <a href=\"https://github.com/" + .repo + "/issues?q=is%3Aissue+is%3A" + $state + "+involves%3A" + $user + "\">view all →</a>"
          + "</summary>\n\n"
          + (.issues | map("- [`#" + .num + "`](" + .url + ") — " + .title) | join("\n"))
          + "\n\n</details>"
        )
      | join("\n\n")
    ' < "$TMPDIR/issues_all.json" > "$out"
  [ -s "$out" ] || echo "_No ${state} issues._" > "$out"
}

render_issues open   "$TMPDIR/issues-open.md"
render_issues closed "$TMPDIR/issues-closed.md"

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

for marker in ("projects", "ecosystem", "issues-open", "issues-closed", "activity"):
    content = pathlib.Path(f"{tmpdir}/{marker}.md").read_text().rstrip()
    pat = re.compile(rf"(<!-- START:{marker} -->).*?(<!-- END:{marker} -->)", re.DOTALL)
    data = pat.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", data)

pathlib.Path(readme_path).write_text(data)
print(f"README updated: {readme_path}")
PY
