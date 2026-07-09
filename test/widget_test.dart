import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boxing_timer_flutter/core/design_system.dart';

void main() {
  testWidgets('DSTimerDial renders phase and time',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: DS.bg,
          body: Center(
            child: DSTimerDial(
              phaseText: 'ROUND 1/12',
              timeString: '03:00',
              progress: 0.25,
              diameter: 300,
            ),
          ),
        ),
      ),
    );

    expect(find.text('03:00'), findsOneWidget);
    expect(find.textContaining('ROUND'), findsOneWidget);
  });
}
