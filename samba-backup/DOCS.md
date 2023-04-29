# Home Assistant Add-on: Samba Backup

Create backups and store them on a Samba share.

## Configuration Options

### Option: `host`

The hostname/URL of the Samba share.

### Option: `share`

The name of the Samba share.

### Option: `target_dir`

The target directory on the Samba share in which the backups will be stored. The directory must be a folder *inside* your share. Leave this option empty if you do not use sub folders and instead want the backups to be stored in the root directory.

**Note**: _The directory must exist and write permissions must be granted._

### Option: `username`

The username to access the Samba share.

### Option: `password`

The password to access the Samba share.

### Option: `keep_local`

The number of local backups to be preserved. Set `all` if you do not want to delete any backups.

**Note**: _Backups that were not created with this add-on will be deleted as well._

### Option: `keep_remote`

The number of backups to be preserved on the Samba share. Set `all` if you do not want to delete any backups.

### Option: `trigger_time`

The time at which a backup will be triggered. The input must be given in format 'HH:MM', e.g. '04:00' which means 4 am. You can additionally use your own Home Assistant automations to trigger a backup - see [Manual Triggers](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#manual-triggers) for more information. If you want to disable the time-based schedule and only use your own automations, scripts, etc., set the option to `manual`.

### Option: `trigger_days`

The days on which a backup will be triggered. If `trigger_time` is set to `manual` this parameter will not have any effect.

### Option: `exclude_addons`

The slugs of add-ons to exclude in the backup. This will trigger a partial backup if specified. You can find out the correct slugs by clicking on an installed add-on and looking at the URL e.g. `core_ssh`.

### Option: `exclude_folders`

The folders to exclude in the backup. This will trigger a partial backup if specified. Possible values are `homeassistant`, `ssl`, `share`, `addons/local` and `media`.

### Option: `backup_name`

The custom name for the backups. You can either use a fixed text or include the following name patterns which will automatically be converted to its real values.

- `{type}`: Full or Partial
- `{version}`: The current version of Home Assistant
- `{date}`: The current date and timestamp

_Example_: "{type} Backup {version} {date}" might end up as "Full Backup 0.110.4 2020-06-05 12:00"

### Option: `backup_password`

If specified the backups will be password-protected.

### Option: `workgroup`

The workgroup to use for authentication. Only set this option if not using the default workgroup `WORKGROUP`.

### Option: `compatibility_mode`

Set this option to `true` if you need to connect to shares that only support old legacy SMB protocols. Note that this option is not recommended, since these protocols are known to be out-dated, insecure and slow.

### Option: `skip_precheck`

Set this option to `true` if you want to skip the checks about the availability/existance/permissions of the share. These checks are performed when the add-on starts. Only use this if you know what you are doing! Default value is `false`.

### Option: `log_level`

Controls the verbosity of log output produced by this add-on. Possible values are `debug`, `info` (default), `warning` and `error`.


## Home Assistant Sensor

This add-on includes a sensor for Home Assistant which reflects the current status and additionally has some useful statistics within its attributes. No configuration is necessary in order to use the sensor. The name of the sensor is `sensor.samba_backup`.


The state of the sensor will be one of the following:

- `IDLE`: Samba Backup is waiting for the trigger
- `RUNNING`: A backup is currently in progress
- `SUCCEEDED`: The backup was successful
- `FAILED`: The backup was not successful


The sensor includes the following attributes:

- `backups local`: The current number of backups available on the device
- `backups remote`: The current number of backups available on the Samba share
- `total backups succeeded`: The total number of successful backups made with this add-on
- `total backups failed`: The total number of failed backups
- `last backup`: The date of the last successful backup


There is a known limitation that the sensor will be unavailable if you restart Home Assistant. This is caused by the way Home Assistant handles sensors which are not backed up by an entity, but instead come from an add-on or AppDaemon. You can easily fix that with the following blueprint:

[![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/blueprints/restore_samba_backup_sensor.yaml)

Or use this automation directly:

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


The `total backups failed` and `total backups succeeded` counters can be reset with the following script:

```yaml
service: hassio.addon_stdin
data:
  addon: 15d21743_samba_backup
  input: reset-counter
```

_Reset counter variables_



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

The configuration options that directly affect the backup creation are overwritable for a single run: `exclude_addons`, `exclude_folders`, `backup_name` and `backup_password`. To overwrite any of these options, you have to use an extended syntax - `command` has to be `trigger`. See the following example:

```yaml
service: hassio.addon_stdin
data:
  addon: 15d21743_samba_backup
  input:
    command: trigger
    backup_name: My overwritten backup name {date}
    backup_password: some_pwd
    exclude_addons: [core_mariadb, core_deconz]
    exclude_folders: [ssl]
```

_Extended trigger_

## FAQ

### Why is the sensor missing when I restart Home Assistant?

This is a known limitation, but it can easily be fixed with an automation. See the [Home Assistant sensor](https://github.com/thomasmauerer/hassio-addons/blob/master/samba-backup/DOCS.md#home-assistant-sensor) section for more details. Apart from that, check that Samba Backup is really running after restart. If not the automation will not have any effect.

### Can I use Samba Backup to upload backups to an online storage via the internet?

Samba Backup is based on the SMB protocol, so as long as the online storage supports SAMBA/CIFS it is possible. However, keep in mind that some SMB implementations rely on NetBIOS which some routers block by default. Therefore it could be necessary to disable the NetBIOS filter in the router settings.

### Why do I get this error at startup "Server does not support EXTENDED_SECURITY"?

If you see this error in the logs, it means that your NAS only supports an outdated authentication mechanism which Samba Backup refuses. The SMB options to overcome this issue are already marked as deprecated and will be removed in the future. Hence, I will not add support for that. Please use a different NAS/share in this case. 
