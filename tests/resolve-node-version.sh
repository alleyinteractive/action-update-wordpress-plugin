#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
	echo "not ok - $1"
	exit 1
}

setup_case() {
	TEST_DIR=$(mktemp -d)
	export TEST_DIR
	export GITHUB_OUTPUT="$TEST_DIR/output"
	: > "$GITHUB_OUTPUT"
}

teardown_case() {
	rm -rf "$TEST_DIR"
}

assert_resolves() {
	local input=$1
	local expected=$2
	local resolved

	setup_case

	NODE_VERSION="$input" "$ROOT_DIR/resolve-node-version.sh" > "$TEST_DIR/stdout.log" 2> "$TEST_DIR/stderr.log"
	resolved=$(grep '^version=' "$GITHUB_OUTPUT" | cut -d= -f2-)

	if [ "$resolved" != "$expected" ]; then
		fail "Expected node-version '$input' to resolve to '$expected', got '$resolved'"
	fi

	teardown_case
	echo "ok - resolves '$input' to '$expected'"
}

assert_warns() {
	local input=$1

	setup_case

	NODE_VERSION="$input" "$ROOT_DIR/resolve-node-version.sh" > "$TEST_DIR/stdout.log" 2> "$TEST_DIR/stderr.log"

	grep -Fq '::warning::' "$TEST_DIR/stdout.log" || fail "Expected node-version '$input' to emit a warning"

	teardown_case
	echo "ok - warns about '$input'"
}

assert_does_not_warn() {
	local input=$1

	setup_case

	NODE_VERSION="$input" "$ROOT_DIR/resolve-node-version.sh" > "$TEST_DIR/stdout.log" 2> "$TEST_DIR/stderr.log"

	if grep -Fq '::warning::' "$TEST_DIR/stdout.log"; then
		fail "Expected node-version '$input' not to emit a warning"
	fi

	teardown_case
	echo "ok - does not warn about '$input'"
}

assert_resolves 'lts' 'lts/*'
assert_resolves 'LTS' 'lts/*'
assert_resolves 'lts/' 'lts/*'
assert_resolves 'lts/latest' 'lts/*'
assert_resolves ' lts ' 'lts/*'
assert_resolves '' 'lts/*'
assert_resolves 'lts/*' 'lts/*'
assert_resolves 'lts/jod' 'lts/jod'
assert_resolves '20' '20'
assert_resolves '20.11.1' '20.11.1'
assert_resolves 'latest' 'latest'
assert_resolves ' 22 ' '22'

assert_warns 'lts'
assert_warns 'lts/latest'
assert_does_not_warn 'lts/*'
assert_does_not_warn '20'
assert_does_not_warn ''

setup_case
NODE_VERSION='' "$ROOT_DIR/resolve-node-version.sh" > "$TEST_DIR/stdout.log"
grep -Fq 'Using Node.js version: lts/*' "$TEST_DIR/stdout.log" || fail "Expected the resolved version to be logged"
teardown_case
echo "ok - logs the resolved version"
