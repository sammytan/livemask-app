# LiveMask App

Multi-platform VPN Client (Flutter + sing-box)

See full AI rules and setup in livemask-docs: https://github.com/MyAiDevs/livemask-docs

## Local macOS development

The App is developed and debugged locally, not inside Docker.

```bash
bash scripts/local-app.sh doctor
bash scripts/local-app.sh start --target macos
bash scripts/local-app.sh logs --target macos
```

Build a queued set of platform targets:

```bash
bash scripts/local-app.sh build --targets macos,ios
bash scripts/local-app.sh build --targets all
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

Both targets call the local Backend through:

```text
API_BASE_URL=http://127.0.0.1:18080
AUTH_CLIENT_MODE=real
```

If `macos/` does not exist yet, the script generates the Flutter macOS scaffold
with `flutter create --platforms=macos .`.
