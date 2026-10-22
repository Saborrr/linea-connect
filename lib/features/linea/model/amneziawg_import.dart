import 'dart:convert';

/// Validate before native parsing: the upstream converter silently discarded
/// unknown fields and malformed integers. Configuration values never enter an
/// error message. Native parsing remains the authority for keys and packets.
class AmneziaWgImport {
  static const parameters = {
    'jc',
    'jmin',
    'jmax',
    's1',
    's2',
    's3',
    's4',
    'h1',
    'h2',
    'h3',
    'h4',
    'i1',
    'i2',
    'i3',
    'i4',
    'i5',
    'headerprotectionkey',
    'contentpaddingaddition',
    'rekeyaftertime',
    'rekeytimeout',
    'rejectaftertime',
    'keepalivetimeout',
    'maxhandshakeattempts',
    'randomtrailers',
    'disablecookies',
  };
  static const interfaceKeys = {'privatekey', 'listenport', 'address', 'dns', 'mtu', ...parameters};

  static bool isAmnezia(String content) =>
      content.trimLeft().startsWith('awg://') ||
      RegExp(
        r'^\s*(Jc|Jmin|Jmax|S[1-4]|H[1-4]|I[1-5]|HeaderProtectionKey|RandomTrailers|ContentPaddingAddition|DisableCookies)\s*=',
        multiLine: true,
        caseSensitive: false,
      ).hasMatch(content);

