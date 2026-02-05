import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart' show SmartShiftApp;

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartShiftApp());
    expect(find.byType(SmartShiftApp), findsOneWidget);
  });
}
