// Linea contributions. Licensed under LICENSE.md.
import 'dart:convert';

enum DiagnosticSeverity { debug, info, warning, error }

enum DiagnosticCode {
  layoutOverflow,
  invalidConfiguration,
  serviceUnavailable,
  streamCancelled,
  providerFailure,
  unhandledException,
  timeout,
  dnsFailure,
  tlsFailure,
  authenticationFailure,
  engineFailure,
  connectionChanged,
  other,
}

/// Only fixed categories and package source locations leave the device.
/// Raw messages, exception text and logger names can contain credentials.
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.at,
    required this.severity,
    required this.code,
    this.component = 'app',
    this.frames = const [],
  });
  final DateTime at;
  final DiagnosticSeverity severity;
  final DiagnosticCode code;
  final String component;
  final List<String> frames;

  factory DiagnosticEvent.classify({
    required DateTime at,
    required int level,
    required String message,
    String loggerName = '',
    StackTrace? stack,
  }) {
    final lower = message.toLowerCase();
    final code = switch (lower) {
      _ when lower.contains('overflowed by') || lower.contains('renderflex') => DiagnosticCode.layoutOverflow,
      _ when lower.contains('invalid config') || lower.contains('invalid uapi') || lower.contains('unknown field') =>
        DiagnosticCode.invalidConfiguration,
      _
          when lower.contains('servicenotrunning') ||
              lower.contains('unavailable') ||
              lower.contains('connection refused') =>
        DiagnosticCode.serviceUnavailable,
      _ when lower.contains('cancelled') || lower.contains('canceled') => DiagnosticCode.streamCancelled,
      _ when lower.contains('provider') && (lower.contains('error') || lower.contains('failed')) =>
        DiagnosticCode.providerFailure,
      _
          when lower.contains('platformdispatchererror') ||
              lower.contains('flutter error') ||
              lower.contains('unhandled') =>
        DiagnosticCode.unhandledException,
      _ when lower.contains('timeout') || lower.contains('timed out') => DiagnosticCode.timeout,
      _ when lower.contains('dns') || lower.contains('lookup') => DiagnosticCode.dnsFailure,
      _ when lower.contains('tls') || lower.contains('certificate') || lower.contains('handshake') =>
        DiagnosticCode.tlsFailure,
      _ when lower.contains('unauthorized') || lower.contains('authentication failed') =>
        DiagnosticCode.authenticationFailure,
      _ when lower.contains('panic') || lower.contains('crash') || lower.contains('fatal error') =>
        DiagnosticCode.engineFailure,
      _ when lower.contains('connection status') => DiagnosticCode.connectionChanged,
      _ => DiagnosticCode.other,
    };
    // Match only app package filenames and numeric line/column positions.
    final frames = RegExp(
      r'package:hiddify/([a-zA-Z0-9_/]+\.dart:[0-9]+(?::[0-9]+)?)',
    ).allMatches(stack?.toString() ?? '').take(5).map((m) => m.group(1)!).toList();
    return DiagnosticEvent(
      at: at,
      severity: level >= 1000
          ? DiagnosticSeverity.error
          : level >= 900
          ? DiagnosticSeverity.warning
          : level >= 800
          ? DiagnosticSeverity.info
          : DiagnosticSeverity.debug,
      code: code,
      frames: frames,
      component: loggerName.startsWith('core.')
          ? 'core'
          : loggerName.startsWith('boot.')
          ? 'startup'
          : 'app',
    );
  }

  Map<String, Object> toJson() => {
    'time': at.toUtc().toIso8601String(),
    'severity': severity.name,
    'code': code.name,
    'component': component,
    if (frames.isNotEmpty) 'source': frames,
  };
}

String exportDiagnostics(
  Iterable<DiagnosticEvent> events, {
  List<Map<String, Object?>> previousErrors = const [],
  List<Map<String, Object?>> processExits = const [],
  Map<String, Object> runtime = const {},
}) => const JsonEncoder.withIndent('  ').convert({
  'format': 'linea-diagnostics',
  'schema': 2,
  'privacy': 'categories-and-app-source-locations',
  if (runtime.isNotEmpty) 'runtime': runtime,
  'events': events.take(5000).map((event) => event.toJson()).toList(),
  'previousErrors': previousErrors,
  'processExits': processExits,
});
