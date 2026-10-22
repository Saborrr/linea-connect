import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/core/db/db.dart';
import 'package:hiddify/features/profile/data/profile_data_source.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';

void main() {
  late Db db;
  late ProfileDao dao;
  setUp(() {
    db = Db(NativeDatabase.memory());
    dao = ProfileDao(db);
  });
  tearDown(() => db.close());
  ProfileEntriesCompanion profile(String id, {String? url, bool active = false}) => ProfileEntriesCompanion.insert(
    id: id,
    type: url == null ? ProfileType.local : ProfileType.remote,
    active: active,
    name: 'Connection',
    lastUpdate: DateTime(2026),
    url: Value(url),
  );

  test('adding local configurations retains every row and the selection', () async {
    await dao.insert(profile('first'));
    await dao.insert(profile('second'));
    await dao.insert(profile('third'));
    final entries = await db.select(db.profileEntries).get();
    expect(entries.length, 3);
    expect(entries.map((e) => e.name).toSet().length, 3);
    expect(entries.where((e) => e.active).single.id, 'first');
  });
  test('different subscription URLs never match by substring or SQL wildcards', () async {
    await dao.insert(profile('long', url: 'https://example.com/sub/abc_extra'));
    await dao.insert(profile('short', url: 'https://example.com/sub/abc'));
    expect((await dao.getByUrl('https://example.com/sub/abc'))?.id, 'short');
    expect(await dao.getByUrl('https://example.com/sub/%'), isNull);
    expect(await dao.getByUrl('https://example.com/sub/abc_'), isNull);
    expect(await dao.watchProfilesCount().first, 2);
    expect((await dao.watchActiveProfile().first)?.id, 'long');
  });
  test('explicit selection changes only the active flag', () async {
    await dao.insert(profile('first'));
    await dao.insert(profile('second', active: true));
    final entries = await db.select(db.profileEntries).get();
    expect(entries.length, 2);
    expect(entries.where((e) => e.active).single.id, 'second');
  });
  test('editing a subscription preserves other connections', () async {
    await dao.insert(profile('first', url: 'https://example.com/one'));
    await dao.insert(profile('second', url: 'https://example.com/two'));
    await dao.edit('second', const ProfileEntriesCompanion(name: Value('Updated')));
    expect(await dao.watchProfilesCount().first, 2);
    expect((await dao.getById('first'))?.active, isTrue);
    expect((await dao.getById('second'))?.name, 'Updated');
  });
}
