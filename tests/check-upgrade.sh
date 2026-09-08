#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
	echo "not ok - $1"
	exit 1
}

assert_contains() {
	local file=$1
	local expected=$2

	grep -Fq -- "$expected" "$file" || fail "Expected $file to contain: $expected"
}

assert_not_contains() {
	local file=$1
	local unexpected=$2

	if grep -Fq -- "$unexpected" "$file"; then
		fail "Expected $file not to contain: $unexpected"
	fi
}

setup_case() {
	TEST_DIR=$(mktemp -d)
	export TEST_DIR
	export COMMAND_LOG="$TEST_DIR/commands.log"
	export PLUGIN_FILE="$TEST_DIR/plugin.php"
	export UPGRADE_DEPENDENCIES=false
	export GITHUB_ACTOR=github-actions
	export GH_PR_LIST_OUTPUT=${1:-[]}
	unset CHECKOUT_PLUGIN_VERSION GH_API_FAIL GH_PR_COMMENTS_OUTPUT GH_PR_LIST_FAIL PARENT_PLUGIN_VERSION WORDPRESS_VERSION

	printf '%s\n' '<?php' ' * Tested up to: 6.7.0' > "$PLUGIN_FILE"
	: > "$COMMAND_LOG"
	mkdir "$TEST_DIR/bin"

	for command in curl date gh git sed sort; do
		ln -s "$ROOT_DIR/tests/stubs/$command" "$TEST_DIR/bin/$command"
	done

	export PATH="$TEST_DIR/bin:$PATH"
}

teardown_case() {
	rm -rf "$TEST_DIR"
}

test_updates_existing_pull_request() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.7.0-1700000000","title":"Upgrade plugin to WordPress 6.7.0","isCrossRepository":false}]'

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$COMMAND_LOG" "gh pr list --app github-actions --state open --limit 1000 --json number,headRefName,title,isCrossRepository"
	assert_contains "$COMMAND_LOG" "git fetch origin action/upgrade-to-6.7.0-1700000000"
	assert_contains "$COMMAND_LOG" "git checkout -B action/upgrade-to-6.7.0-1700000000 origin/action/upgrade-to-6.7.0-1700000000"
	assert_contains "$COMMAND_LOG" "git push origin action/upgrade-to-6.7.0-1700000000"
	assert_contains "$COMMAND_LOG" "gh pr edit 42 --title Upgrade plugin to WordPress 6.8.0"
	assert_contains "$COMMAND_LOG" 'gh pr comment 42 --body Updated this pull request from WordPress `6.7.0` to `6.8.0` instead of opening a new pull request. <!-- action-update-wordpress-plugin:6.8.0 -->'
	assert_not_contains "$COMMAND_LOG" "gh pr create"

	teardown_case
	echo "ok - updates an existing pull request"
}

test_skips_existing_pull_request_at_current_version() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.8.0-1700000000","title":"Upgrade plugin to WordPress 6.8.0","isCrossRepository":false}]'
	export CHECKOUT_PLUGIN_VERSION=6.8.0

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$TEST_DIR/output.log" "Pull request #42 already targets WordPress 6.8.0, no update needed."
	assert_not_contains "$COMMAND_LOG" "git commit"
	assert_not_contains "$COMMAND_LOG" "git push"
	assert_not_contains "$COMMAND_LOG" "gh pr edit"
	assert_not_contains "$COMMAND_LOG" "gh pr comment"

	unset CHECKOUT_PLUGIN_VERSION
	teardown_case
	echo "ok - skips an existing pull request at the current version"
}

test_creates_pull_request_when_none_exists() {
	setup_case

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$COMMAND_LOG" "git checkout -b action/upgrade-to-6.8.0-1700000000"
	assert_contains "$COMMAND_LOG" "git push origin action/upgrade-to-6.8.0-1700000000"
	assert_contains "$COMMAND_LOG" "gh pr create --title Upgrade plugin to WordPress 6.8.0"
	assert_not_contains "$COMMAND_LOG" "gh pr edit"
	assert_not_contains "$COMMAND_LOG" "gh pr comment"

	teardown_case
	echo "ok - creates a pull request when none exists"
}

test_treats_equivalent_version_formats_as_current() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.8-1700000000","title":"Upgrade plugin to WordPress 6.8","isCrossRepository":false}]'
	export CHECKOUT_PLUGIN_VERSION=6.8.0
	export WORDPRESS_VERSION=6.8

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$TEST_DIR/output.log" "Pull request #42 already targets WordPress 6.8, no update needed."
	assert_not_contains "$COMMAND_LOG" "git commit"
	assert_not_contains "$COMMAND_LOG" "git push"

	unset CHECKOUT_PLUGIN_VERSION WORDPRESS_VERSION
	teardown_case
	echo "ok - treats equivalent version formats as current"
}

