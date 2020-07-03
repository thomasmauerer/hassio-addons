# Home Assistant Add-on: Samba Backup

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

![Current version][version]

Create snapshots and store them on a Samba share.

## About

This add-on lets you automatically create Home Assistant snapshots and store them on a Samba share. This does work with Samba shares that require authentication by username/password or allow guest access.

## Installation

1. Navigate in your Home Assistant frontend to **Supervisor** -> **Add-on Store** and add this URL as an additional repository: `https://github.com/thomasmauerer/hassio-addons`
2. Find the "Samba Backup" add-on and click the "INSTALL" button.
3. Configure the add-on and click on "START".

## Configuration

The `host` and the `share` parameters are always required. If you do not specify any username and password, the Samba share has to be configured to allow guest access for this to work.

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
  "backup_name": "{type} Snapshot (Samba Backup) {date}"
}
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `host`

The hostname/URL of the Samba share.

### Option: `share`

The name of the Samba share.

### Option: `target_dir`

The target directory on the Samba share in which the snapshots will be stored. If not specified the snapshots will be stored in the root directory.

**Note**: _The directory must exist and write permissions must be granted._

### Option: `username`

The username to access the Samba share.

### Option: `password`

The password to access the Samba share.

### Option: `keep_local`

The number of local snapshots to be preserved. Set `all` if you do not want to delete any snapshots.

**Note**: _Snapshots that were not created with this add-on will be deleted as well._

### Option: `keep_remote`

The number of snapshots to be preserved on the Samba share. Set `all` if you do not want to delete any snapshots.

### Option: `trigger_time`

The time at which a backup will be triggered. If a pure time-based schedule does not suit your needs, you can also write your own Home Assistant automation to trigger this add-on. You just have to do two things:

1. Set `trigger_time` to `manual`
2. Include the following in your automation

```yaml
service: hassio.addon_stdin
data:
  addon: 15d21743_samba_backup
  input: trigger
```

### Option: `trigger_days`

The days on which a backup will be triggered. If `trigger_time` is set to `manual` this parameter will not have any effect.

### Option: `exclude_addons`

The slugs of add-ons to exclude in the snapshot. This will trigger a partial snapshot if specified. You can find out the correct slugs by clicking on an installed add-on and looking at the URL e.g. `core_ssh`.

### Option: `exclude_folders`

The folders to exclude in the snapshot. This will trigger a partial snapshot if specified. Possible values are `homeassistant`, `ssl`, `share` and `addons/local`.

### Option: `backup_name`

The custom name for the snapshots. You can either use a fixed text or include the following name patterns which will automatically be converted to its real values.

- `{type}`: Full or Partial
- `{version}`: The current version of Home Assistant
- `{date}`: The current date and timestamp

_Example_: "{type} Snapshot {version} {date}" might end up as "Full Snapshot 0.110.4 2020-06-05 12:00"

**Note**: _This only affects the snapshot names, not the file names itself._

### Option: `backup_password`

If specified the snapshots will be password-protected.

### Option: `log_level`

Controls the verbosity of log output produced by this add-on. Possible values are `debug`, `info` (default), `warning` and `error`.

### Option: `mqtt_host`

If using an external mqtt broker, the hostname/URL of the broker. See [Status Notifications](#status-notifications) for additional infos.

**Note**: _Do not set this option if you want to use the (on-device) Mosquitto broker addon._

### Option: `mqtt_username`

If using an external mqtt broker, the username to authenticate with the broker.

### Option: `mqtt_password`

If using an external mqtt broker, the password to authenticate with the broker.

### Option: `mqtt_port`

If using an external mqtt broker, the port of the broker. If not specified the default port 1883 will be used.

### Option: `mqtt_topic`

The topic to which status updates will be published. You can only control the root topic with this option, the subtopic is fixed!

_Example_: samba_backup/status: "samba_backup" is the root topic, whereas "status" is the subtopic.


### Status Notifications

This add-on will (optionally) publish its current status via mqtt on topic `samba_backup/status`. The recommended way of setting this up is to install the official Mosquitto broker add-on. If you are using an Access Control List, make sure to add the following two lines. Otherwise you won't receive anything on the mqtt topic. No additional configuration is required!

```
user addons
topic readwrite samba_backup/#
```

Auto-configuration will **not work** if you use an external mqtt broker instead of the Mosquitto add-on. In this case you have to specify the mqtt configuration options as documented above.


The status will be one of the following:

- `IDLE`: Samba Backup is waiting for the trigger
- `RUNNING`: A backup is currently in progress
- `SUCCEEDED`: The backup was successful
- `FAILED`: The backup was not successful

You can use this information in Home Assistant, e.g. to send out a notification if a backup failed. Just configure a mqtt sensor and use it in an automation.

```yaml
sensor:
- platform: mqtt
  name: "Samba Backup"
  state_topic: "samba_backup/status"
```

**Note**: _A failed backup will also exit the entire add-on. Please check the logs in that case and restart the add-on._

## Credits
This add-on is inspired by [hassio-remote-backup](https://github.com/overkill32/hassio-remote-backup), but does not require a ssh connection and also offers more features.

## Want to contribute?

Any kind of help or useful input/feedback is appreciated! If you want to create a pull request, please create it against the `dev` branch. You can also check the [forum thread](https://community.home-assistant.io/t/samba-backup-create-and-store-snapshots-on-a-samba-share/199471) of this add-on for infos and discussions.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[version]: https://img.shields.io/badge/version-v2.5-blue.svg
