# Home Assistant Add-on: Samba Backup

Create snapshots and store them on a Samba share.

## Configuration Options

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

The time at which a backup will be triggered. The input must be given in format 'HH:MM', e.g. '04:00' which means 4 am. You can also use your own Home Assistant automations to trigger a backup - see [Manual Triggers](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#manual-triggers) for more information. If you want to disable the time-based schedule completely, set the option to `manual`.

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

### Option: `compatibility_mode`

Set this option to `true` if you need to connect to shares that only support old legacy SMB protocols. Note that this option is not recommended, since these protocols are known to be out-dated, insecure and slow.

### Option: `log_level`

Controls the verbosity of log output produced by this add-on. Possible values are `debug`, `info` (default), `warning` and `error`.

### Option: `mqtt_host`

If using an external mqtt broker, the hostname/URL of the broker. See [MQTT Status Notifications](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#mqtt-status-notifications) for additional infos.

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

## Home Assistant Sensor

This add-on includes a sensor for Home Assistant which reflects the current status and additionally has some useful statistics within its attributes. No configuration is necessary in order to use the sensor. The name of the sensor is `sensor.samba_backup`.


The state of the sensor will be one of the following:

- `IDLE`: Samba Backup is waiting for the trigger
- `RUNNING`: A backup is currently in progress
- `SUCCEEDED`: The backup was successful
- `FAILED`: The backup was not successful


The sensor includes the following attributes:

- `backups local`: The current number of snapshots available on the device
- `backups remote`: The current number of snapshots available on the Samba share
- `total backups succeeded`: The total number of successful backups made with this add-on
- `total backups failed`: The total number of failed backups
- `last backup`: The date of the last successful backup


There is a known limitation that the sensor will be unavailable if you restart Home Assistant. This is caused by the way Home Assistant handles sensors which are not backed up by an entity, but instead come from an add-on or AppDaemon. You can easily fix that with an automation that triggers at startup:


```yaml
automation:
- alias: Restore Samba Backup sensor on startup
  trigger:
  - event: start
    platform: homeassistant
  action:
  - service: hassio.addon_stdin
    data:
      addon: 15d21743_samba_backup
      input: restore-sensor
  mode: single
```

_Automation to restore the sensor when Home Assistant restarts_


## MQTT Status Notifications

**!!DEPRECATED!! Please switch to the new [Home Assistant Sensor](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#home-assistant-sensor).**

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


## Manual Triggers

Apart from a time-based schedule, this add-on also supports manual triggers from a Home Assistant automation or script. If you only want manual triggers, you can set `trigger_time` to `manual`.

The easiest way to trigger a manual backup is by using the `hassio.addon_stdin` service call in a script:

```yaml
service: hassio.addon_stdin
data:
  addon: 15d21743_samba_backup
  input: trigger
```

_Simple trigger_

The configuration options that directly affect the snapshot creation are overwritable for a single run: `exclude_addons`, `exclude_folders`, `backup_name` and `backup_password`. To overwrite any of these options, you have to use an extended syntax - `command` has to be `trigger`. See the following example:

```yaml
service: hassio.addon_stdin
data:
  addon: 15d21743_samba_backup
  input:
    command: trigger
    backup_name: My overwritten snapshot name {date}
    exclude_addons: [core_mariadb, core_deconz]
```

_Extended trigger_
