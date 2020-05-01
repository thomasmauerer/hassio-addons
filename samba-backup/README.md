# Home Assistant Add-on: Samba Backup

Create snapshots and store them on a Samba share.

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Suppor    ts armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Arch    itecture][i386-shield]

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

_Example configuration_:
```json
{
  "host": "192.168.178.100",
  "share": "my-share",
  "target_dir": "backups/ha-backups",
  "username": '',
  "password": ''
}
```

## Credits
This add-on is inspired by [hassio-remote-backup](https://github.com/overkill32/hassio-remote-backup), but does not require a ssh connection, but simply a Samba share.
