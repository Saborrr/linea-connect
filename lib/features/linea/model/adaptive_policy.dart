// Linea contributions. Licensed under LICENSE.md with the Hiddify upstream.
// Pure policy only. See docs/linea/VALIDATION.md for runtime integration status.

enum NetworkAssessment {
  healthy,
  offline,
  captivePortal,
  suspectedRestrictions,
  unavailable,
  unknown,
}

class NetworkEvidence {
  const NetworkEvidence({
    required this.networkEpoch,
    required this.observedAt,
    required this.online,
    required this.captivePortal,
    required this.tunnelHealthy,
    this.independentLocalSuccesses = 0,
    this.independentGlobalFailures = 0,
  });

  final int networkEpoch;
  final DateTime observedAt;
  final bool online;
  final bool captivePortal;
  final bool tunnelHealthy;
  // Counts of distinct configured control origins, not repeated requests.
  final int independentLocalSuccesses;
  final int independentGlobalFailures;
}

class RouteCandidate {
  const RouteCandidate({
    required this.id,
    required this.networkEpoch,
    required this.verifiedAt,
    required this.tunnelVerified,
    required this.allowedForAuto,
    required this.runtimeSupported,
    required this.latencyMs,
  });
  final String id;
  final int networkEpoch;
  final DateTime verifiedAt;
  // Must be real end-to-end HTTP verification through this candidate.
  // A reachable server port or cached core ping is insufficient.
  final bool tunnelVerified;
  final bool allowedForAuto;
  final bool runtimeSupported;
  final int latencyMs;
}

class RouteDecision {
  const RouteDecision(
    this.assessment, {
    this.candidateId,
    this.failureCount = 0,
  });
  final NetworkAssessment assessment;
  final String? candidateId;
  final int failureCount;
}

/// Bounded failover with hysteresis. No network IO, timers or direct-route fallback.
/// The platform service must supply fresh measurements and acknowledge a switch.
class AdaptivePolicy {
  AdaptivePolicy({
    this.minimumFailures = 3,
    this.cooldown = const Duration(seconds: 30),
    this.sampleTtl = const Duration(seconds: 30),
    this.minimumSampleSpacing = const Duration(seconds: 3),
  }) {
    if (minimumFailures < 2 ||
        cooldown.isNegative ||
        sampleTtl <= Duration.zero ||
        minimumSampleSpacing <= Duration.zero) {
      throw ArgumentError('Invalid policy settings');
    }
  }

  final int minimumFailures;
  final Duration cooldown;
  final Duration sampleTtl;
  final Duration minimumSampleSpacing;
  int? _epoch;
  String? _route;
  DateTime? _lastSample;
  DateTime? _lastAttempt;
  int _failures = 0;
  int _selectiveFailures = 0;
  bool enabled = true;

  void userDisconnected() {
    enabled = false;
    _reset();
  }

  void userConnected() {
    enabled = true;
    _reset();
  }

  void _reset() {
    _epoch = null;
    _route = null;
    _lastSample = null;
    _lastAttempt = null;
    _failures = 0;
    _selectiveFailures = 0;
  }

  RouteDecision observe({
    required NetworkEvidence evidence,
    required String activeRoute,
    required List<RouteCandidate> candidates,
    required DateTime now,
  }) {
    if (!enabled) return const RouteDecision(NetworkAssessment.unknown);
    if (_epoch != evidence.networkEpoch || _route != activeRoute) {
      _epoch = evidence.networkEpoch;
      _route = activeRoute;
      _failures = 0;
      _selectiveFailures = 0;
      _lastSample = null;
      // Retain rate limiting on route changes, but never reuse measurements.
    }
    final age = now.difference(evidence.observedAt);
    if (age.isNegative || age > sampleTtl)
      return const RouteDecision(NetworkAssessment.unknown);
    if (_lastSample != null &&
        evidence.observedAt.difference(_lastSample!) < minimumSampleSpacing) {
      return RouteDecision(NetworkAssessment.unknown, failureCount: _failures);
    }
    if (_lastSample != null &&
        evidence.observedAt.difference(_lastSample!) > sampleTtl) {
      _failures = 0;
      _selectiveFailures = 0;
    }
    _lastSample = evidence.observedAt;
    if (!evidence.online || evidence.captivePortal) {
      _failures = 0;
      _selectiveFailures = 0;
      return RouteDecision(
        evidence.online
            ? NetworkAssessment.captivePortal
            : NetworkAssessment.offline,
      );
    }
    if (evidence.tunnelHealthy) {
      _failures = 0;
      _selectiveFailures = 0;
      return const RouteDecision(NetworkAssessment.healthy);
    }
    _failures++;
    final selective =
        evidence.independentLocalSuccesses >= 2 &&
        evidence.independentGlobalFailures >= 2;
    _selectiveFailures = selective ? _selectiveFailures + 1 : 0;
    final assessment = selective && _selectiveFailures >= minimumFailures
        ? NetworkAssessment.suspectedRestrictions
        : NetworkAssessment.unavailable;
    if (_failures < minimumFailures ||
        (_lastAttempt != null && now.difference(_lastAttempt!) < cooldown)) {
      return RouteDecision(assessment, failureCount: _failures);
    }
    final usable = candidates.where((candidate) {
      final candidateAge = now.difference(candidate.verifiedAt);
      return candidate.id != activeRoute &&
          candidate.allowedForAuto &&
          candidate.runtimeSupported &&
          candidate.tunnelVerified &&
          candidate.networkEpoch == evidence.networkEpoch &&
          !candidateAge.isNegative &&
          candidateAge <= sampleTtl &&
          candidate.latencyMs > 0;
    }).toList()..sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    if (usable.isEmpty)
      return RouteDecision(assessment, failureCount: _failures);
    // Reserve the attempt here, not after an awaited native call succeeds.
    _lastAttempt = now;
    return RouteDecision(
      assessment,
      candidateId: usable.first.id,
      failureCount: _failures,
    );
  }
}
