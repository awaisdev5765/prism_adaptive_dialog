import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_adaptive_dialog/prism_adaptive_dialog.dart';

/// Screenshot generator — renders an open destructive-confirmation dialog
/// into `doc/screenshot.png`.
/// Run with: `SCREENSHOTS=1 flutter test test/screenshot_test.dart`
void main() {
  const key = ValueKey('screenshot');

  Future<void> loadFonts() async {
    var dir = Directory('test/fonts');
    if (!dir.existsSync()) {
      dir = Directory('../prism_markdown/test/fonts');
    }
    if (!dir.existsSync()) return;
    final families = <String, List<Uint8List>>{};
    for (final file in dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.ttf'))) {
      final name = file.uri.pathSegments.last.replaceAll('.ttf', '');
      final family = name.startsWith('RobotoMono')
          ? 'monospace'
          : name.substring(0, name.indexOf('-'));
      (families[family] ??= []).add(file.readAsBytesSync());
    }
    for (final entry in families.entries) {
      final loader = FontLoader(entry.key);
      for (final bytes in entry.value) {
        loader.addFont(Future.value(bytes.buffer.asByteData()));
      }
      await loader.load();
    }
    final flutterRoot = File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .parent
        .parent
        .path;
    final iconFont = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (iconFont.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(iconFont.readAsBytesSync().buffer.asByteData()),
        );
      await loader.load();
    }
  }

  testWidgets(
    'capture dialog screenshot',
    (tester) async {
      await loadFonts();
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      late final BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B57D0),
            ),
          ),
          home: Builder(
            builder: (context) {
              hostContext = context;
              return RepaintBoundary(
                key: key,
                child: const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 56),
                        SizedBox(height: 8),
                        Text('Tap delete to see the adaptive dialog'),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Open the dialog, then capture the whole screen with the overlay.
      unawaited(
        PrismAdaptiveDialog.show<bool>(
          hostContext,
          title: 'Delete item?',
          builder: (context) => const Text('This cannot be undone.'),
          actions: [
            AdaptiveDialogAction.cancel(context),
            AdaptiveDialogAction.destructive(
              context,
              label: 'Delete',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData =
            await image.toByteData(format: ImageByteFormat.png);
        final file = File('doc/screenshot.png');
        await file.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
      });
    },
    skip: !Platform.environment.containsKey('SCREENSHOTS'),
  );
}
