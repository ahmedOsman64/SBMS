import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbms/core/shared/widgets/buttons.dart';

void main() {
  testWidgets('AppButton renders correct text and responds to taps', (WidgetTester tester) async {
    bool tapped = false;

    // Build the AppButton widget.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Test Button',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    // Verify button text is rendered.
    expect(find.text('Test Button'), findsOneWidget);

    // Tap button and verify callback triggers.
    await tester.tap(find.text('Test Button'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
