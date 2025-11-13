import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:from_data/from_data.dart';

void main() {
  group('FormSchema', () {
    test('parses JSON schema and validations', () {
      final schema = FormSchema.fromJson({
        'title': 'Demo',
        'fields': [
          {
            'id': 'name',
            'label': 'Full name',
            'type': 'text',
            'required': true,
            'validations': [
              {'type': 'minLength', 'value': 3},
            ],
          },
          {
            'id': 'age',
            'label': 'Age',
            'type': 'number',
            'validations': [
              {'type': 'min', 'value': 18},
            ],
          },
        ],
      });

      expect(schema.fields, hasLength(2));
      final nameField = schema.fieldById('name');
      expect(nameField, isNotNull);
      expect(nameField!.required, isTrue);
      expect(nameField.validations, hasLength(1));
      expect(schema.fieldById('missing'), isNull);
    });
  });

  testWidgets('FromDataForm builds and validates input', (tester) async {
    final schema = FormSchema.fromJson({
      'fields': [
        {
          'id': 'name',
          'label': 'Full name',
          'type': 'text',
          'required': true,
        },
        {
          'id': 'age',
          'label': 'Age',
          'type': 'number',
          'validations': [
            {'type': 'min', 'value': 18},
          ],
        },
        {
          'id': 'accept',
          'label': 'I agree',
          'type': 'checkbox',
          'required': true,
        },
      ],
    });

    final formKey = GlobalKey<FromDataFormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FromDataForm(
            key: formKey,
            schema: schema,
          ),
        ),
      ),
    );

    expect(formKey.currentState, isNotNull);
    expect(formKey.currentState!.validate(), isFalse);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Minh',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Age'),
      '25',
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'I agree'));
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isTrue);
    expect(formKey.currentState!.values['name'], 'Minh');
    expect(formKey.currentState!.values['age'], 25);
    expect(formKey.currentState!.values['accept'], isTrue);
  });
}
