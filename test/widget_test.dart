import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/widgets/custom_button.dart';
import 'package:real_estate_app/widgets/custom_text_field.dart';

void main() {
  testWidgets('CustomButton renders text and triggers callback', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Sign In',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    await tester.tap(find.byType(CustomButton));
    expect(pressed, isTrue);
  });

  testWidgets('CustomTextField renders label and hint', (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'Email',
            hint: 'Enter your email',
          ),
        ),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
  });
}
