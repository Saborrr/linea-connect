import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/linea/model/amneziawg_import.dart';
import 'package:hiddify/features/profile/data/profile_parser.dart';

void main() {
  final key = base64.encode(List.filled(32, 7));
  final conf =
      '''[Interface]
PrivateKey = $key
Address = 10.0.0.2/32
Jc = 4
Jmin = 10
Jmax = 40
S1 = 16
S2 = 16
S3 = 16
S4 = 16
H1 = 1
H2 = 2
H3 = 3
H4 = 4
HeaderProtectionKey = $key
ContentPaddingAddition = 0-64
RekeyAfterTime = 100-120
RekeyTimeout = 4-6
RejectAfterTime = 170-190
KeepaliveTimeout = 8-12
MaxHandshakeAttempts = 15-20
RandomTrailers = true
DisableCookies = on
[Peer]
PublicKey = $key
Endpoint = 192.0.2.1:443
PersistentKeepalive = 22-30
''';
  test('3.1 conf and base64 awg link retain all supported fields', () {
    expect(AmneziaWgImport.validate(conf), isNull);
    expect(AmneziaWgImport.validate('awg://${base64.encode(utf8.encode(conf))}'), isNull);
    expect(ProfileParser.protocol(conf), 'AmneziaWG');
  });
  test('AWG 2.0 remains accepted', () {
    expect(AmneziaWgImport.validate('[Interface]\nJc = 4\nS3 = 20\nS4 = 24'), isNull);
  });
  test('3.1 JSON and query ranges are accepted', () {
    final parameters = {
      'header_protection_key': key,
      's1': 12,
      's2': 12,
      's3': 12,
      's4': 12,
      'random_trailers': true,
      'content_padding_addition': '0-64',
    };
    expect(
      AmneziaWgImport.validate(
        jsonEncode({
          'endpoints': [
            {'type': 'awg', 'awg': parameters},
          ],
        }),
      ),
      isNull,
    );
    final link = Uri(
      scheme: 'awg',
      host: 'example.com',
      port: 443,
      queryParameters: {for (final e in parameters.entries) e.key: e.value.toString(), 'pk': key, 'pub': key},
    );
    expect(AmneziaWgImport.validate(link.toString()), isNull);
  });
  test('incorrect numeric fields do not silently become zero', () {
    expect(AmneziaWgImport.validate(conf.replaceFirst('Jc = 4', 'Jc = WRONG_SECRET')), isNotNull);
    expect(AmneziaWgImport.validate(conf.replaceFirst('Jc = 4', 'Jc = WRONG_SECRET')), isNot(contains('WRONG_SECRET')));
    expect(AmneziaWgImport.validate(conf.replaceFirst('Jmin = 10', 'Jmin = 90')), isNotNull);
  });
  test('header protection requires matching nonce padding and a valid key', () {
    expect(AmneziaWgImport.validate(conf.replaceFirst('S3 = 16', 'S3 = 0')), isNotNull);
    expect(
      AmneziaWgImport.validate(conf.replaceFirst('HeaderProtectionKey = $key', 'HeaderProtectionKey = bad')),
      isNotNull,
    );
  });
  test('unknown generations and multiple .conf peers cannot silently downgrade', () {
    expect(AmneziaWgImport.validate(conf.replaceFirst('[Peer]', 'FutureSecretSetting = secret\n[Peer]')), isNotNull);
    expect(AmneziaWgImport.validate('$conf\n[Peer]\nPublicKey = $key'), isNotNull);
  });
  test('deeply nested imported JSON is rejected before overflowing the stack', () {
    final nested = '${'[' * 100}0${']' * 100}';
    expect(AmneziaWgImport.validate(nested), contains('nesting'));
  });
}
