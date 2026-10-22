import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:hiddify/core/router/go_router/routing_config_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Iterable<GoRoute> routes(Iterable<RouteBase> roots) sync* {
  for (final route in roots) {
    if (route is GoRoute) yield route;
    if (route is ShellRoute) yield* routes(route.routes);
    if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        yield* routes(branch.routes);
      }
    }
    if (route is GoRoute) yield* routes(route.routes);
  }
}

void main() {
  test('phone dashboard links resolve to exactly one registered route', () {
    final container = ProviderContainer(overrides: [isMobileBreakpointProvider.overrideWithValue(true)]);
    addTearDown(container.dispose);
    final config = container.read(routingConfigNotifierProvider);
    final names = routes(config.routes).map((route) => route.name).toList();
    for (final name in ['home', 'profiles', 'proxies', 'logs', 'profileDetails']) {
      expect(names.where((value) => value == name), hasLength(1), reason: '$name must exist on phones');
    }
    final home = routes(config.routes).firstWhere((route) => route.name == 'home');
    expect(home.routes.whereType<GoRoute>().any((route) => route.name == 'profiles'), isTrue);
  });
}
