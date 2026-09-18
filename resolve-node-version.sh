#!/bin/bash

set -o pipefail

# Resolve the node-version input into a value actions/setup-node understands.

VERSION=$(printf '%s' "${NODE_VERSION:-}" | tr -d '[:space:]')
NORMALIZED=$(printf '%s' "$VERSION" | tr '[:upper:]' '[:lower:]')

case "$NORMALIZED" in
	'')
		VERSION='lts/*'
		;;
	lts | lts/ | lts/latest)
		echo "::warning::[action-update-wordpress-plugin] node-version '$NODE_VERSION' is not a version actions/setup-node understands, using 'lts/*' instead."
		VERSION='lts/*'
		;;
esac

echo "[action-update-wordpress-plugin] Using Node.js version: $VERSION"
echo "version=$VERSION" >> "$GITHUB_OUTPUT"
