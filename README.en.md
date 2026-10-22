<p align="center"><img src="docs/linea/assets/hero.svg" alt="Linea Connect" width="100%"></p>
<p align="center"><a href="README.md">Русский</a> · <b>English</b></p>

# Linea Connect

An open source VPN client for your own server, including subscriptions from
3x-ui. A simple dashboard, a compact list of saved connections, and diagnostics
that survive an application restart. Built on [Hiddify](https://github.com/hiddify/hiddify-app).

**Development 0.2.0.** [Download the latest successful Android build](https://github.com/Saborrr/linea-connect/actions/workflows/linea-android.yml)
from its `Linea-Android-development` artifact. Unzip it and install `app-debug.apk`.
Apple builds require your own signing identity before installation.

<p align="center"><img src="docs/linea/assets/connected.png" width="31%" alt="Connection dashboard"> <img src="docs/linea/assets/import.png" width="31%" alt="Import options"></p>

These previews render actual Flutter widgets with sample data.

- New connection links append to the saved list. Importing the same subscription
  address refreshes that subscription. New profiles preserve your selection by default.
- AmneziaWG **2.0 and 3.1**, using the official pinned v3 backend. Header protection,
  RandomTrailers, DisableCookies, content padding, timing ranges, S1–S4, H1–H4 and
  I1–I5 reach the native device. TCP/UDP loopback tunnels and import are tested.
- Existing Hiddify protocol adapters remain enabled, including VLESS, REALITY,
  VMess, Trojan, Shadowsocks, Hysteria2, TUIC and WireGuard. Your server and network
  still need compatible settings.
- Diagnostic exports contain fixed event categories, app source locations,
  previous-run errors and numeric Android process exit metadata. Subscription
  URLs, keys and arbitrary log messages are omitted.
- Automatic selection uses the current profile's `urltest` group. The separate
  adaptive allowlist policy is tested but is not integrated into background services.

Native sources are pinned in [`core.lock.json`](tool/native/core.lock.json).
Android and Apple workflows build that source with the included AWG adapter patch;
they do not use the mutable upstream draft core.

```sh
make common-prepare
flutter test
dart tool/linea_checks.dart
bash tool/native/prepare-core.sh
bash tool/native/test-core.sh hiddify-core/source
```

[AWG integration](docs/linea/AMNEZIAWG.md) · [Build and signing](docs/linea/BUILD.md) ·
[Protocol matrix](docs/linea/PROTOCOLS.md) · [Validation](docs/linea/VALIDATION.md) ·
[Privacy](docs/linea/PRIVACY.md)

This is a derivative project, not an official Hiddify or Amnezia release.
[Hiddify Extended GNU GPL v3](LICENSE.md), including its commercial-use restrictions,
is preserved. [Original upstream README](README.upstream.md).
