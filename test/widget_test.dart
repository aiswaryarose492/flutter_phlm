import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phlm/main.dart';

void main() {
  testWidgets('PHLM app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const PHLMApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
