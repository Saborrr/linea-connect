import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/utils/laststeam.dart';

void main() {
  test('native stream errors reach pending callers without escaping the zone', () async {
    final source = StreamController<int>();
    final last = LastStream(source.stream);
    final result = expectLater(last.get(), throwsStateError);
    source.addError(StateError('channel ended'));
    await result;
    source.add(7);
    await Future<void>.delayed(Duration.zero);
    expect(await last.get(), 7);
    await last.close();
    await source.close();
  });
  test('an idle stream error is handled and a later event remains usable', () async {
    final source = StreamController<int>();
    final last = LastStream(source.stream);
    source.addError(StateError('service stopped'));
    source.add(2);
    await Future<void>.delayed(Duration.zero);
    expect(await last.get(), 2);
    await last.close();
    await source.close();
  });
  test('closing releases waiters and rejects further reads', () async {
    final source = StreamController<int>();
    final last = LastStream(source.stream);
    final result = expectLater(last.get(), throwsStateError);
    await last.close();
    await result;
    await expectLater(last.get(), throwsStateError);
    await last.close();
    await source.close();
  });
}
