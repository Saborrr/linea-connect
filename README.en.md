# Linea Connect

Open-source personal VPN client project derived from
[Hiddify](https://github.com/hiddify/hiddify-app), targeting Android, iOS and macOS.

Initial source revision only. Native builds, device installation and connectivity
have not been validated. Public fork: https://github.com/Saborrr/linea-connect.

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
