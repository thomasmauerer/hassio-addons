# Home Assistant Add-on: Samba Backup

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

![Current version][version]

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
|`keep_local`|Yes|The number of local snapshots to be preserved. Set `all` if you do not want to delete any snapshots. Note that this will also delete snapshots that were not created with this add-on.|
|`keep_remote`|Yes|The number of snapshots to be preserved on the Samba share. Set `all` if you do not want to delete any snapshots.|
|`trigger_time`|Yes|The time when to automatically trigger a backup. See below for advanced options.|
|`trigger_days`|Yes|The days on which a backup will be triggered.|
|`exclude_addons`|No|The slugs of add-ons to exclude in the snapshot. This will trigger a partial snapshot if specified. You can find out the correct slugs by clicking on an installed add-on and looking at the URL e.g. `core_ssh`.|
|`exclude_folders`|No|The folders to exclude in the snapshot. This will trigger a partial snapshot if specified. Possible values are `homeassistant`, `ssl`, `share` and `addons/local`.|
|`backup_name`|No|The custom name for the snapshots. See below for advanced options.|
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
  "trigger_time": "04:00",
  "trigger_days": ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],
  "exclude_addons": ["core_ssh", "core_duckdns"],
  "exclude_folders": ["share"],
  "backup_name": "{type} Snapshot (Samba Backup) {date}",
  "backup_password": "my-$tr0nG-pwd",
}
```

### What if I don't like the names of the snapshots?

No problem, you can customize the names with the `backup_name` variable. You can either use a fixed text or include the following name patterns which will automatically be converted to its real values.

- `{type}`: Full or Partial
- `{version}`: The current version of Home Assistant
- `{date}`: The current date and timestamp

_Example_: "{type} Snapshot {version} {date}" might end up as "Full Snapshot 0.110.4 2020-06-05 12:00"


### What if the supported triggers do not suit my needs?

Maybe you want some advanced trigger based on a specific Home Assistant event? No problem, you can still create your own Home Assistant automation to trigger this add-on. You just have to do two things:

1. Set `trigger_time` to *manual*
2. Include the following in your automation
```yaml
  service: hassio.addon_stdin
  data:
    addon: 15d21743_samba_backup
    input: trigger
```

## Credits
This add-on is inspired by [hassio-remote-backup](https://github.com/overkill32/hassio-remote-backup), but does not require a ssh connection and also offers more features.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[version]: https://img.shields.io/badge/version-v2.1-blue.svg
