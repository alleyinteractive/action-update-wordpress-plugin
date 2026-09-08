#!/bin/bash

set -o pipefail

# Automatically upgrade a plugin to match the latest WordPress version.

function normalize_version() {
	echo "$1" | awk -F. '{printf("%d.%d.%d\n", $1,$2,$3)}'
}

function update_pull_request() {
	local comment_marker="<!-- action-update-wordpress-plugin:$WP_NORMALIZED_VERSION -->"
	local comments
	local update_note="Updated this pull request from WordPress \`$PREVIOUS_VERSION\` to \`$WP_VERSION\` instead of opening a new pull request. $comment_marker"

	gh pr edit "$PR_NUMBER" --title "Upgrade plugin to WordPress $WP_VERSION" --body "- [ ] Test plugin against WordPress \`$WP_VERSION\`"
	comments=$(gh api --paginate "repos/{owner}/{repo}/issues/$PR_NUMBER/comments" --jq '.[].body')

	if ! grep -Fq "$comment_marker" <<< "$comments"; then
		gh pr comment "$PR_NUMBER" --body "$update_note"
	fi
}

# Ensure PLUGIN_FILE is set.
if [ -z "$PLUGIN_FILE" ]; then
	echo "[action-update-wordpress-plugin] PLUGIN_FILE is not set."
	exit 1
fi

# Check if PLUGIN_FILE exists.
if [ ! -f "$PLUGIN_FILE" ]; then
	echo "[action-update-wordpress-plugin] $PLUGIN_FILE does not exist."
	exit 1
fi

# Extract the latest version from the plugin file.
LATEST_VERSION=$(grep "Tested up to:" "$PLUGIN_FILE" | awk '{print $NF}')

# Ensure latest version is always in x.x.x format (e.g. 5.2.1 vs 5.2).
LATEST_VERSION=$(normalize_version "$LATEST_VERSION")

# Check if the latest version is set and not empty.
if [ -z "$LATEST_VERSION" ]; then
	echo "[action-update-wordpress-plugin] Latest version is not set."
	exit 1
fi

# Fetch the latest WordPress version from api.wordpress.org.
WP_VERSION=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')
WP_NORMALIZED_VERSION=$(normalize_version "$WP_VERSION")

# Early exit if they're the same version.
if [ "$WP_NORMALIZED_VERSION" == "$LATEST_VERSION" ]; then
	echo "[action-update-wordpress-plugin] Latest WordPress version and plugin-supported version are the same, no upgrade needed."
	exit 0
fi

echo "[action-update-wordpress-plugin] Latest WordPress version:        $WP_VERSION"
echo "[action-update-wordpress-plugin] Latest plugin supported version: $LATEST_VERSION"

# Check if the latest plugin version is less than the latest WordPress version, comparing the semantically versioned numbers.
function version_gt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

if version_gt "$LATEST_VERSION" "$WP_NORMALIZED_VERSION"; then
	echo "[action-update-wordpress-plugin] Latest WordPress version is greater than the latest plugin supported version, no upgrade needed."
	exit 0
else
	echo "[action-update-wordpress-plugin] Latest WordPress version is less than the latest plugin supported version, upgrade needed."
fi

echo "[action-update-wordpress-plugin] Upgrading plugin to $WP_VERSION ..."

set -e

OPEN_PR=$(gh pr list --app github-actions --state open --limit 1000 --json number,headRefName,title,isCrossRepository | jq -r 'sort_by(.number) | reverse | map(select(.isCrossRepository == false and (.headRefName | startswith("action/upgrade-to-")))) | first | if . then [.number, .headRefName, .title] | @tsv else empty end')

if [ -n "$OPEN_PR" ]; then
	IFS=$'\t' read -r PR_NUMBER BRANCH_NAME PR_TITLE <<< "$OPEN_PR"
	echo "[action-update-wordpress-plugin] Reusing pull request #$PR_NUMBER: $PR_TITLE"
	git fetch origin "$BRANCH_NAME"
	git checkout -B "$BRANCH_NAME" "origin/$BRANCH_NAME"

	PREVIOUS_VERSION=$(grep "Tested up to:" "$PLUGIN_FILE" | awk '{print $NF}')
	PREVIOUS_VERSION=$(normalize_version "$PREVIOUS_VERSION")

	if [ "$WP_NORMALIZED_VERSION" == "$PREVIOUS_VERSION" ]; then
		BRANCH_VERSION=${BRANCH_NAME#action/upgrade-to-}
		BRANCH_VERSION=$(normalize_version "${BRANCH_VERSION%-*}")

		if [ "$BRANCH_VERSION" != "$WP_NORMALIZED_VERSION" ]; then
			PREVIOUS_VERSION=$(git show HEAD^:"${PLUGIN_FILE#./}" 2>/dev/null | grep "Tested up to:" | awk '{print $NF}')
			PREVIOUS_VERSION=$(normalize_version "${PREVIOUS_VERSION:-$BRANCH_VERSION}")
			update_pull_request
			echo "[action-update-wordpress-plugin] Pull request #$PR_NUMBER metadata updated"
		else
			echo "[action-update-wordpress-plugin] Pull request #$PR_NUMBER already targets WordPress $WP_VERSION, no update needed."
		fi

		exit 0
	fi
else
	PR_NUMBER=""
	PREVIOUS_VERSION="$LATEST_VERSION"
	BRANCH_NAME="action/upgrade-to-$WP_VERSION-$(date +%s)"
	git checkout -b "$BRANCH_NAME"
fi

# npm ci if UPGRADE_DEPENDENCIES is not equal to "false".
if [ "$UPGRADE_DEPENDENCIES" != "false" ]; then
	# Check if package.json exists.
	if [ ! -f "package.json" ]; then
		echo "[action-update-wordpress-plugin] package.json does not exist, skipping dependency upgrade."
	else
		npm ci

		# Run the "npx wp-scripts packages-update" command.
		npx wp-scripts packages-update --dist-tag="wp-$WP_VERSION"
	fi
else
	echo "[action-update-wordpress-plugin] Skipping dependency upgrade."
fi

# Replace the 'Tested up to' version in the plugin file.
sed -i "s/Tested up to: .*/Tested up to: $WP_VERSION/g" "$PLUGIN_FILE"

# Setup Git.
git config --global user.email "$GITHUB_ACTOR@users.noreply.github.com"
git config --global user.name "$GITHUB_ACTOR"

# Commit all the changes.
git add -A && git commit -m "Upgrade plugin to $WP_VERSION"
git push origin "$BRANCH_NAME"

if [ -n "$PR_NUMBER" ]; then
	update_pull_request
	echo "[action-update-wordpress-plugin] Pull request #$PR_NUMBER updated"
else
	gh pr create --title "Upgrade plugin to WordPress $WP_VERSION" --body "- [ ] Test plugin against WordPress \`$WP_VERSION\`" --head "$BRANCH_NAME"
	echo "[action-update-wordpress-plugin] Pull request created"
fi

exit 0
