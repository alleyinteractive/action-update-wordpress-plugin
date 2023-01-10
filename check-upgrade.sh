#!/bin/bash

# Automatically upgrade a plugin to match the latest WordPress version.

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
LATEST_VERSION=$(echo "$LATEST_VERSION" | awk -F. '{printf("%d.%d.%d\n", $1,$2,$3)}')

# Check if the latest version is set and not empty.
if [ -z "$LATEST_VERSION" ]; then
	echo "[action-update-wordpress-plugin] Latest version is not set."
	exit 1
fi

# Fetch the latest WordPress version from api.wordpress.org.
WP_VERSION=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')

# Early exist if they're the same version.
if [ "$WP_VERSION" == "$LATEST_VERSION" ]; then
	echo "[action-update-wordpress-plugin] Latest WordPress version and plugin-supported version are the same, no upgrade needed."
	exit 0
fi

echo "[action-update-wordpress-plugin] Latest WordPress version:        $WP_VERSION"
echo "[action-update-wordpress-plugin] Latest plugin supported version: $LATEST_VERSION"

# Check if the latest plugin version is less than the latest WordPress version.
# shellcheck disable=SC2001
if [ "$(echo "$LATEST_VERSION" | sed 's/\.//g')" -gt "$(echo "$WP_VERSION" | sed 's/\.//g')" ]; then
	echo "[action-update-wordpress-plugin] Plugin is already up-to-date, no upgrade needed."
	exit 0
fi

# Check if a pull request already exists with the gh cli.
if [ "$(gh pr list --search "Upgrade plugin to WordPress $WP_VERSION" --state "all" | wc -l)" -gt 0 ]; then
	echo "[action-update-wordpress-plugin] Pull request already exists, no upgrade needed."
	exit 0
fi

echo "[action-update-wordpress-plugin] Upgrading plugin to $WP_VERSION ..."

set -e

# Checkout a new branch including the current time
BRANCH_NAME="action/upgrade-to-$WP_VERSION-$(date +%s)"
git checkout -b "$BRANCH_NAME"

# npm ci if UPGRADE_DEPENDENCIES is not equal to "false".
if [ "$UPGRADE_DEPENDENCIES" != "false" ]; then
	# Check if package.json exists.
	if [ ! -f "package.json" ]; then
		echo "[action-update-wordpress-plugin] package.json does not exist, skipping dependency upgrade."
	else
		npm ci

		# Run the "npm run packages-update" command.
		npm run packages-update --dist-tag="wp-$WP_VERSION"
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

# Create a pull request.
gh pr create --title "Upgrade plugin to WordPress $WP_VERSION" --body "- [ ] Test plugin against WordPress \`$WP_VERSION\`" --head "$BRANCH_NAME"

echo "[action-update-wordpress-plugin] Pull request created"
exit 0
