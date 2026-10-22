// Linea contributions. Licensed under LICENSE.md.
import 'dart:convert';

enum DiagnosticSeverity { debug, info, warning, error }

enum DiagnosticCode {
  timeout,
  dnsFailure,
  tlsFailure,
  authenticationFailure,
  engineFailure,
  connectionChanged,
  other,
}

/// Export uses an allowlist of fields. Raw messages and logger names are never
/// serialized, even if a secret uses an unknown key or appears inside base64.
class DiagnosticEvent {
  const DiagnosticEvent({
    required this.at,
    required this.severity,
    required this.code,
  });
  final DateTime at;
  final DiagnosticSeverity severity;
  final DiagnosticCode code;

  factory DiagnosticEvent.classify({
    required DateTime at,
    required int level,
    required String message,
  }) {
    final lower = message.toLowerCase();
    final code = switch (lower) {
      _ when lower.contains('timeout') || lower.contains('timed out') =>
        DiagnosticCode.timeout,
      _ when lower.contains('dns') || lower.contains('lookup') =>
        DiagnosticCode.dnsFailure,
      _
          when lower.contains('tls') ||
              lower.contains('certificate') ||
              lower.contains('handshake') =>
        DiagnosticCode.tlsFailure,
      _
          when lower.contains('unauthorized') ||
              lower.contains('authentication failed') =>
        DiagnosticCode.authenticationFailure,
      _ when lower.contains('panic') || lower.contains('crash') =>
        DiagnosticCode.engineFailure,
      _ when lower.contains('connection status') =>
        DiagnosticCode.connectionChanged,
      _ => DiagnosticCode.other,
    };
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
    );
  }

  Map<String, Object> toJson() => {
    'time': at.toUtc().toIso8601String(),
    'severity': severity.name,
    'code': code.name,
  };
}

String exportDiagnostics(Iterable<DiagnosticEvent> events) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': 'linea-diagnostics',
      'schema': 1,
      'privacy': 'event-codes-only',
      'events': events.take(5000).map((event) => event.toJson()).toList(),
    });
