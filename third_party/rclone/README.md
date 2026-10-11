# Bundled rclone

Place the Windows `rclone.exe` binary in this folder before building the Windows
release installer:

```text
third_party/rclone/rclone.exe
```

The Windows build and installer copy that executable beside `list.exe`. The app
already checks that location before falling back to `rclone` on PATH, so users do
not need to install rclone manually.

Download rclone from the official rclone releases page and keep any required
license or notice files with the binary when distributing the app.
