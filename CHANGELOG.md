# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-09-15

### Added

- Reuse the newest open, same-repository upgrade pull request opened by the `github-actions` app instead of opening a duplicate one. The reused pull request has its branch, title, and checklist updated, and receives a single idempotent comment recording the previous and new WordPress versions. Closed and merged pull requests are never reused. ([#13](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/13))
- Repair pull request metadata on a retry when a previous run pushed its commit but failed before updating the pull request. ([#13](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/13))
- Behavior test suites for `check-upgrade.sh` and `resolve-node-version.sh`, run in CI alongside ShellCheck. ([#13](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/13))
- A `Update Major Version Tag` workflow that repoints the `vX` tag at each published stable release, so `@v2` always resolves to the newest 2.x release.

### Changed

- Skip the Node.js setup entirely when `upgrade-npm-dependencies` is `"false"`. The action only needs Node.js to run `npm ci` and `wp-scripts packages-update`, so workflows that just bump the `Tested up to` header no longer depend on `actions/setup-node` at all.
- Upgrade `actions/setup-node` from v3 to v7. v3 targets Node.js 20, which GitHub has deprecated and now force-runs on Node.js 24. This requires an Actions runner on version 2.327.1 or later, which all GitHub-hosted runners satisfy.
- Pass `package-manager-cache: false` to `actions/setup-node`. v5 began caching automatically when `package.json` declares a `packageManager` field, which would reintroduce the `npm ci` failure fixed in 1.0.2 for plugins without a `package-lock.json`.
- Abort instead of continuing when a GitHub API lookup fails, so a transient error cannot cause a duplicate pull request. ([#13](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/13))
- Move the changelog out of `README.md` and into this file.

### Fixed

- Accept `lts`, `lts/`, and `lts/latest` as values for the `node-version` input and resolve them to `lts/*`. `actions/setup-node` does not understand those spellings and fails with `Unable to find Node version 'lts'`. This was the default in 2.0.0 and is still what the 2.0.0 README documents, so any workflow that copied it or pinned `@v2.0.0` hits the failure.

## [2.0.1] - 2026-01-23

### Fixed

- Change the default `node-version` from `lts` to `lts/*`, the syntax `actions/setup-node` expects. ([#12](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/12))

## [2.0.0] - 2024-04-26

### Added

- A `node-version` input for selecting the Node.js version the action runs under. ([#10](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/10))

### Changed

- **Breaking:** the action no longer pins Node.js 16. It now uses the `node-version` input, which defaults to the current LTS release. ([#10](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/10))

## [1.2.1] - 2023-04-04

### Fixed

- Correct the semantic version comparison used to decide whether an upgrade is needed. ([#6](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/6))

## [1.2.0] - 2023-03-07

### Changed

- Run `npx wp-scripts packages-update` instead of `npm run packages-update`, so the action no longer depends on the plugin defining that npm script. ([#4](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/4))

## [1.1.0] - 2023-01-10

### Changed

- Check that `package.json` exists before running `npm ci`, even when `upgrade-npm-dependencies` is `true`. ([#3](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/3))

## [1.0.2] - 2023-01-10

### Fixed

- Disable npm caching, which broke `npm ci` for plugins without a `package-lock.json`. ([#2](https://github.com/alleyinteractive/action-update-wordpress-plugin/pull/2))

## [1.0.1] - 2022-12-15

### Changed

- No functional changes. Retagged for the GitHub Marketplace listing.

## [1.0.0] - 2022-12-12

### Added

- Initial release. Bumps a plugin's `Tested up to` header to the latest WordPress version, optionally updates its WordPress npm dependencies, and opens a pull request with the result.

[Unreleased]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.2.1...v2.0.0
[1.2.1]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/alleyinteractive/action-update-wordpress-plugin/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/alleyinteractive/action-update-wordpress-plugin/releases/tag/v1.0.0
