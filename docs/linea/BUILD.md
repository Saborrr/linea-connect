# Сборка и подпись

Публичный форк: https://github.com/Saborrr/linea-connect.

## Требования

- Flutter 3.38.5 / Dart 3.10.4.
- Go 1.26.3 для native core; Node.js/npm для upstream make target.
- Android SDK, NDK r28c, Java 17 для Android.
- Xcode и CocoaPods на Mac для iOS/macOS.

## Проверки

```sh
make common-prepare
flutter test
dart tool/linea_checks.dart
bash tool/native/prepare-core.sh
bash tool/native/test-core.sh hiddify-core/source
```

Linux-тестам Drift нужна библиотека SQLite (`libsqlite3-dev` на Ubuntu).
Скрипт native-подготовки загружает закреплённый Hiddify Core и рекурсивные
submodules, применяет открытый патч адаптера AWG 3.1 и подключает официальное
ядро AmneziaWG `/v3`. Версии указаны в `tool/native/core.lock.json`.

Старые upstream-команды `make android-prepare` / `ios-prepare` / `macos-prepare`
всё ещё используют draft-библиотеки. Для сборок Linea с AWG 3.1 используйте
описанный workflow или команды ниже.

## Android

Actions → **Linea Android development build** → Run workflow. Сборка также
запускается автоматически при изменениях кода в main. Последний успешный запуск:
https://github.com/Saborrr/linea-connect/actions/workflows/linea-android.yml.

Артефакт `Linea-Android-development` содержит `app-debug.apk` и `core.lock.json`.
Артефакт `Linea-interface-checks` содержит превью виджетов из тестов.
Для скачивания GitHub может потребовать вход. Артефакты хранятся 30 дней.

```sh
make -C hiddify-core/source android
mkdir -p android/app/libs
cp hiddify-core/source/bin/hiddify-core.aar android/app/libs/
flutter build apk --debug --build-name=0.2.0 --build-number=50001
```

Это development APK. Ключ debug-подписи кешируется для следующих запусков этого
workflow. Старые сборки, созданные до введения постоянного кеша, могут иметь
другую подпись; Android не устанавливает обновление поверх другой подписи.
Перед любым удалением установленного приложения сохраните свои конфигурации.
Для выпуска нужен собственный release keystore, хранящийся в Secrets.
Ключи подписи не включаются в репозиторий или артефакты.

## iPhone и Mac

Workflow **Linea Apple compile checks** собирает native core из тех же
закреплённых исходников, проверяет AWG-туннели и компилирует приложение без
подписи. При запуске выберите `ios`, `macos` или `all`.

Для iOS native target создаёт `HiddifyCore.xcframework`, который копируется в
`ios/Frameworks`. Далее выполняются `pod install --repo-update` и
`flutter build ios --release --no-codesign`. Для Mac используется универсальная
`hiddify-core.dylib`; Xcode компилирует Linea.app с `CODE_SIGNING_ALLOWED=NO`.

Неподписанная Runner.app не является установочным IPA. Для установки iPhone
нужны собственный Apple Developer team, entitlements и provisioning profiles
для Runner и Packet Tunnel. App ID: `io.github.saborrr.linea`; extension и App
Group должны соответствовать проекту. На Mac для распространения нужны подпись
и notarization. Работу VPN проверяйте на физическом устройстве.

## Исходники и лицензии

[Hiddify Extended GPL v3](../../LICENSE.md) сохранена. Сборки публикуются через
GitHub Actions. Native source revision, официальный AWG backend и весь патч
доступны по `tool/native/`. Коммит приложения связывает исходники с конкретной
сборкой в Actions. Секреты сервера и пользовательские журналы не коммитятся.
