import 'package:flutter_test/flutter_test.dart';
import 'package:bioniq_app/main.dart';

void main() {
  testWidgets('Bioniq app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BioniqApp());
    expect(find.text('Welcome to Bioniq'), findsOneWidget);
  });
}