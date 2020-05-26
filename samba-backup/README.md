# Home Assistant Add-on: Samba Backup

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

Create snapshots and store them on a Samba share.

## About

This add-on lets you automatically create Home Assistant snapshots and store them on a Samba share. This does work with Samba shares that require authentication by username/password or allow guest access.

## Installation

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store** and add this URL as an additional repository: `https://github.com/thomasmauerer/hassio-addons`
2. Find the "Samba Backup" add-on and click the "INSTALL" button.
3. Configure the add-on and click on "START" and/or use it in an automation.

## Configuration

The `host` and the `share` parameters are always required. If you do not specify any username and password, the Samba share has to be configured to allow guest access for this to work.

|Parameter|Required|Description|
|---------|--------|-----------|
|`host`|Yes|The hostname/URL of the Samba share.|
|`share`|Yes|The name of the Samba share.|
|`target_dir`|No|The target directory on the Samba share. If not specified the snapshots will be stored in the root directory.|
|`username`|No|The username to access the Samba share.|
|`password`|No|The password to access the Samba share.|
|`keep_local`|No|The number of local snapshots to be preserved. Set `all` if you do not want to delete any snapshots.|
|`keep_remote`|No|The number of snapshots to be preserved on the Samba share. Set `all` if you do not want to delete any snapshots.|
|`backup_password`|No|If specified the snapshots will be password-protected.|

_Example configuration_:
```json
{
  "host": "192.168.178.100",
  "share": "my-share",
  "target_dir": "backups/ha-backups",
  "username": "my-user",
  "password": "my-password",
  "keep_local": "14",
  "keep_remote": "30",
  "backup_password": "my-$tr0nG-pwd"
}
```

_Example automation to trigger a backup once per day_:
```yaml
automation:
  - alias: Auto Backup
    trigger:
    - at: 04:00:00
      platform: time
    action:
    - service: hassio.addon_start
      data:
        addon: 15d21743_samba_backup
```

## Credits
This add-on is inspired by [hassio-remote-backup](https://github.com/overkill32/hassio-remote-backup), but does not require a ssh connection and also offers more features.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
