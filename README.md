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
    - uses: actions/checkout@v3
    - uses: alleyinteractive/action-update-wordpress-plugin@v1
      with:
        plugin-file: 'plugin.php'
        upgrade-npm-dependencies: "true"
        node-version: '20'  # Specify the Node.js version if not lts

```

The action assumes that a `package-lock.json` file exists in the root of the
repository to run `npm ci`.

### Inputs

- `plugin-file` - The name of the plugin's main file. Defaults to `plugin.php`.
- `upgrade-npm-dependencies` - Whether or not to run the `packages-update` npm
  script. Defaults to `"true"`. Set to `"false"` to disable.
- `node-version` - The version of Node.js to use for running the action. Defaults to `"lts/*"`. Specify any version number or tag supported by actions/setup-node@v3 (e.g., `18`, `20`, `lts/*`, `latest`, etc.).


## Changelog

### 2.0.1

- Fixes default node version in action from `lts` to `lts/*`, which is the syntax expected by the `setup-node` action.

### 2.0.0

- Update action to allow node-version input (defaults to `lts`). *This is a breaking change*, as the action previously used Node.js 16.x.

### 1.2.1

- Fix semvar comparsion logic.

### 1.2.0

- Changes action to use `npx wp-scripts packages-update` instead of `npm run packages-update`.

### 1.1.0

- Update action to check if `package.json` exists before running `npm ci` (even
  if `upgrade-npm-dependencies` is set to `true`).

### 1.0.2

- Disable caching of NPM to fix issue with `npm ci` not working.

### 1.0.1

- No changes, just a new release to fix the release workflow.

### 1.0.0

- Initial release.

## Credits

This project is actively maintained by [Alley
Interactive](https://github.com/alleyinteractive). Like what you see? [Come work
with us](https://alley.com/careers/).

- [Sean Fisher](https://github.com/srtfisher)
- [All Contributors](../../contributors)

## License

The GNU General Public License (GPL) license. Please see [License File](LICENSE) for more information.
