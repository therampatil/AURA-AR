import 'package:flutter_test/flutter_test.dart';
import 'package:ar_scan_app/main.dart';

void main() {
  testWidgets('AuraARApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AuraARApp());
    expect(find.text('AURA AR'), findsOneWidget);
    expect(find.text('START CONTINUOUS SCAN'), findsOneWidget);
  });
}
