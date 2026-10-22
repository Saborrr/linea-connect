import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiddify/features/linea/widget/import_options_sheet.dart';
import 'package:hiddify/features/linea/widget/connection_row.dart';
import 'package:hiddify/features/linea/widget/linea_dashboard.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final font = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
    if (font.existsSync()) {
      final bytes = await font.readAsBytes();
      await (FontLoader('LineaPreview')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  Widget app(Widget child, double scale) => MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF13785C)),
      scaffoldBackgroundColor: const Color(0xFFFAFCFA),
      fontFamily: 'LineaPreview',
    ),
    builder: (context, child) => RepaintBoundary(
      key: const ValueKey('preview'),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
    home: child,
  );

  LineaDashboard dashboard(LineaConnectionState state, {VoidCallback? onAdd}) => LineaDashboard(
    state: state,
    onConnect: () {},
    onAdd: onAdd ?? () {},
    onProfiles: () {},
    onDiagnostics: () {},
    onSettings: () {},
    onRoutes: () {},
    profileName: 'Мой сервер · Амстердам',
    profileCount: 3,
    latency: 48,
    downloaded: '24.8 MB',
    uploaded: '3.1 MB',
    onAutomatic: (_) {},
  );
  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('preview')));
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/linea-previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('dashboard and import fit width $width with font scale $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final state in [LineaConnectionState.empty, LineaConnectionState.connected]) {
          await tester.pumpWidget(app(dashboard(state), scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (width == 390 && scale == 1) await capture(tester, state.name);
        }
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ImportOptionsSheet(
                  onClipboard: () {},
                  onFile: () {},
                  onManual: () {},
                  onQr: () {},
                  onClose: () {},
                ),
              ),
            ),
            scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const ValueKey('add_manually_button')));
        expect(tester.takeException(), isNull);
        if (width == 390 && scale == 1) await capture(tester, 'import');
      });
    }
  }
  testWidgets('compact connection list retains labels and tap targets', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    Widget list(double scale) => app(
      Scaffold(
        appBar: AppBar(title: const Text('Подключения')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 12,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) => ConnectionRow(
            key: ValueKey('connection_$i'),
            name: ['Мой сервер · Амстердам', 'Резервный · Франкфурт', 'AmneziaWG 3.1 · Хельсинки'][i % 3],
            subtitle: i == 0 ? 'Выбрано' : 'Настройки VPN',
            selected: i == 0,
            onTap: () => selected = i,
            trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ),
        ),
      ),
      scale,
    );
    await tester.pumpWidget(list(1));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('connection_0'))).height, lessThanOrEqualTo(84));
    await tester.tap(find.text('Резервный · Франкфурт').first);
    expect(selected, 1);
    await capture(tester, 'profiles');
    tester.view.physicalSize = const Size(320, 844);
    await tester.pumpWidget(list(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('preview import over the dashboard', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(dashboard(LineaConnectionState.empty), 1));
    showModalBottomSheet<void>(
      context: tester.element(find.byType(Scaffold)),
      isScrollControlled: true,
      builder: (context) =>
          ImportOptionsSheet(onClipboard: () {}, onFile: () {}, onManual: () {}, onQr: () {}, onClose: () {}),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(tester, 'import');
  });
  testWidgets('empty primary action adds a profile, without attempting VPN', (tester) async {
    var count = 0;
    await tester.pumpWidget(app(dashboard(LineaConnectionState.empty, onAdd: () => count++), 1));
    await tester.tap(find.byKey(const ValueKey('linea_primary_action')));
    expect(count, 1);
    expect(find.text('Автовыбор сервера'), findsNothing);
  });
}
