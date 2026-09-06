import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_estate_app/models/country_code.dart';
import 'package:real_estate_app/widgets/custom_phone_field.dart';

void main() {
  testWidgets('CustomPhoneField renders default country code (+92) and flag',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPhoneField(
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('+92'), findsOneWidget);
    expect(find.text('🇵🇰'), findsOneWidget);
    expect(find.text('0 / 10 digits'), findsOneWidget);
  });

  testWidgets('CustomPhoneField limits input length according to country digits',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPhoneField(
            controller: controller,
          ),
        ),
      ),
    );

    // Enter 12 digits - should be capped at 10 digits for Pakistan
    await tester.enterText(find.byType(TextFormField), '300123456789');
    await tester.pump();

    expect(controller.text, '3001234567');
    expect(find.text('10 / 10 digits'), findsOneWidget);
  });

  testWidgets('CustomPhoneField strips leading zero automatically',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPhoneField(
            controller: controller,
          ),
        ),
      ),
    );

    // User types 03001234567 -> leading 0 should be stripped to 3001234567
    await tester.enterText(find.byType(TextFormField), '03001234567');
    await tester.pump();

    expect(controller.text, '3001234567');
  });

  testWidgets('CustomPhoneField validates empty and incomplete digits',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomPhoneField(
              controller: controller,
            ),
          ),
        ),
      ),
    );

    // Validate empty
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Please enter your phone number'), findsOneWidget);

    // Enter partial digits (5 digits)
    await tester.enterText(find.byType(TextFormField), '30012');
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.textContaining('Must be 10 digits for Pakistan (+92)'),
        findsOneWidget);

    // Enter full 10 digits
    await tester.enterText(find.byType(TextFormField), '3001234567');
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.textContaining('Must be 10 digits'), findsNothing);
  });

  testWidgets('CustomPhoneField opens country picker and updates selected country',
      (WidgetTester tester) async {
    final controller = TextEditingController();
    CountryCode? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomPhoneField(
            controller: controller,
            onCountryChanged: (c) => selected = c,
          ),
        ),
      ),
    );

    // Tap country code selector
    await tester.tap(find.text('+92'));
    await tester.pumpAndSettle();

    // Verify modal header is shown
    expect(find.text('Select Country Code'), findsOneWidget);

    // Select United Arab Emirates (+971)
    await tester.tap(find.text('United Arab Emirates'));
    await tester.pumpAndSettle();

    // Verify country code updated
    expect(find.text('+971'), findsOneWidget);
    expect(find.text('🇦🇪'), findsOneWidget);
    expect(find.text('0 / 9 digits'), findsOneWidget);
    expect(selected?.code, 'AE');
  });

  testWidgets('CustomPhoneField with isRequired=false passes validation when empty',
      (WidgetTester tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: CustomPhoneField(
              controller: controller,
              isRequired: false,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Please enter your phone number'), findsNothing);
  });

  test('CountryCode parsePhone correctly identifies dial code and number', () {
    final result = CountryCode.parsePhone('+92 300 1234567');
    expect(result.country.dialCode, '+92');
    expect(result.country.name, 'Pakistan');
    expect(result.localNumber, '300 1234567');

    final usResult = CountryCode.parsePhone('+1 416 555 0199');
    expect(usResult.country.dialCode, '+1');
  });
}
