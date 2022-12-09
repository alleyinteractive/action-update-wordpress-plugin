# Update WordPress Plugin Action

Automatically update your
[alleyinteractive/create-wordpress-plugin](https://github.com/alleyinteractive/create-wordpress-plugin)-based
plugins to the latest WordPress version whenever core releases a new version.

When a new version of WordPress is released, this action will automatically bump
the `Tested up to` version of the plugin. You can also run the [`packages-update`
npm
script](https://github.com/alleyinteractive/create-wordpress-plugin#updating-wp-dependencies)
to update the WordPress plugin dependencies to match the latest WordPress version.

### Usage

By default, the plugin will look for a `plugin.php` file in the root of the
repository. If your plugin's main file is named something else, you can specify
the name of the file using the `plugin-file` input.

```yaml
name: Update WordPress Plugin

on:
  schedule:
    - cron: '0 0 * * *'

jobs:
  update-plugin:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: alleyinteractive/action-update-wordpress-plugin@feature
      with:
        plugin-file: 'plugin.php'
        upgrade-npm-dependencies: "true"
```

### Changelog

#### 1.0.0

- Initial release.

## Credits

This project is actively maintained by [Alley
Interactive](https://github.com/alleyinteractive). Like what you see? [Come work
with us](https://alley.com/careers/).

- [Sean Fisher](https://github.com/srtfisher)
- [All Contributors](../../contributors)

## License

The GNU General Public License (GPL) license. Please see [License File](LICENSE) for more information.
