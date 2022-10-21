# Home Assistant Add-on: Samba Backup

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

![Current version][version]

[<img src="https://raw.githubusercontent.com/thomasmauerer/hassio-addons/master/samba-backup/images/donate-paypal.svg" width=200/>](https://www.paypal.com/donate/?hosted_button_id=LP732BXWCKM3C)

Create backups and store them on a Samba share.

## About

This add-on lets you automatically create Home Assistant backups and store them on a Samba share. This does work with Samba shares that require authentication by username/password or allow guest access.

## Installation

1. Navigate in your Home Assistant frontend to **Settings** -> **Add-ons** -> **Add-on Store** and add this URL as an additional repository: `https://github.com/thomasmauerer/hassio-addons`
2. Refresh your browser.
3. Find the "Samba Backup" add-on and click the "INSTALL" button.
4. Configure the add-on and click on "START".

## Configuration

The `host` and the `share` parameters are always required. If you do not specify any username and password, the Samba share has to be configured to allow guest access for this to work.

_Example configuration_:

```yaml
host: 192.168.178.100
share: my-share
target_dir: backups/ha-backups
username: my-user
password: my-password
keep_local: 5
keep_remote: 10
trigger_time: 04:00
trigger_days:
  - Mon
  - Wed
  - Fri
exclude_addons:
  - core_mariadb
exclude_folders:
  - media
backup_name: {type} Backup {date}
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

Please check the **[Documentation](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md)** for a complete reference of all configuration options.

## Want to contribute?

Any kind of help or useful input/feedback is appreciated! Please also check the [forum thread](https://community.home-assistant.io/t/samba-backup-create-and-store-snapshots-on-a-samba-share/199471) of this add-on for infos and discussions.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[version]: https://img.shields.io/badge/version-v5.2.0-blue.svg
