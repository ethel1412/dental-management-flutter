import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scan_my_tooth/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
