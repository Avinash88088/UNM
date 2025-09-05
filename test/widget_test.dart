import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: basic widget renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('AI Document Master')),
    ));

    expect(find.text('AI Document Master'), findsOneWidget);
  });
}