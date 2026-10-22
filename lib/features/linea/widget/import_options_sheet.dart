import 'package:flutter/material.dart';

class ImportOptionsSheet extends StatelessWidget {
  const ImportOptionsSheet({
    super.key,
    required this.onClipboard,
    required this.onFile,
    required this.onManual,
    this.onQr,
    required this.onClose,
  });
  final VoidCallback onClipboard, onFile, onManual, onClose;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    String t(String en, String ruText) => ru ? ruText : en;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t('Add connection', 'Добавить подключение'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(tooltip: t('Close', 'Закрыть'), onPressed: onClose, icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            _ImportAction(
              key: const ValueKey('add_from_clipboard_button'),
              title: t('Paste link', 'Вставить ссылку'),
              subtitle: t('From the clipboard', 'Из буфера обмена'),
              icon: Icons.content_paste_rounded,
              onTap: onClipboard,
            ),
            _ImportAction(
              key: const ValueKey('add_from_file_button'),
              title: t('Open file', 'Открыть файл'),
              subtitle: t('Configuration or subscription', 'Настройки VPN или подписка'),
              icon: Icons.description_outlined,
              onTap: onFile,
            ),
            if (onQr != null)
              _ImportAction(
                key: const ValueKey('add_by_qr_code_button'),
                title: t('Scan QR code', 'Сканировать QR-код'),
                subtitle: t('Using the camera', 'С помощью камеры'),
                icon: Icons.qr_code_scanner_rounded,
                onTap: onQr!,
              ),
            _ImportAction(
              key: const ValueKey('add_manually_button'),
              title: t('Enter address', 'Ввести адрес'),
              subtitle: t('Subscription name and URL', 'Название и ссылка подписки'),
              icon: Icons.edit_outlined,
              onTap: onManual,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportAction extends StatelessWidget {
  const _ImportAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: colors.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
