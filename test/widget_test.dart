import 'package:flutter_test/flutter_test.dart';
import 'package:novadrama/main.dart';

void main() {
  testWidgets('NovaDrama smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NovaDramaApp());
    expect(find.byType(NovaDramaApp), findsOneWidget);
  });
}
