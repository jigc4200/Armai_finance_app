import 'package:flutter_test/flutter_test.dart';
import 'package:financecopilot/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CopilotoFinancieroApp());
    await tester.pumpAndSettle();

    expect(find.text('Copiloto Financiero'), findsOneWidget);
  });
}
