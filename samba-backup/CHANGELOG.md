# Changelog

## 4.3

- Remove mqtt support
- Add config option for the workgroup
- Add support to disable ICMP requests
- Bump CLI version to 4.9.0

## 4.2

- Fix supervisor warnings for partial snapshots
- Add support to exclude the media folder
- Bump CLI version to 4.7.0

## 4.1

- Improve and extend SMB pre-checks
- Update sensor if pre-check fails
- Remove mqtt listener

## 4.0

- Include a Home Assistant sensor for status updates and statistics
- The add-on will no longer shut down in case of a failed backup
- MQTT support is now deprecated. Please switch to the new sensor
- Several minor improvements

**Important**: If you have already a sensor called `Samba Backup` (sensor.samba_backup), please delete or at least rename it!

## 3.1

- Add support for legacy SMB protocols

## 3.0

- Support multiple triggers at once
- Introduce mqtt trigger
- Make configuration options overwritable for manual triggers

## 2.6

- Fix config issues with dollar signs

## 2.5

- Add support for external mqtt brokers
- Fix incorrect escaped user input

## 2.4

- Fix config issues with spaces and special characters

## 2.3

- Add mqtt support
- Publish current status via mqtt

## 2.2

- Use dedicated log functions
- Control verbosity of logs
- Perform precheck on Samba share

## 2.1

- Fix wrong HA version in name patterns

## 2.0

- This is a breaking release!
- Samba Backup now cleans up all snapshots stored on the device
- Samba Backup is now running as a service in the background
- Support custom snapshot names including name patterns
- Support triggers out of the box without separate Home Assistant automations
- Support manual triggers for advanced use-cases

## 1.5

- Improve remote cleanup functionality
- Make backup password optional

## 1.4

- Add support for partial snapshots
- Minor improvements

## 1.3

- Add support to clean up remote snapshots

## 1.2

- Add support for password-protected snapshots

## 1.1

- Add support to clean up local snapshots
- Minor improvements

## 1.0

- Add support for add-on configuration
- Add support to create snapshots
- Add support to copy snapshots to remote Samba share
