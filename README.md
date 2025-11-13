# from_data

`from_data` is a Flutter library for rendering forms and managing state from schema-driven configuration. It lets you define complex forms in JSON or Dart maps and get a fully functional UI with validation, defaults, and extensibility.

## Features

- Schema-driven UI with support for text, number, email, password, multiline, dropdown, checkbox, and switch fields.
- Automatic state management, value hydration, and validation via `FromDataController`.
- Custom field builders and layout hooks so you can override specific field types.
- Built-in read-only mode, scroll configuration, and autovalidation options.

## Getting started

Install the package with your preferred package manager:

```bash
flutter pub add from_data
```

Then import it where you need to render a form:

```dart
import 'package:from_data/from_data.dart';
```

## Usage

Create a `FormSchema` from configuration and render it with `FromDataForm`. The controller takes care of value changes, default states, and validation.

```dart
final schema = FormSchema.fromJson({
  'id': 'profile',
  'title': 'Profile',
  'description': 'Tell us about yourself',
  'fields': [
    {
      'id': 'name',
      'type': 'text',
      'label': 'Full name',
      'required': true,
    },
    {
      'id': 'email',
      'type': 'email',
      'label': 'Email',
      'validations': [
        {'type': 'pattern', 'pattern': r'.+@.+\..+'},
      ],
    },
    {
      'id': 'newsletter',
      'type': 'switcher',
      'label': 'Subscribe to newsletter',
      'initialValue': true,
    },
  ],
});

class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FromDataForm(
      schema: schema,
      onChanged: (values) => debugPrint('Form values: $values'),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
```

Need more advanced usage? Check the full example app in `example/lib/main.dart`.

## Additional information

We welcome contributions and ideas. Feel free to open an issue or pull request.

- Example app: `example/lib/main.dart`
- Report issues: open a GitHub issue in this repository.
- License: see `LICENSE`.
