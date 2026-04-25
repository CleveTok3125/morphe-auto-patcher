# Morphe Auto Patcher

Automates Morphe APK download, patching, and publishing.

## Flow

```text
check update
  -> download latest morphe-cli + patches
  -> sync local APK cache
  -> download required APK versions
  -> patch APKs
  -> publish patched APKs to public/<timestamp>
```

## Requirements

- `bash`
- `curl`
- `jq`
- `java`
- `bun`
- `file`

## Project Layout

- `cron.sh`: checks if Morphe patches have a new release
- `main.sh`: full pipeline
- `refresh-morphe-assets.sh`: downloads latest `morphe-cli.jar` and `patches.mpp`
- `download-apks.sh`: downloads APKs from APKMirror
- `multi-patch.sh`: patches downloaded APKs
- `gc-sync.sh`: removes stale entries from `downloaded.list`
- `public/`: published outputs, stored by timestamp

## Run

Run the full pipeline manually:

```bash
bash ./main.sh
```

Run only when a new Morphe patches release is detected:

```bash
bash ./cron.sh
```

Check update status only:

```bash
bash ./check-morphe-update.sh
```

## Docker

The repository includes a Docker-based static host for the published files in `public/`.

Build and run the container:

```bash
./docker.run
```

This does the following:

- builds the image from `Dockerfile`
- replaces the existing container if one is already running
- starts the container with `--restart unless-stopped`
- mounts `$(pwd)/public` into the container as read-only
- serves files on port `10003`

Published files are available under the `bW9ycGhl` path:

- `http://<host>:10003/bW9ycGhl/`
- `http://<host>:10003/bW9ycGhl/<timestamp>/`
- `http://<host>:10003/bW9ycGhl/latest/`

## Output

- Downloaded APKs: `apks/`
- Patched APKs: `apks-patched/`
- Generated keystores: `apks-keystore/`
- Published release folders: `public/<YYYYMMDD_HHMMSS>/`

Only the latest 3 published folders are kept.