test_repairs_pull_request_metadata_after_push_succeeds() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.7.0-1700000000","title":"Upgrade plugin to WordPress 6.7.0","isCrossRepository":false}]'
	export CHECKOUT_PLUGIN_VERSION=6.8.0
	export PARENT_PLUGIN_VERSION=6.7.0

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$COMMAND_LOG" "gh pr edit 42 --title Upgrade plugin to WordPress 6.8.0"
	assert_contains "$COMMAND_LOG" 'gh pr comment 42 --body Updated this pull request from WordPress `6.7.0` to `6.8.0` instead of opening a new pull request. <!-- action-update-wordpress-plugin:6.8.0 -->'
	assert_not_contains "$COMMAND_LOG" "git commit"
	assert_not_contains "$COMMAND_LOG" "git push"

	unset CHECKOUT_PLUGIN_VERSION PARENT_PLUGIN_VERSION
	teardown_case
	echo "ok - repairs pull request metadata after push succeeds"
}

test_does_not_duplicate_update_note_on_retry() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.7.0-1700000000","title":"Upgrade plugin to WordPress 6.8.0","isCrossRepository":false}]'
	export CHECKOUT_PLUGIN_VERSION=6.8.0
	export PARENT_PLUGIN_VERSION=6.7.0
	export GH_PR_COMMENTS_OUTPUT='Updated previously. <!-- action-update-wordpress-plugin:6.8.0 -->'

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$COMMAND_LOG" "gh pr edit 42 --title Upgrade plugin to WordPress 6.8.0"
	assert_not_contains "$COMMAND_LOG" "gh pr comment"

	unset CHECKOUT_PLUGIN_VERSION PARENT_PLUGIN_VERSION GH_PR_COMMENTS_OUTPUT
	teardown_case
	echo "ok - does not duplicate the update note on retry"
}

test_selects_newest_same_repository_action_pull_request() {
	setup_case '[{"number":45,"headRefName":"action/upgrade-to-6.7.0-4","title":"Fork","isCrossRepository":true},{"number":44,"headRefName":"unrelated","title":"Unrelated","isCrossRepository":false},{"number":42,"headRefName":"action/upgrade-to-6.7.0-2","title":"Newest match","isCrossRepository":false},{"number":41,"headRefName":"action/upgrade-to-6.7.0-1","title":"Older match","isCrossRepository":false}]'

	"$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log"

	assert_contains "$COMMAND_LOG" "git fetch origin action/upgrade-to-6.7.0-2"
	assert_contains "$COMMAND_LOG" "gh pr edit 42"
	assert_not_contains "$COMMAND_LOG" "git fetch origin action/upgrade-to-6.7.0-4"
	assert_not_contains "$COMMAND_LOG" "gh pr edit 45"

	teardown_case
	echo "ok - selects the newest same-repository action pull request"
}

test_stops_when_pull_request_lookup_fails() {
	setup_case
	export GH_PR_LIST_FAIL=true

	if "$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log" 2>&1; then
		fail "Expected pull request lookup failure to stop the action"
	fi

	assert_not_contains "$COMMAND_LOG" "git checkout -b"
	assert_not_contains "$COMMAND_LOG" "gh pr create"

	teardown_case
	echo "ok - stops when pull request lookup fails"
}

test_stops_when_comment_lookup_fails() {
	setup_case '[{"number":42,"headRefName":"action/upgrade-to-6.7.0-1700000000","title":"Upgrade plugin to WordPress 6.7.0","isCrossRepository":false}]'
	export GH_API_FAIL=true

	if "$ROOT_DIR/check-upgrade.sh" > "$TEST_DIR/output.log" 2>&1; then
		fail "Expected comment lookup failure to stop the action"
	fi

	assert_not_contains "$COMMAND_LOG" "gh pr comment"

	teardown_case
	echo "ok - stops when comment lookup fails"
}

test_updates_existing_pull_request
test_skips_existing_pull_request_at_current_version
test_creates_pull_request_when_none_exists
test_treats_equivalent_version_formats_as_current
test_repairs_pull_request_metadata_after_push_succeeds
test_does_not_duplicate_update_note_on_retry
test_selects_newest_same_repository_action_pull_request
test_stops_when_pull_request_lookup_fails
test_stops_when_comment_lookup_fails
