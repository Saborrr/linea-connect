// Linea Connect. Derived from Hiddify; see LICENSE.md and README.upstream.md.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/linea/widget/linea_dashboard.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/stats/notifier/stats_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(activeProfileProvider);
    final profile = profiles.valueOrNull;
    final connection = ref.watch(connectionNotifierProvider);
    final status = connection.valueOrNull;
    final running = status is Connected;
    final busy = status is Connecting || status is Disconnecting || connection.isLoading;
    // No requests to the background VPN service while it is stopped.
    final proxy = running ? ref.watch(activeProxyNotifierProvider).unwrapPrevious().valueOrNull : null;
    final stats = running ? ref.watch(statsNotifierProvider).unwrapPrevious().valueOrNull : null;
    final group = running ? ref.watch(proxiesOverviewNotifierProvider).unwrapPrevious().valueOrNull : null;
    final automatic = group?.items.where((item) => item.type.toLowerCase() == 'urltest').firstOrNull;
    final delay = proxy?.urlTestDelay ?? 0;
    final checkedAt = proxy?.hasUrlTestTime() == true ? proxy!.urlTestTime.toDateTime() : null;
    final age = checkedAt == null ? null : DateTime.now().difference(checkedAt);
    final reachable =
        running &&
        ConnectionConst.isValidDelay(delay) &&
        age != null &&
        !age.isNegative &&
        age < const Duration(minutes: 2);
    final failed =
        connection.hasError || profiles.hasError || (status is Disconnected && status.connectionFailure != null);
    final viewState = running
        ? (reachable ? LineaConnectionState.connected : LineaConnectionState.checking)
        : profiles.isLoading
        ? LineaConnectionState.loading
        : failed
        ? LineaConnectionState.failed
        : profile == null
        ? LineaConnectionState.empty
        : busy
        ? LineaConnectionState.connecting
        : LineaConnectionState.idle;
    void add() => ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
    void routes() => context.goNamed('proxies');
    return LineaDashboard(
      state: viewState,
      profileCount: ref.watch(profilesNotifierProvider).valueOrNull?.length ?? 0,
      profileName: profile?.name,
      protocol: proxy?.type,
      latency: reachable ? delay : null,
      downloaded: stats?.trafficAvailable == true ? _bytes(stats!.downlinkTotal.toInt()) : null,
      uploaded: stats?.trafficAvailable == true ? _bytes(stats!.uplinkTotal.toInt()) : null,
      automatic: automatic != null && group?.selected == automatic.tag,
      onAutomatic: automatic == null || group == null
          ? null
          : (enabled) async {
              if (!enabled) {
                routes();
                return;
              }
              final t = ref.read(translationsProvider).requireValue;
              await ref.read(proxyRepositoryProvider).selectProxy(group.tag, automatic.tag).mapLeft((error) async {
                await ref.read(dialogNotifierProvider.notifier).showCustomAlertFromErr(error.present(t));
              }).run();
            },
      onAdd: add,
      onProfiles: () => context.goNamed('profiles'),
      onDiagnostics: () => context.goNamed('logs'),
      onSettings: () => ref.read(bottomSheetsNotifierProvider.notifier).showQuickSettings(),
      onRoutes: routes,
      onConnect: busy
          ? null
          : () async {
              if (profile == null && !running) {
                add();
                return;
              }
              final dialogs = ref.read(dialogNotifierProvider.notifier);
              if (running || await dialogs.showExperimentalFeatureNotice()) {
                await ref.read(connectionNotifierProvider.notifier).toggleConnection();
              }
            },
    );
  }
}

String _bytes(int value) {
  if (value < 1024) return '$value B';
  if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  if (value < 1024 * 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
