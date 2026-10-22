import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/linea/data/diagnostic_journal.dart';
import 'package:hiddify/features/linea/model/diagnostic_export.dart';

void main() {
  test('report preserves useful app source without credentials or external frames', () {
    final event = DiagnosticEvent.classify(
      at: DateTime(2026),
      level: 1000,
      message: 'Flutter error RenderFlex overflowed by 2 pixels https://secret/sub/KEY',
      stack: StackTrace.fromString(
        '#0 Test (package:hiddify/features/home/widget/home_page.dart:42:3)\n#1 https://SECRET\n#2 unknown (/private/SECRET.dart:2:3)',
      ),
    );
    final report = exportDiagnostics([event]);
    expect(report, contains('layoutOverflow'));
    expect(report, contains('home_page.dart:42:3'));
    expect(report, isNot(contains('secret/sub')));
    expect(report, isNot(contains('SECRET')));
  });
  test('error journal survives restart and ignores a truncated crash write', () async {
    final directory = await Directory.systemTemp.createTemp('linea-journal');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/errors.jsonl');
    DiagnosticJournal(
      file,
    ).append(DiagnosticEvent.classify(at: DateTime(2026), level: 1000, message: 'PlatformDispatcherError: SECRET'));
    file.writeAsStringSync('{broken', mode: FileMode.append);
    final records = DiagnosticJournal(file).read();
    expect(records.single['code'], 'unhandledException');
    expect(file.readAsStringSync(), isNot(contains('SECRET')));
  });
}
