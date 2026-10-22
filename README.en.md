# Linea Connect

Open-source personal VPN client project derived from
[Hiddify](https://github.com/hiddify/hiddify-app), targeting Android, iOS and macOS.

Initial development revision. The Android debug APK built successfully in
[GitHub Actions](https://github.com/Saborrr/linea-connect/actions/runs/39770773497),
with 203 Flutter tests passing. Another 39 policy/privacy checks passed in CI.
[Download the APK archive](https://github.com/Saborrr/linea-connect/actions/runs/39770773497/artifacts/12422677153).
[Unsigned macOS compile artifact](https://github.com/Saborrr/linea-connect/actions/runs/39772943128/artifacts/12423507837)
and [unsigned iOS app with Packet Tunnel](https://github.com/Saborrr/linea-connect/actions/runs/39775224921/artifacts/12423749948)
are also available. The iOS archive contains an app bundle, not an installable IPA.
Device installation, live connectivity and Apple distribution
signing have not been validated.
Public fork: https://github.com/Saborrr/linea-connect.

Changes: a distinct compact home screen and icons, separate app identifiers,
core-managed automatic route selection, event-code-only diagnostic export,
a bounded adaptive policy and its offline checks, disabled upstream update feeds
and crash-report uploads. The adaptive policy is not yet integrated into native
background VPN services and must not be presented as automatic allowlist detection.

No user server addresses, credentials or subscription URLs are committed.
An unreachable VPS IP cannot be made reachable merely by changing protocols.

Run the dependency-free checks with `dart tool/linea_checks.dart`.
See [validation](docs/linea/VALIDATION.md) and [build instructions](docs/linea/BUILD.md).

Upstream snapshot: `4b99aa681d36aae104c440a9557a71dd93382ba3`.
Original attribution and [Hiddify Extended GNU GPL v3](LICENSE.md) are preserved.
New contributions use the same license. See [upstream README](README.upstream.md).
