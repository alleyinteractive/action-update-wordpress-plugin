#!/bin/bash

# Automatically upgrade a plugin to match the latest WordPress version.

# Ensure PLUGIN_FILE is set.
if [ -z "$PLUGIN_FILE" ]; then
	echo "PLUGIN_FILE is not set."
	exit 1
fi

# Check if PLUGIN_FILE exists.
if [ ! -f "$PLUGIN_FILE" ]; then
	echo "$PLUGIN_FILE does not exist."
	exit 1
fi

# Extract the latest version from the plugin file.
LATEST_VERSION=$(grep "Tested up to:" "$PLUGIN_FILE" | awk '{print $NF}')

# Ensure latest version is always in x.x.x format (e.g. 5.2.1 vs 5.2).
LATEST_VERSION=$(echo "$LATEST_VERSION" | awk -F. '{printf("%d.%d.%d\n", $1,$2,$3)}')

# Check if the latest version is set and not empty.
if [ -z "$LATEST_VERSION" ]; then
	echo "Latest version is not set."
	exit 1
fi

# Fetch the latest WordPress version from api.wordpress.org.
WP_VERSION=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')

# Early exist if they're the same version.
if [ "$WP_VERSION" == "$LATEST_VERSION" ]; then
	echo "Latest WordPress version and plugin-supported version are the same, no upgrade needed."
	exit 0
fi

echo "Latest WordPress version:        $WP_VERSION"
echo "Latest plugin supported version: $LATEST_VERSION"

# Check if the latest plugin version is less than the latest WordPress version.
if [ "$(echo "$LATEST_VERSION" | sed 's/\.//g')" -gt "$(echo "$WP_VERSION" | sed 's/\.//g')" ]; then
	echo "Plugin is already up-to-date, no upgrade needed."
	exit 0
fi

# Check if a pull request already exists with the gh cli.
if [ "$(gh pr list --search "Upgrade plugin to $WP_VERSION" | wc -l)" -gt 0 ]; then
	echo "Pull request already exists, no upgrade needed."
	exit 0
fi

echo "Upgrading plugin to $WP_VERSION ..."

set -e

# Checkout a new branch.
git checkout -b "action/upgrade-to-$WP_VERSION"

# npm ci if UPGRADE_DEPENDENCIES is not equal to "false".
if [ "$UPGRADE_DEPENDENCIES" != "false" ]; then
	npm ci

	# Run the "npm run packages-update" command.
	npm run packages-update --dist-tag=wp-$WP_VERSION
else
	echo "Skipping dependency upgrade."
fi

# Replace the 'Tested up to' version in the plugin file.
sed -i "" "s/Tested up to: .*/Tested up to: $WP_VERSION/g" plugin.php

exit 0

# Commit all the changes.
git add .
git commit -m "Upgrade plugin to $WP_VERSION"
git push origin "action/upgrade-to-$WP_VERSION"

# Create a pull request.
gh pr create --title "Upgrade plugin to $WP_VERSION" --body "Upgrade plugin to $WP_VERSION" --head "action/upgrade-to-$WP_VERSION"

echo "Pull request created."
