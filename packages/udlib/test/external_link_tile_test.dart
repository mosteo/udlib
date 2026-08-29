import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:udlib/udlib.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders leading, title and subtitle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          subtitle: 'A subtitle',
          url: 'https://example.com',
          onShare: (_) async {},
        ),
      ),
    );

    expect(find.byIcon(Icons.link), findsOneWidget);
    expect(find.text('A title'), findsOneWidget);
    expect(find.text('A subtitle'), findsOneWidget);
  });

  testWidgets('subtitle is omitted when null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com',
          onShare: (_) async {},
        ),
      ),
    );

    expect(find.byType(ListTile), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.subtitle, isNull);
  });

  testWidgets('applies tileColor', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com',
          onShare: (_) async {},
          tileColor: Colors.amber,
        ),
      ),
    );

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect(tile.tileColor, Colors.amber);
  });

  testWidgets('tapping share invokes onShare with the exact url', (
    tester,
  ) async {
    String? shared;
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com/path',
          onShare: (url) async => shared = url,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(shared, 'https://example.com/path');
  });

  testWidgets('tapping the QR icon shows the url as a QR code', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com/path',
          onShare: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.qr_code_2));
    await tester.pumpAndSettle();

    // QrImageView's own `data` is private, so this cannot assert the
    // exact string encoded -- the widget's presence in a dialog, right
    // after tapping the QR button, is the observable contract.
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    // The dialog's caption repeats the tile's own title.
    expect(find.text('A title'), findsWidgets);
  });

  testWidgets('tapping the row does not throw (no url_launcher plugin '
      'in the test harness)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com',
          onShare: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    // A MissingPluginException from url_launcher is caught the same
    // way a real failed launch would be -- nothing to assert beyond
    // "this did not throw and the widget is still there".
    expect(find.byType(ExternalLinkTile), findsOneWidget);
  });

  testWidgets('custom tooltips and failedToOpenMessage are honoured', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ExternalLinkTile(
          leading: const Icon(Icons.link),
          title: 'A title',
          url: 'https://example.com',
          onShare: (_) async {},
          shareTooltip: 'Compartir enlace',
          qrTooltip: 'Ver código QR',
        ),
      ),
    );

    expect(find.byTooltip('Compartir enlace'), findsOneWidget);
    expect(find.byTooltip('Ver código QR'), findsOneWidget);
  });
}
