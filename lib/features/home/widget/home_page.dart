// Linea Connect. Derived from Hiddify; see LICENSE.md and README.upstream.md.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    String text(String russian, String english) => ru ? russian : english;
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final connection = ref.watch(connectionNotifierProvider);
    final status = connection.valueOrNull;
    final running = status is Connected;
    final hotReloading = ref.watch(hotReloadingProvider).valueOrNull ?? false;
    final failed =
        connection.hasError ||
        (status is Disconnected && status.connectionFailure != null);
    final busy =
        status is Connecting ||
        status is Disconnecting ||
        connection.isLoading ||
        hotReloading;
    // Drop cached measurements across reconnects.
    final proxy = ref
        .watch(activeProxyNotifierProvider)
        .unwrapPrevious()
        .valueOrNull;
    final delay = proxy?.urlTestDelay ?? 0;
    final reachable = running && ConnectionConst.isValidDelay(delay);
    final stats = ref.watch(statsNotifierProvider).unwrapPrevious().valueOrNull;
    final group = ref.watch(proxiesOverviewNotifierProvider).valueOrNull;
    final automatic = group?.items
        .where((item) => item.type.toLowerCase() == 'urltest')
        .firstOrNull;
    final autoSelected = automatic != null && group?.selected == automatic.tag;
    final title = busy
        ? text('Подключение', 'Connecting')
        : reachable
        ? text('Соединение работает', 'Connection is working')
        : running
        ? text('Проверяем доступ', 'Checking access')
        : failed
        ? text('Не удалось подключиться', 'Connection failed')
        : text('Можно подключаться', 'Ready to connect');
    final subtitle = reachable
        ? text(
            'Контрольный запрос через маршрут выполнен',
            'The route passed its connectivity check',
          )
        : running
        ? text(
            'Туннель запущен, доступ ещё не подтверждён',
            'The tunnel is up; access is not confirmed yet',
          )
        : failed
        ? text(
            'Откройте диагностику или попробуйте другой маршрут',
            'Open diagnostics or try another route',
          )
        : text(
            'Добавьте подписку своего сервера и подключитесь',
            'Add your server subscription and connect',
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Linea',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        actions: [
          IconButton(
            tooltip: text('Диагностика', 'Diagnostics'),
            onPressed: () => context.goNamed('logs'),
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
          IconButton(
            tooltip: text('Добавить подключение', 'Add connection'),
            onPressed: () => ref
                .read(bottomSheetsNotifierProvider.notifier)
                .showAddProfile(),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            children: [
              Text(
                text(
                  'Ваш сервер. Ваше подключение.',
                  'Your server. Your connection.',
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: reachable
                      ? const Color(0xFF153F36)
                      : const Color(0xFF202D3B),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      reachable
                          ? Icons.verified_user_outlined
                          : Icons.shield_outlined,
                      size: 36,
                      color: const Color(0xFFB9E8CE),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFFCFDAD9),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          backgroundColor: const Color(0xFFB9E8CE),
                          foregroundColor: const Color(0xFF153F36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: busy
                            ? null
                            : () async {
                                if (profile == null) {
                                  ref
                                      .read(
                                        bottomSheetsNotifierProvider.notifier,
                                      )
                                      .showAddProfile();
                                  return;
                                }
                                final dialogs = ref.read(
                                  dialogNotifierProvider.notifier,
                                );
                                if (running ||
                                    await dialogs
                                        .showExperimentalFeatureNotice()) {
                                  await ref
                                      .read(connectionNotifierProvider.notifier)
                                      .toggleConnection();
                                }
                              },
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                running
                                    ? Icons.power_settings_new
                                    : Icons.arrow_forward_rounded,
                              ),
                        label: Text(
                          busy
                              ? text('Подождите', 'Please wait')
                              : running
                              ? text('Отключить', 'Disconnect')
                              : text('Подключиться', 'Connect'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(
                    profile?.name ??
                        text('Добавить свой сервер', 'Add your server'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    reachable
                        ? '${proxy?.type ?? ""} · $delay ms'
                        : text(
                            'Подписка 3x-ui или ссылка подключения',
                            '3x-ui subscription or connection link',
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => profile == null
                      ? ref
                            .read(bottomSheetsNotifierProvider.notifier)
                            .showAddProfile()
                      : context.goNamed(
                          'profileDetails',
                          pathParameters: {'id': profile.id},
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    text('Автовыбор маршрута', 'Automatic route selection'),
                  ),
                  subtitle: Text(
                    text(
                      'Выбирает доступный сервер из текущей подписки',
                      'Chooses an available server in your current subscription',
                    ),
                  ),
                  value: autoSelected,
                  onChanged: !running
                      ? null
                      : (enabled) async {
                          if (!enabled || automatic == null || group == null) {
                            context.goNamed('proxies');
                            return;
                          }
                          final t = ref.read(translationsProvider).requireValue;
                          await ref
                              .read(proxyRepositoryProvider)
                              .selectProxy(group.tag, automatic.tag)
                              .mapLeft((error) async {
                                await ref
                                    .read(dialogNotifierProvider.notifier)
                                    .showCustomAlertFromErr(error.present(t));
                              })
                              .run();
                        },
                ),
              ),
              const SizedBox(height: 12),
              _Panel(
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: text('Задержка', 'Latency'),
                        value: reachable ? '$delay ms' : '···',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: text('Скачано', 'Downloaded'),
                        value: running && (stats?.trafficAvailable ?? false)
                            ? _bytes(stats!.downlinkTotal.toInt())
                            : '···',
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: text('Отправлено', 'Uploaded'),
                        value: running && (stats?.trafficAvailable ?? false)
                            ? _bytes(stats!.uplinkTotal.toInt())
                            : '···',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text(
                  'При ограничениях сети нужен доступный резервный сервер. Смена протокола не гарантирует доступ к заблокированному IP.',
                  'Network restrictions require a reachable backup server. Changing protocols cannot guarantee access to a blocked IP.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  text('Подробности и настройки', 'Details and settings'),
                ),
                children: [
                  ListTile(
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(
                      text('Параметры подключения', 'Connection settings'),
                    ),
                    onTap: () => ref
                        .read(bottomSheetsNotifierProvider.notifier)
                        .showQuickSettings(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: Text(
                      text(
                        'Журнал и выгрузка диагностики',
                        'Logs and diagnostic export',
                      ),
                    ),
                    onTap: () => context.goNamed('logs'),
                  ),
                  const ListTile(
                    title: Text('Based on Hiddify'),
                    subtitle: Text(
                      'github.com/hiddify/hiddify-app · LICENSE.md',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 7),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

String _bytes(int value) {
  if (value < 1024) return '$value B';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  if (value < 1024 * 1024 * 1024)
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
