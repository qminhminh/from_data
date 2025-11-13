# from_data

`from_data` is a Flutter package that builds fully dynamic forms from JSON or Dart schemas. Define your form once as data, render it instantly in Flutter, and keep state management and validation consistent across the entire form.

## Features

- Generate forms from `FormSchema` objects or raw JSON.
- Support for common field types: text, number, email, password, multiline, dropdown, checkbox, and switch.
- Built-in validation rules: required, min/max length, min/max value, regex pattern.
- `FromDataController` keeps track of form values and exposes change notifications.
- Plug-and-play layout customization and custom builders for bespoke widgets.

## Installation

Add the dependency to your Flutter project (example with a local path):

```yaml
dependencies:
  from_data:
    path: ../from_data
```

Run `flutter pub get` afterwards.

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:from_data/from_data.dart';

final schema = FormSchema.fromJson({
  'title': 'Create Account',
  'fields': [
    {
      'id': 'name',
      'label': 'Full name',
      'type': 'text',
      'required': true,
      'validations': [
        {'type': 'minLength', 'value': 3, 'message': 'Name must be at least 3 characters.'},
      ],
    },
    {
      'id': 'email',
      'label': 'Email',
      'type': 'email',
      'required': true,
      'validations': [
        {'type': 'pattern', 'pattern': r'^[^@]+@[^@]+\.[^@]+$', 'message': 'Please enter a valid email.'},
      ],
    },
    {
      'id': 'plan',
      'label': 'Plan',
      'type': 'dropdown',
      'options': [
        {'value': 'free', 'label': 'Free', 'default': true},
        {'value': 'pro', 'label': 'Pro'},
      ],
    },
    {
      'id': 'accept',
      'label': 'I accept the terms',
      'type': 'checkbox',
      'required': true,
    },
  ],
});

final formKey = GlobalKey<FromDataFormState>();

class DemoForm extends StatelessWidget {
  const DemoForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FromDataForm(
      key: formKey,
      schema: schema,
      onChanged: (values) => debugPrint(values.toString()),
    );
  }
}
```

Call `formKey.currentState?.validate()` before submitting to ensure the input is valid and read results through `formKey.currentState?.values`.

## Full Example

Check the `example/` directory for a complete sample app that renders the form, handles submission, and shows the captured data.

## Contributing

- Please open an issue or pull request when you need a new feature or find a bug.
- Include reproduction steps or tests to speed up review.

Happy form building with `from_data`!
