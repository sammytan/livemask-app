# LiveMask App

Multi-platform VPN Client (Flutter + sing-box)

See full AI rules and setup in livemask-docs: https://github.com/MyAiDevs/livemask-docs

## Mandatory design source for UI work

Before changing any user-visible App UI, read the current App design handoff in
`livemask-docs`:

```text
../livemask-docs/docs/app/LIVEMASK_APP_DESIGN_BRIEF_FOR_ATOMS.md
../livemask-docs/design/app/README.md
../livemask-docs/design/app/atoms/v2/README.md
../livemask-docs/design/app/atoms/v2/export/.wiki.md
```

The Atoms export is design source material, not Flutter runtime code. Translate
the screen structure, states, copy, spacing, and components into Flutter widgets.
Do not copy React / Atoms Cloud implementation code into this repository.

## Local macOS development

The App is developed and debugged locally, not inside Docker.

```bash
bash scripts/local-app.sh doctor
bash scripts/local-app.sh start --target macos
bash scripts/local-app.sh logs --target macos
```

Single-target builds are the default when system resources are tight:

```bash
bash scripts/local-app.sh build --target macos
bash scripts/local-app.sh build --target ios
bash scripts/local-app.sh build --target android
bash scripts/local-app.sh build --target linux
bash scripts/local-app.sh build --target windows
bash scripts/local-app.sh build --target web
```

Build a queued set of platform targets:

```bash
bash scripts/local-app.sh build --targets macos,ios
bash scripts/local-app.sh build --targets all
```

Run a specific simulator/device:

```bash
flutter devices
bash scripts/local-app.sh start --target ios --device-id <simulator-or-device-id>
bash scripts/local-app.sh start --target android --device-id <emulator-or-device-id>
```

Web preview is still available for quick UI checks:

```bash
bash scripts/local-app.sh start --target web
```

Supported target names:

```text
macos, ios, android, linux, windows, web
```

Host rules:

- macOS can build/run `macos`, `ios`, `web`, and Android when Android SDK is configured.
- Linux must be built on Linux.
- Windows must be built on Windows, for example inside Parallels Desktop.
- Unsupported targets are reported as skipped/blocking in the queue instead of being treated as success.

Local App runs call the local Backend through:

```text
API_BASE_URL=http://127.0.0.1:18080
AUTH_CLIENT_MODE=real
```

iOS and macOS platform scaffolds are tracked in this repository. If another
platform directory is missing, `scripts/local-app.sh` can generate the Flutter
scaffold for that target before building.
