import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hiddify/features/linea/data/diagnostic_journal.dart';
import 'package:hiddify/features/linea/model/diagnostic_export.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> buildDiagnosticReport(Iterable<LogRecord> records, Directory directory) async {
  var exits = <Map<String, Object?>>[];
  if (Platform.isAndroid) {
    try {
      final result = await const MethodChannel('com.hiddify.app/method').invokeListMethod<dynamic>('getLastExitInfo');
      exits = (result ?? [])
          .whereType<Map>()
          .map(
            (value) => <String, Object?>{
              // Numeric process metadata only, no Android description or trace text.
              for (final key in ['reason', 'status', 'timestamp', 'pss', 'rss', 'importance'])
                if (value[key] is int) key: value[key] as int,
            },
          )
          .take(5)
          .toList();
    } on PlatformException {
      /* Older Android or restricted OEM API. */
    } on MissingPluginException {
      /* Unsupported platform. */
    }
  }
  final info = await PackageInfo.fromPlatform();
  return exportDiagnostics(
    records.map(
      (r) => DiagnosticEvent.classify(
        at: r.time,
        level: r.level.value,
        message: '${r.message} ${r.error ?? ''}',
        loggerName: r.loggerName,
        stack: r.stackTrace,
      ),
    ),
    previousErrors: DiagnosticJournal(File('${directory.path}/linea-diagnostics.jsonl')).read(),
    processExits: exits,
    runtime: {'platform': Platform.operatingSystem, 'appVersion': info.version, 'build': info.buildNumber},
  );
}
