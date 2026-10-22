# AmneziaWG 2.0 и 3.1

Native backend: официальный `github.com/amnezia-vpn/amneziawg-go/v3`, tag
`v3.1.20260828`, commit `b5928efb6ca19f0153958460c3d141f04abc5c2e`.
Версии Hiddify Core и рекурсивных submodules закреплены через `tool/native/core.lock.json`.
Новые поля не отбрасываются при преобразовании в native UAPI.

| Настройки `.conf` | Поля в JSON `endpoints[].awg` |
| --- | --- |
| Jc, Jmin, Jmax | jc, jmin, jmax |
| S1–S4 | s1–s4 |
| H1–H4, I1–I5 | h1–h4, i1–i5 |
| HeaderProtectionKey | header_protection_key |
| ContentPaddingAddition | content_padding_addition |
| RekeyAfterTime, RekeyTimeout | rekey_after_time, rekey_timeout |
| RejectAfterTime, KeepaliveTimeout | reject_after_time, keepalive_timeout |
| MaxHandshakeAttempts | max_handshake_attempts |
| RandomTrailers, DisableCookies | random_trailers, disable_cookies |

Диапазоны передаются строками, например `"100-120"`. Булевы значения в JSON:
`true` / `false`; в `.conf` также принимаются `on` / `off`. HeaderProtectionKey
передаётся в конфигурации как base64-ключ длиной 32 байта и преобразуется в hex
только внутри native IPC. Для защиты заголовков S1–S4 должны быть не меньше 12.
Параметры сервера и клиента должны соответствовать друг другу.

В peer диапазон `PersistentKeepalive` сохраняется через JSON `persistent_keepalive`.
Прежнее числовое `persistent_keepalive_interval` тоже поддерживается.
ListenPort из `.conf` сохраняется. Для нескольких peers используется JSON endpoint;
повторные секции `[Peer]` в `.conf` отклоняются, поскольку upstream-конвертер
иначе молча оставлял только последнюю. DNS использует настройки DNS приложения;
поле DNS из `.conf` не заменяет их автоматически.

Проверки выполняются командой `bash tool/native/test-core.sh <source>`:

- AWG 2.0: TCP/UDP echo через два локальных VPN endpoint.
- AWG 3.1: тот же зашифрованный туннель с HeaderProtectionKey,
  RandomTrailers, DisableCookies, дополнением пакетов и диапазонами таймингов.
- Преобразование новых параметров в native IPC и принятие их официальным device.
- Импорт `.conf` и query-ссылки с сохранением параметров 3.1.
- Принятие S3/S4 и проверка обфускации передаваемых пакетов.

Это локальные интеграционные проверки. Они не подтверждают доступность
конкретного VPS через мобильного оператора и не заменяют испытания на телефоне.

Первичные источники:
- https://github.com/amnezia-vpn/amneziawg-go/tree/v3.1.20260828
- https://github.com/amnezia-vpn/amneziawg-go/blob/v3.1.20260828/README.md
- https://github.com/hiddify/hiddify-core/tree/399f1eba7b80254b7ed365edbddee58d772cb593

Скрипт `patch-core.py` расширяет только AWG-адаптер и импорт, не убирая остальные
протоколы из build tags Hiddify. Новые регрессионные тесты входят в репозиторий.
