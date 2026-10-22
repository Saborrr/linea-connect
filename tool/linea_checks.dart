// Dependency-free checks: dart --enable-asserts tool/linea_checks.dart
import 'dart:convert';
import '../lib/features/linea/model/adaptive_policy.dart';
import '../lib/features/linea/model/diagnostic_export.dart';

var checks = 0;
void check(bool condition, String name) {
  checks++;
  if (!condition) throw StateError('FAIL: $name');
}

void main() {
  final start = DateTime.utc(2026, 10, 22, 10);
  NetworkEvidence sample(
    int second, {
    int epoch = 1,
    bool online = true,
    bool portal = false,
    bool healthy = false,
    int local = 2,
    int global = 2,
  }) => NetworkEvidence(
    networkEpoch: epoch,
    observedAt: start.add(Duration(seconds: second)),
    online: online,
    captivePortal: portal,
    tunnelHealthy: healthy,
    independentLocalSuccesses: local,
    independentGlobalFailures: global,
  );
  RouteCandidate candidate(
    int second, {
    String id = 'backup',
    int epoch = 1,
    bool verified = true,
    bool allowed = true,
    bool supported = true,
    int latency = 80,
  }) => RouteCandidate(
    id: id,
    networkEpoch: epoch,
    verifiedAt: start.add(Duration(seconds: second)),
    tunnelVerified: verified,
    allowedForAuto: allowed,
    runtimeSupported: supported,
    latencyMs: latency,
  );
  RouteDecision observe(
    AdaptivePolicy policy,
    int second, {
    NetworkEvidence? evidence,
    List<RouteCandidate>? candidates,
    String route = 'primary',
  }) => policy.observe(
    evidence: evidence ?? sample(second),
    activeRoute: route,
    candidates: candidates ?? [candidate(second)],
    now: start.add(Duration(seconds: second)),
  );

  var policy = AdaptivePolicy();
  check(observe(policy, 0).candidateId == null, 'one failure never switches');
  check(observe(policy, 4).candidateId == null, 'two failures never switch');
  final decision = observe(policy, 8);
  check(
    decision.candidateId == 'backup',
    'third independent failure proposes verified backup',
  );
  check(
    decision.assessment == NetworkAssessment.suspectedRestrictions,
    'selective evidence is only suspected',
  );
  check(
    observe(policy, 12).candidateId == null,
    'cooldown suppresses duplicate attempts',
  );
  check(observe(policy, 40).candidateId == 'backup', 'retry after cooldown');
  policy.userDisconnected();
  check(
    observe(policy, 44).candidateId == null,
    'manual disconnect cancels automation',
  );
  policy.userConnected();
  check(observe(policy, 48).failureCount == 1, 'new user session starts fresh');

  policy = AdaptivePolicy();
  observe(policy, 0);
  observe(policy, 4);
  check(
    observe(policy, 8, evidence: sample(8, online: false)).assessment ==
        NetworkAssessment.offline,
    'offline classified separately',
  );
  check(observe(policy, 12).failureCount == 1, 'offline resets hysteresis');
  check(
    observe(policy, 16, evidence: sample(16, portal: true)).assessment ==
        NetworkAssessment.captivePortal,
    'portal is not restriction evidence',
  );
  check(
    observe(policy, 20, evidence: sample(20, healthy: true)).assessment ==
        NetworkAssessment.healthy,
    'healthy tunnel resets failures',
  );

  policy = AdaptivePolicy();
  observe(policy, 0);
  observe(policy, 4);
  check(
    observe(policy, 8, evidence: sample(8, epoch: 2)).failureCount == 1,
    'network change invalidates samples',
  );
  check(
    observe(policy, 12, route: 'different').failureCount == 1,
    'route change invalidates samples',
  );

  for (final invalid in [
    candidate(8, verified: false),
    candidate(8, allowed: false),
    candidate(8, supported: false),
    candidate(8, epoch: 0),
    candidate(-100),
    candidate(80),
    candidate(8, latency: 0),
    candidate(8, id: 'primary'),
  ]) {
    policy = AdaptivePolicy();
    observe(policy, 0);
    observe(policy, 4);
    check(
      observe(policy, 8, candidates: [invalid]).candidateId == null,
      'reject ineligible candidate',
    );
  }
  policy = AdaptivePolicy();
  observe(policy, 0);
  observe(policy, 4);
  check(
    observe(
          policy,
          8,
          candidates: [
            candidate(8, id: 'slow', latency: 200),
            candidate(8, id: 'fast', latency: 30),
          ],
        ).candidateId ==
        'fast',
    'prefer best verified candidate',
  );
  policy = AdaptivePolicy();
  observe(policy, 0);
  observe(policy, 4);
  check(
    observe(policy, 8, evidence: sample(8, local: 0, global: 0)).assessment ==
        NetworkAssessment.unavailable,
    'outage is not a proven allowlist',
  );
  policy = AdaptivePolicy();
  observe(policy, 0);
  check(
    observe(policy, 1).failureCount == 1,
    'bursty events do not increase failure count',
  );
  check(
    observe(policy, 100, evidence: sample(1)).assessment ==
        NetworkAssessment.unknown,
    'stale evidence rejected',
  );
  check(
    observe(policy, 100, evidence: sample(101)).assessment ==
        NetworkAssessment.unknown,
    'future evidence rejected',
  );

  policy = AdaptivePolicy();
  observe(policy, 0, evidence: sample(0, local: 0));
  observe(policy, 4, evidence: sample(4, local: 0));
  check(
    observe(policy, 8).assessment == NetworkAssessment.unavailable,
    'one selective sample cannot establish persistent restrictions',
  );
  policy = AdaptivePolicy();
  observe(policy, 0);
  observe(policy, 4);
  check(
    observe(policy, 100).failureCount == 1,
    'long sampling gap resets history',
  );

  const secrets = [
    'vless://SECRET@vpn.example:443',
    'https://panel.example/sub/VERY_SECRET',
    'password=UNKNOWNSECRET',
    '{"newField":"PRIVATEKEY"}',
    'YW55LXNlY3JldC1oZXJl',
  ];
  final raw = 'timeout ${secrets.join(' ')}';
  final report = exportDiagnostics([
    DiagnosticEvent.classify(at: start, level: 1000, message: raw),
  ]);
  for (final secret in secrets) {
    check(!report.contains(secret), 'arbitrary secret never serialized');
  }
  final decoded = jsonDecode(report) as Map<String, dynamic>;
  check(
    decoded['events'][0]['code'] == 'timeout',
    'useful failure code survives',
  );
  check(decoded['events'][0]['severity'] == 'error', 'severity survives');
  check(
    DiagnosticEvent.classify(
          at: start,
          level: 900,
          message: 'TLS certificate failed',
        ).code ==
        DiagnosticCode.tlsFailure,
    'TLS categorization',
  );
  check(
    DiagnosticEvent.classify(
          at: start,
          level: 900,
          message: 'dns lookup failed',
        ).code ==
        DiagnosticCode.dnsFailure,
    'DNS categorization',
  );
  check(
    (jsonDecode(
                  exportDiagnostics(
                    List.generate(
                      6000,
                      (_) => DiagnosticEvent(
                        at: start,
                        severity: DiagnosticSeverity.info,
                        code: DiagnosticCode.other,
                      ),
                    ),
                  ),
                )['events']
                as List)
            .length ==
        5000,
    'export size bounded',
  );
  print('PASS: $checks Linea policy and diagnostic checks');
}
