import 'package:flutter/material.dart';

enum LineaConnectionState { empty, loading, idle, connecting, connected, checking, failed }

/// A presentation-only screen. Opening it never starts the VPN or a probe.
class LineaDashboard extends StatelessWidget {
  const LineaDashboard({
    super.key,
    required this.state,
    required this.onConnect,
    required this.onAdd,
    required this.onProfiles,
    required this.onDiagnostics,
    required this.onSettings,
    required this.onRoutes,
    this.profileName,
    this.protocol,
    this.latency,
    this.downloaded,
    this.uploaded,
    this.automatic = false,
    this.onAutomatic,
    this.profileCount = 0,
  });
  final LineaConnectionState state;
  final VoidCallback? onConnect;
  final VoidCallback onAdd, onProfiles, onDiagnostics, onSettings, onRoutes;
  final String? profileName, protocol, downloaded, uploaded;
  final int? latency;
  final int profileCount;
  final bool automatic;
  final ValueChanged<bool>? onAutomatic;

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    String t(String en, String ruText) => ru ? ruText : en;
    final colors = Theme.of(context).colorScheme;
    final busy = state == LineaConnectionState.connecting || state == LineaConnectionState.loading;
    final active = state == LineaConnectionState.connected || state == LineaConnectionState.checking;
    final empty = state == LineaConnectionState.empty;
    final title = switch (state) {
      LineaConnectionState.empty => t('Add a connection', 'Добавьте подключение'),
      LineaConnectionState.loading => t('Loading', 'Загрузка'),
      LineaConnectionState.idle => t('Ready to connect', 'Готово к подключению'),
      LineaConnectionState.connecting => t('Connecting', 'Подключение'),
      LineaConnectionState.connected => t('You’re connected', 'Вы подключены'),
      LineaConnectionState.checking => t('VPN is on', 'VPN включён'),
      LineaConnectionState.failed => t('Connection interrupted', 'Соединение прервано'),
    };
    final description = switch (state) {
      LineaConnectionState.empty => t(
        'Import a link, a configuration file or a QR code',
        'Импортируйте ссылку, файл настроек или QR-код',
      ),
      LineaConnectionState.loading => t('Preparing your connections', 'Загружаем ваши подключения'),
      LineaConnectionState.idle => t('Your server is selected', 'Ваш сервер выбран'),
      LineaConnectionState.connecting => t('Starting the connection', 'Устанавливаем соединение'),
      LineaConnectionState.connected => t('The route passed its latest check', 'Последняя проверка маршрута успешна'),
      LineaConnectionState.checking => t('Checking internet access', 'Проверяем доступ в интернет'),
      LineaConnectionState.failed => t('Try again or open diagnostics', 'Попробуйте снова или откройте диагностику'),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linea', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        actions: [
          IconButton(
            tooltip: t('Diagnostics', 'Диагностика'),
            onPressed: onDiagnostics,
            icon: const Icon(Icons.monitor_heart_outlined),
          ),
          IconButton(
            tooltip: t('Add connection', 'Добавить подключение'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  t('A connection you control', 'Подключение под вашим контролем'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: active
                        ? const [Color(0xFF145746), Color(0xFF102F2C)]
                        : const [Color(0xFF233D42), Color(0xFF14262F)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        active
                            ? Icons.shield_rounded
                            : empty
                            ? Icons.add_link_rounded
                            : Icons.power_settings_new_rounded,
                        color: const Color(0xFFB8EACD),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(description, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFFCEE1DD))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('linea_primary_action'),
                        onPressed: busy
                            ? null
                            : empty
                            ? onAdd
                            : onConnect,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB8EACD),
                          foregroundColor: const Color(0xFF153F36),
                          disabledBackgroundColor: const Color(0xFF46665C),
                          disabledForegroundColor: Colors.white,
                          minimumSize: const Size(0, 56),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                empty
                                    ? t('Add connection', 'Добавить подключение')
                                    : active
                                    ? t('Disconnect', 'Отключить')
                                    : t('Connect', 'Подключить'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (!empty && state != LineaConnectionState.loading) ...[
                _Surface(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: onProfiles,
                    leading: _IconBox(icon: Icons.dns_outlined),
                    title: Text(
                      profileName ?? t('Current connection', 'Текущее подключение'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(t('All connections: $profileCount', 'Все подключения: $profileCount')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 12),
                  _Surface(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                        final columns = (constraints.maxWidth / (90 * scale)).floor().clamp(1, 3);
                        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 16,
                          children: [
                            _Metric(
                              width: width,
                              label: t('Latency', 'Задержка'),
                              value: latency == null ? '···' : '$latency ${t('ms', 'мс')}',
                            ),
                            _Metric(width: width, label: t('Downloaded', 'Получено'), value: downloaded ?? '···'),
                            _Metric(width: width, label: t('Uploaded', 'Отправлено'), value: uploaded ?? '···'),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Surface(
                    child: onAutomatic == null
                        ? ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: onRoutes,
                            leading: const Icon(Icons.alt_route_rounded),
                            title: Text(t('Select server', 'Выбрать сервер')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          )
                        : SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(t('Automatic selection', 'Автовыбор сервера')),
                            subtitle: Text(
                              t('Use an available server in this profile', 'Доступный сервер из этого профиля'),
                            ),
                            value: automatic,
                            onChanged: onAutomatic,
                          ),
                  ),
                ],
                const SizedBox(height: 12),
              ],
              _Surface(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.monitor_heart_outlined),
                      title: Text(t('Diagnostics', 'Диагностика')),
                      subtitle: Text(t('Connection events and report', 'События и отчёт о подключении')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: onDiagnostics,
                    ),
                    const Divider(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune_rounded),
                      title: Text(t('Connection settings', 'Настройки подключения')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: onSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => showAboutDialog(
                    context: context,
                    applicationName: 'Linea',
                    applicationLegalese:
                        'Based on Hiddify\ngithub.com/hiddify/hiddify-app\nHiddify Extended GNU GPL v3',
                  ),
                  child: Text(t('About Linea', 'О Linea')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .45)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 24, color: Theme.of(context).colorScheme.onPrimaryContainer),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.width, required this.label, required this.value});
  final double width;
  final String label, value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
