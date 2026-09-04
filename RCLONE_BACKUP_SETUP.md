# Hive Backup to Google Drive with rclone

This app stores the local Hive database as the primary source of truth. Google Drive backup is an external copy made with `rclone`; failures must not modify local Hive data.

## What Gets Backed Up

The app discovers the open Hive boxes and copies their real database files into a temporary snapshot before upload:

- `loans`
- `deposits`
- `events`
- `bankLoans`

Files ending in `.lock` are never uploaded.

## Google Drive Layout

The default remote layout is:

```text
LoanLedgerBackups/
  johndoe01/
    AUTO_BACKUP/
      loans.hive
      deposits.hive
      events.hive
      bankLoans.hive
    MANUAL_BACKUP/
      scheduled_2026-09-04_08-00/
      scheduled_2026-09-04_16-00/
      scheduled_2026-09-04_23-00/
      manual_2026-09-04_20-15/
```

`AUTO_BACKUP` contains the latest files only. Manual and scheduled backups create timestamped historical folders under `MANUAL_BACKUP`.

## Install rclone

1. Download rclone from `https://rclone.org/downloads/`.
2. Install it or place `rclone.exe` somewhere stable, such as beside the packaged Windows app.
3. Confirm it works:

```powershell
rclone version
```

If `rclone` is not on `PATH`, enter the full executable path in the app's Backup & Restore settings.

## Configure Google Drive

Run:

```powershell
rclone config
```

Create a Google Drive remote named:

```text
gdrive
```

Follow rclone's browser OAuth flow. If you use your own Google Cloud OAuth app, keep the client ID and client secret outside this repository and enter them only into rclone during setup.

Verify:

```powershell
rclone about gdrive:
rclone mkdir gdrive:LoanLedgerBackups
```

## Protect `rclone.conf`

rclone stores OAuth tokens in `rclone.conf`. Do not commit it to Git. This repository ignores common local rclone credential files:

- `rclone.conf`
- `*.rclone.conf`
- `.rclone/`
- `backup_config.local.json`

To find the active config path:

```powershell
rclone config file
```

Paste that path into the app only if you do not want rclone to use its default config location.

## App Settings

Open `Backup & Restore` from the cloud icon in the main app bar.

Default values:

- rclone executable path: `rclone`
- rclone config path: blank
- remote name: `gdrive`
- Google Drive root folder: `LoanLedgerBackups`
- automatic interval minutes: `30`
- scheduled backup times: `08:00, 16:00, 23:00`

On first launch after OTP verification, the app asks for a name. `John Doe` becomes `johndoe01` unless that folder already exists on the configured Google Drive remote, in which case the next available suffix is used.

## Windows Packaging

For a Windows build, either:

- require users to install rclone and add it to `PATH`; or
- ship `rclone.exe` beside the app executable and configure the Backup & Restore page with that path.

Do not package a real `rclone.conf` containing personal OAuth tokens. Each user should provide their own rclone configuration.

## Verification Checklist

1. Delete only the local backup identity keys if you need to repeat first-launch identity testing.
2. Launch the app and enter `John Doe`; confirm the Backup ID is `johndoe01` on an empty Drive folder.
3. Create a `johndoe01` folder manually in Drive, clear the local identity, relaunch, and confirm the next ID becomes `johndoe02`.
4. Click `Test Connection`; confirm `Google Drive: Connected`.
5. Click `Backup Now`; confirm a folder like `MANUAL_BACKUP/manual_2026-09-04_20-15/` appears.
6. Leave the app open for the configured automatic interval; confirm files appear directly under `AUTO_BACKUP/`.
7. Wait for another automatic backup; confirm `AUTO_BACKUP/` still contains only the latest Hive files, not timestamped folders.
8. Leave the app open across `08:00`, `16:00`, or `23:00`; confirm a `scheduled_...` folder appears under `MANUAL_BACKUP/`.
9. Temporarily break the remote name or disconnect the network and run a backup; confirm local loans, payments, interest, and deposits still work.
10. Start a backup and immediately press `Backup Now` again; confirm the app reports that a backup is already running.
