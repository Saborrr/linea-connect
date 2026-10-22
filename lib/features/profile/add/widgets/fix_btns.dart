import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/features/linea/widget/import_options_sheet.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtns extends ConsumerWidget {
  const FixBtns({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ImportOptionsSheet(
      onClose: () => Navigator.of(context).pop(),
      onClipboard: () async {
        final text = await Clipboard.getData(Clipboard.kTextPlain);
        if (context.mounted) await ref.read(addProfileNotifierProvider.notifier).addClipboard(text?.text ?? '');
      },
      onFile: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['txt', 'json', 'yaml', 'yml', 'conf', 'ovpn', 'zip'],
        );
        if (result == null || !context.mounted) return;
        final picked = result.files.single;
        var bytes = picked.bytes;
        if (bytes == null) {
          final path = picked.path;
          if (path == null) return;
          final file = File(path);
          if (!await file.exists()) return;
          bytes = await file.readAsBytes();
        }
        if (!context.mounted) return;
        final notifier = ref.read(addProfileNotifierProvider.notifier);
        if (picked.extension?.toLowerCase() == 'zip') {
          await notifier.addArchive(bytes, name: picked.name.replaceFirst(RegExp(r'\.zip$', caseSensitive: false), ''));
        } else {
          await notifier.addClipboard(decodeTextBytes(bytes));
        }
      },
      onQr: PlatformUtils.isDesktop
          ? null
          : () async {
              final text = await ref.read(dialogNotifierProvider.notifier).showQrScanner();
              if (text != null && context.mounted)
                await ref.read(addProfileNotifierProvider.notifier).addClipboard(text);
            },
      onManual: () => ref.read(addProfilePageNotifierProvider.notifier).goManual(),
    );
  }
}
