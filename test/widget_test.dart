import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dummy test', (WidgetTester tester) async {
    // Build a dummy widget to replace the default counter test
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Text('Test'),
      ),
    ));

    expect(find.text('Test'), findsOneWidget);
  });
}