  static String? validate(String content, [int depth = 0]) {
    if (depth > 3) return 'AmneziaWG: configuration nesting is too deep';
    final text = content.trim();
    if (text.startsWith('awg://') && text.contains('\n')) {
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
        final issue = validate(line.trim(), depth + 1);
        if (issue != null) return issue;
      }
      return null;
    }
    if (text.startsWith('awg://')) {
      final raw = text.substring(6).split('#').first;
      if (!raw.contains('?')) {
        try {
          return validate(utf8.decode(base64.decode(base64.normalize(raw))), depth + 1);
        } catch (_) {
          return 'AmneziaWG: invalid encoded configuration';
        }
      }
      final uri = Uri.tryParse(text);
      if (uri == null) return 'AmneziaWG: invalid connection link';
      final values = <String, String>{};
      const connectionKeys = {
        'pk',
        'privatekey',
        'publickey',
        'presharedkey',
        'psk',
        'address',
        'reserved',
        'mtu',
        'keepalive',
        'name',
        'allowedips',
        'dns',
        'listenport',
        'fragment',
        'peerpublickey',
        'pub',
        'peerpub',
        'peerpk',
        'ip',
        'localaddress',
        'persistentkeepalive',
      };
      for (final entry in uri.queryParameters.entries) {
        final key = entry.key.toLowerCase().replaceAll('_', '');
        if (parameters.contains(key))
          values[key] = entry.value;
        else if (!connectionKeys.contains(key))
          return 'AmneziaWG: this configuration uses unsupported parameters';
      }
      return _validateParameters(values);
    }
    if (text.contains('[Interface]') && isAmnezia(text)) {
      var section = '';
      var peerCount = 0;
      final values = <String, String>{};
      for (final rawLine in text.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) continue;
        if (line.startsWith('[')) {
          section = line.toLowerCase();
          if (section == '[peer]') peerCount++;
          continue;
        }
        if (section != '[interface]') continue;
        final separator = line.indexOf('=');
        if (separator < 0) return 'AmneziaWG: invalid configuration line';
        final key = line.substring(0, separator).trim().toLowerCase();
        if (!interfaceKeys.contains(key)) return 'AmneziaWG: this configuration uses unsupported parameters';
        if (parameters.contains(key)) {
          if (values.containsKey(key)) return 'AmneziaWG: duplicate parameter';
          values[key] = line.substring(separator + 1).trim();
        }
      }
      // The native .conf converter currently accepts one peer. Never silently
      // replace the preceding peer; use native endpoint JSON for multiple peers.
      if (peerCount > 1) return 'AmneziaWG: use endpoint JSON for a configuration with multiple peers';
      return _validateParameters(values);
    }
    if (text.startsWith('{') || text.startsWith('[')) {
      try {
        return _validateJson(jsonDecode(text));
      } on FormatException {
        return null;
      }
    }
    if (!text.contains('://') && !text.contains('[')) {
      try {
        final decoded = utf8.decode(base64.decode(base64.normalize(text)));
        if (decoded != text) return validate(decoded, depth + 1);
      } on FormatException {
        /* Not an encoded subscription. */
      }
    }
    for (final line in text.split('\n')) {
      if (line.trim().startsWith('awg://')) {
        final issue = validate(line.trim(), depth + 1);
        if (issue != null) return issue;
      }
    }
    return null;
  }

  static String? _validateJson(dynamic node) {
    if (node is List) {
      for (final child in node) {
        final issue = _validateJson(child);
        if (issue != null) return issue;
      }
    } else if (node is Map) {
      if (node['type'] == 'awg' && node['awg'] is Map) {
        final values = <String, String>{};
        for (final entry in (node['awg'] as Map).entries) {
          final key = entry.key.toString().toLowerCase().replaceAll('_', '');
          if (!parameters.contains(key)) return 'AmneziaWG: this configuration uses unsupported parameters';
          values[key] = entry.value.toString();
        }
        return _validateParameters(values);
      }
      for (final child in node.values) {
        final issue = _validateJson(child);
        if (issue != null) return issue;
      }
    }
    return null;
  }

  static String? _validateParameters(Map<String, String> values) {
    var enabled = false;
    for (final entry in values.entries) {
      final key = entry.key, value = entry.value;
      if (key == 'headerprotectionkey') {
        try {
          if (base64.decode(base64.normalize(value)).length != 32) return 'AmneziaWG: invalid header protection key';
        } on FormatException {
          return 'AmneziaWG: invalid header protection key';
        }
        for (final padding in ['s1', 's2', 's3', 's4']) {
          if ((int.tryParse(values[padding] ?? '') ?? 0) < 12)
            return 'AmneziaWG 3.1: S1–S4 must be at least 12 with header protection';
        }
        enabled = true;
        continue;
      }
      if (key == 'randomtrailers' || key == 'disablecookies') {
        if (!['true', 'false', 'on', 'off', '1', '0'].contains(value.toLowerCase()))
          return 'AmneziaWG: invalid boolean parameter';
        enabled |= ['true', 'on', '1'].contains(value.toLowerCase());
        continue;
      }
      if ([
        'contentpaddingaddition',
        'rekeyaftertime',
        'rekeytimeout',
        'rejectaftertime',
        'keepalivetimeout',
        'maxhandshakeattempts',
      ].contains(key)) {
        final range = value.split('-');
        if (value == '(off)') continue;
        if (range.length > 2 ||
            range.any((v) => int.tryParse(v) == null || int.parse(v) < 0 || int.parse(v) > 0xffffffff) ||
            (range.length == 2 && int.parse(range[0]) > int.parse(range[1])))
          return 'AmneziaWG: invalid timing or padding range';
        enabled |= range.any((v) => int.parse(v) > 0);
        continue;
      }
      if (key.startsWith('i')) {
        enabled |= value.isNotEmpty;
        continue;
      }
      if (key.startsWith('h')) {
        final range = value.split('-');
        if (range.length > 2 ||
            range.any((part) => int.tryParse(part) == null || int.parse(part) < 0 || int.parse(part) > 0xffffffff) ||
            (range.length == 2 && int.parse(range[0]) > int.parse(range[1])))
          return 'AmneziaWG: invalid header range';
        enabled |= range.any((part) => int.parse(part) > 0);
      } else {
        final number = int.tryParse(value);
        if (number == null || number < 0 || number > (key.startsWith('s') ? 65535 : 0xffffffff))
          return 'AmneziaWG: invalid numeric parameter';
        enabled |= number > 0;
      }
    }
    final min = int.tryParse(values['jmin'] ?? ''), max = int.tryParse(values['jmax'] ?? '');
    if (min != null && max != null && min > max) return 'AmneziaWG: minimum packet size exceeds maximum';
    if (!enabled) return 'AmneziaWG: no obfuscation parameters were supplied';
    return null;
  }
}
