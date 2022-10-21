# Changelog

## 5.2.0

- Add dutch translation
- Fix incorrect sensor values during backup run
- Fix problem with reset-counter function
- Check current number of stored backups at startup

## 5.1.2

- Add german and swedish translation
- Improve log output

## 5.1.1

- Fix bug that add-on does not start without a log level

## 5.1.0

- Implement necessary changes for Supervisor 2022.06 so that add-ons are considered in partial backups
- Add translations
- Update Alpine Linux to 3.16
- Bump CLI version to 4.18.0

## 5.0.0

**Important**: You need to run supervisor 2021.08.0 or higher!

- Replace deprecated supervisor API calls
- Rename snapshot -> backup
- Include date and improve logs
- Add support to reset the Home Assistant sensor
- Improve situation when backup could not be created
- Update Alpine Linux to 3.14
- Bump CLI version to 4.13.0

## 4.5.0

- Increase timeout for smbclient
- Update password schema
- Update Alpine Linux to 3.13
- Bump CLI version to 4.10.1

## 4.4.0

- Use snapshot names for the filenames on the share
- Remove ICMP requests and config option `no_icmp`
- Add support to skip the pre-checks on add-on startup

## 4.3.0

- Remove mqtt support
- Add config option for the workgroup
- Add support to disable ICMP requests
- Bump CLI version to 4.9.0

## 4.2.0

- Fix supervisor warnings for partial snapshots
- Add support to exclude the media folder
- Bump CLI version to 4.7.0

## 4.1.0

- Improve and extend SMB pre-checks
- Update sensor if pre-check fails
- Remove mqtt listener

## 4.0.0

- Include a Home Assistant sensor for status updates and statistics
- The add-on will no longer shut down in case of a failed backup
- MQTT support is now deprecated. Please switch to the new sensor
- Several minor improvements

**Important**: If you have already a sensor called `Samba Backup` (sensor.samba_backup), please delete or at least rename it!

## 3.1.0

- Add support for legacy SMB protocols

## 3.0.0

- Support multiple triggers at once
- Introduce mqtt trigger
- Make configuration options overwritable for manual triggers

## 2.6.0

- Fix config issues with dollar signs

## 2.5.0

- Add support for external mqtt brokers
- Fix incorrect escaped user input

## 2.4.0

- Fix config issues with spaces and special characters

## 2.3.0

- Add mqtt support
- Publish current status via mqtt

## 2.2.0

- Use dedicated log functions
- Control verbosity of logs
- Perform precheck on Samba share

## 2.1.0

- Fix wrong HA version in name patterns

## 2.0.0

- This is a breaking release!
- Samba Backup now cleans up all snapshots stored on the device
- Samba Backup is now running as a service in the background
- Support custom snapshot names including name patterns
- Support triggers out of the box without separate Home Assistant automations
- Support manual triggers for advanced use-cases

## 1.5.0

- Improve remote cleanup functionality
- Make backup password optional

## 1.4.0

- Add support for partial snapshots
- Minor improvements

## 1.3.0

- Add support to clean up remote snapshots

## 1.2.0

- Add support for password-protected snapshots

## 1.1.0

- Add support to clean up local snapshots
- Minor improvements

## 1.0.0

- Add support for add-on configuration
- Add support to create snapshots
- Add support to copy snapshots to remote Samba share
