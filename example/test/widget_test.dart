// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Displays dynamic form and shows validation warning',
      (tester) async {
    await tester.pumpWidget(const FromDataExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Service Registration'), findsOneWidget);

    await tester.tap(find.text('Submit form'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Please double-check the required fields.'),
      findsOneWidget,
    );
  });
}
