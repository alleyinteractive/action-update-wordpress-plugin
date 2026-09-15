# Update WordPress Plugin Action

Automatically update your
[alleyinteractive/create-wordpress-plugin](https://github.com/alleyinteractive/create-wordpress-plugin)-based
plugins to the latest WordPress version whenever core releases a new version.

When a new version of WordPress is released, this action will automatically bump
the `Tested up to` version of the plugin. You can also run the [`packages-update`
npm
script](https://github.com/alleyinteractive/create-wordpress-plugin#updating-wp-dependencies)
to update the WordPress plugin dependencies to match the latest WordPress version.

## Usage

By default, the plugin will look for a `plugin.php` file in the root of the
repository. If your plugin's main file is named something else, you can specify
the name of the file using the `plugin-file` input.

```yaml
name: Update WordPress Plugin

on:
  pull_request:
  schedule:
    - cron: '0 */6 * * *'

permissions:
  contents: write
  pull-requests: write

jobs:
  update-plugin:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v5
    - uses: alleyinteractive/action-update-wordpress-plugin@v2
      with:
        plugin-file: 'plugin.php'
        upgrade-npm-dependencies: "true"
        node-version: '20'  # Specify the Node.js version if not lts/*

```

The action assumes that a `package-lock.json` file exists in the root of the
repository to run `npm ci`.

When one or more open pull requests created by this action already exist, the
action updates the newest pull request's branch, title, and checklist instead
of opening another pull request. It also comments on the pull request with the
previous and new WordPress versions. Closed and merged pull requests are not
reused.

### Inputs

- `plugin-file` - The name of the plugin's main file. Defaults to `plugin.php`.
- `upgrade-npm-dependencies` - Whether or not to run the `packages-update` npm
  script. Defaults to `"true"`. Set to `"false"` to disable, which also skips
  the Node.js setup step entirely.
- `node-version` - The version of Node.js to use for running the action.
  Defaults to `"lts/*"`. Specify any version number or tag supported by
  [`actions/setup-node`](https://github.com/actions/setup-node#supported-version-syntax)
  (e.g., `18`, `20`, `lts/*`, `lts/jod`, `latest`). A bare `lts` is not valid
  syntax for `setup-node`; the action rewrites it to `lts/*` and logs a warning
  rather than failing.

### Versioning

The `v2` tag always points at the newest 2.x release, so `@v2` picks up fixes
automatically. Pin an exact tag such as `@v2.1.0` if you would rather review
each upgrade yourself.

`actions/setup-node@v7` requires an Actions runner on version 2.327.1 or later.
All GitHub-hosted runners meet this; self-hosted runners may need updating.


## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each release.

## Credits

This project is actively maintained by [Alley
Interactive](https://github.com/alleyinteractive). Like what you see? [Come work
with us](https://alley.com/careers/).

- [Sean Fisher](https://github.com/srtfisher)
- [All Contributors](../../contributors)

## License

The GNU General Public License (GPL) license. Please see [License File](LICENSE) for more information.
