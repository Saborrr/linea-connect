# Сборка и публикация исходников

## Создание репозитория

Нужен **публичный форк** https://github.com/hiddify/hiddify-app в аккаунте Saborrr,
рекомендуемое имя `linea-connect`. Для требований текущей LICENSE недостаточно
обычного несвязанного репозитория с копией файлов.
Публичный форк создан: https://github.com/Saborrr/linea-connect.

Подготовленные изменения не содержат реквизитов сервера пользователя.
После создания форка локальные коммиты переносятся обычным git push в отдельную
ветку. Не применять force push к чужой или изменившейся ветке main.

Если изменения переданы patch-файлом, применить его к указанному upstream-коммиту
через `git am`; затем прогнать проверки и открыть PR в собственном форке.

## Требования

- Flutter 3.38.5, Dart 3.10.4, как в закреплённом upstream snapshot.
- Android SDK и Java 17 для Android.
- Для Apple: Mac, Xcode, CocoaPods, свой Apple Developer team и подходящие entitlements.
- Сетевой доступ к официальным Flutter/pub/GitHub/Maven источникам зависимостей.
- При текущей development-сборке Makefile загружает native core из upstream
  `draft`. Это изменяемый канал: значение `core.version` применяется к ветке
  `CHANNEL=prod`, а не к данному workflow. До релиза закрепить совместимую версию
  и SHA-256, проверить лицензии и фактические протоколы.

## Проверки без зависимостей

```sh
dart tool/linea_checks.dart
```

## Android

В репозитории запустить Actions → Linea Android development build → Run workflow.
Workflow выполняет подготовку исходников/ядра, тесты и debug-сборку.
Первый запуск завершился успешно, прошли 203 Flutter-теста:
https://github.com/Saborrr/linea-connect/actions/runs/39770773497.

Готовый архив с app-debug.apk:
https://github.com/Saborrr/linea-connect/actions/runs/39770773497/artifacts/12422677153.
GitHub может потребовать вход для скачивания артефакта. Архив нужно распаковать.
Срок хранения текущего артефакта по API: до 20.01.2027. Сборка из коммита 6aec6fb.
Установка на устройстве в этой работе не выполнялась.

Локальный эквивалент:

```sh
make android-prepare
flutter test
flutter build apk --debug
```

Debug APK предназначен для разработки. Для распространения нужны собственный
release keystore и отдельный workflow подписи. Ключи не коммитить.

## iPhone

Workflow **Linea Apple compile checks** проверяет компиляцию iOS и macOS без
сертификатов и сохраняет неподписанные app bundles. Это проверка сборки, а не
готовые для установки IPA или notarized Mac app. Встроенная Packet Tunnel
extension также должна быть подписана собственными provisioning profiles.

```sh
make ios-prepare
open ios/Runner.xcworkspace
```

В Xcode назначить свой team для Runner и Packet Tunnel, зарегистрировать
`io.github.saborrr.linea` и соответствующий extension ID/App Group.
Пустой DEVELOPMENT_TEAM в исходниках нужно заполнить локально. Оригинальный team
Hiddify удалён. Проверять туннель на физическом устройстве. Наличие исходников
или IPA без правильной подписи не означает возможность установки на iPhone.
Выпускные сборки оформлять через GitHub Actions с сертификатами в Secrets.

## Mac

```sh
make macos-prepare
flutter run -d macos
```

Проверить унаследованную схему службы/TUN, права и подпись; не утверждать,
что macOS использует ту же реализацию, что iOS Packet Tunnel. Для распространения
подготовить собственные подпись, notarization и GitHub Actions workflow.

## Обновления

Автообновление приложения отключено, чтобы Linea не предлагала установить
релиз Hiddify. До его включения настроить собственный подписанный канал обновлений.
Прежние upstream workflows находятся в docs/linea/upstream-workflows и не исполняются.
