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

## Output

- Downloaded APKs: `apks/`
- Patched APKs: `apks-patched/`
- Generated keystores: `apks-keystore/`
- Published release folders: `public/<YYYYMMDD_HHMMSS>/`

Only the latest 3 published folders are kept.
