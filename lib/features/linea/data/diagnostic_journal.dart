import 'dart:convert';
import 'dart:io';
import 'package:hiddify/features/linea/model/diagnostic_export.dart';

/// A small, credential-free error journal survives a process crash on phones.
/// Failure to write diagnostics must never stop the application.
class DiagnosticJournal {
  DiagnosticJournal(this.file);
  final File file;
  static const maxBytes = 128 * 1024;

  void append(DiagnosticEvent event) {
    if (event.severity != DiagnosticSeverity.error) return;
    try {
      file.parent.createSync(recursive: true);
      if (file.existsSync() && file.lengthSync() > maxBytes) {
        final lines = file.readAsLinesSync();
        file.writeAsStringSync('${lines.skip(lines.length ~/ 2).join('\n')}\n');
      }
      file.writeAsStringSync('${jsonEncode(event.toJson())}\n', mode: FileMode.append, flush: true);
    } catch (_) {
      /* Diagnostics cannot bring down the app. */
    }
  }

  List<Map<String, Object?>> read() {
    try {
      if (!file.existsSync()) return [];
      final events = <Map<String, Object?>>[];
      for (final line in file.readAsLinesSync()) {
        try {
          final value = jsonDecode(line);
          if (value is! Map<String, dynamic>) continue;
          // Re-allowlist persisted data too, including after an interrupted write.
          final code = DiagnosticCode.values.where((e) => e.name == value['code']).firstOrNull;
          final time = DateTime.tryParse(value['time']?.toString() ?? '');
          if (code == null || time == null) continue;
          final frames = (value['source'] is List ? value['source'] as List : const [])
              .whereType<String>()
              .where((f) => RegExp(r'^[a-zA-Z0-9_/]+\.dart:[0-9]+(?::[0-9]+)?$').hasMatch(f))
              .take(5)
              .toList();
          events.add(
            DiagnosticEvent(
              at: time,
              severity: DiagnosticSeverity.error,
              code: code,
              component: ['app', 'core', 'startup'].contains(value['component']) ? value['component'] as String : 'app',
              frames: frames,
            ).toJson(),
          );
        } catch (_) {
          /* A truncated final record is skipped. */
        }
      }
      return events.reversed.take(200).toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }
}
