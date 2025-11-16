# from_data

A powerful Flutter library for building dynamic, schema-driven forms with automatic field rendering, validation, and state management. Define your forms using JSON or Dart maps and get a fully functional, production-ready form UI.

## What is from_data?

`from_data` is a **schema-driven form builder** that allows you to:

- **Define forms declaratively** using JSON or Dart maps instead of writing repetitive form code
- **Generate UI automatically** from schema definitions
- **Manage form state** with a built-in controller
- **Validate inputs** with flexible validation rules
- **Support any data type** (String, int, Map, List, Object, etc.) without restrictions
- **Extend and customize** with custom field builders

## Use Cases

### 1. **Dynamic Forms from API/Schema**
Build forms based on schema data received from your backend:

```dart
// Load form schema from API
final schemaResponse = await http.get('/api/form-schema');
final schema = FormSchema.fromJson(jsonDecode(schemaResponse.body));

// Render form automatically
FromDataForm(schema: schema)
```

### 2. **Multi-step Registration/Wizard Forms**
Create complex multi-step forms with different fields per step:

```dart
final step1Schema = FormSchema.fromJson(step1Config);
final step2Schema = FormSchema.fromJson(step2Config);
// Easy to switch between steps
```

### 3. **Configuration Forms**
Build admin panels or settings forms where field structure changes dynamically:

```dart
// Form structure depends on user role or permissions
final fields = getFieldsForUser(userRole);
final schema = FormSchema(fields: fields);
```

### 4. **Data Collection Apps**
Create surveys, questionnaires, or data entry forms with various field types:

```dart
// Survey with text, dropdowns, checkboxes, dates
final surveySchema = FormSchema.fromJson(surveyConfig);
```

### 5. **CRUD Forms**
Build create/edit forms with conditional fields and validation:

```dart
// Same schema for create and edit, just different initial values
FromDataForm(
  schema: formSchema,
  initialValues: editMode ? existingData : null,
)
```

## Features

- **12 Field Types**: text, number, email, password, multiline, dropdown, checkbox, switch, **date, time, datetime**
- **Universal Data Type Support**: Accepts any data type (String, int, double, bool, Map, List, Object, etc.) without restrictions
- **React Native-style API**: Convenient methods like `append()`, `get()`, `getAll()`, `set()`, `delete()`, `has()`, `clear()`
- **Automatic State Management**: Built-in controller handles form values, validation, and change notifications
- **Flexible Validation**: Min/max length, min/max value, pattern matching, and custom validators
- **Customizable**: Override field rendering with custom builders and layout hooks
- **Read-only Mode**: Display forms in view-only mode
- **Auto-validation**: Configure when validation triggers (on user interaction, on submit, etc.)

## Getting Started

### Installation

Add `from_data` to your `pubspec.yaml`:

```bash
flutter pub add from_data
```

Or manually:

```yaml
dependencies:
  from_data: ^0.2.0
```

Then import it:

```dart
import 'package:from_data/from_data.dart';
```

## Usage Guide

### Basic Usage

Create a form schema and render it:

```dart
final schema = FormSchema.fromJson({
  'title': 'User Profile',
  'description': 'Please fill in your information',
  'fields': [
    {
      'id': 'name',
      'label': 'Full Name',
      'type': 'text',
      'required': true,
      'validations': [
        {
          'type': 'minLength',
          'value': 3,
          'message': 'Name must be at least 3 characters',
        },
      ],
    },
    {
      'id': 'email',
      'label': 'Email Address',
      'type': 'email',
      'required': true,
      'validations': [
        {
          'type': 'pattern',
          'pattern': r'^[^@]+@[^@]+\.[^@]+$',
          'message': 'Please enter a valid email',
        },
      ],
    },
    {
      'id': 'newsletter',
      'label': 'Subscribe to newsletter',
      'type': 'switcher',
      'initialValue': true,
    },
  ],
});

class MyForm extends StatelessWidget {
  const MyForm({super.key});

  @override
  Widget build(BuildContext context) {
    return FromDataForm(
      schema: schema,
      onChanged: (values) {
        print('Form values changed: $values');
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
```

### Using Form Controller

Access and manipulate form values programmatically:

```dart
class MyFormPage extends StatefulWidget {
  const MyFormPage({super.key});

  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final _formKey = GlobalKey<FromDataFormState>();
  late final FromDataController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FromDataController();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final values = _formKey.currentState!.values;
      // Submit values to API
      print('Submitting: $values');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FromDataForm(
        key: _formKey,
        controller: _controller,
        schema: schema,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSubmit,
        child: const Icon(Icons.send),
      ),
    );
  }
}
```

### Field Types

#### Text Fields

```dart
{
  'id': 'name',
  'label': 'Name',
  'type': 'text',          // Single-line text
  // or 'email'            // Email keyboard
  // or 'password'         // Password (obscured)
  // or 'multiline'        // Multi-line text
}
```

#### Number Field

```dart
{
  'id': 'age',
  'label': 'Age',
  'type': 'number',
  'validations': [
    {'type': 'min', 'value': 18, 'message': 'Must be 18+'},
    {'type': 'max', 'value': 100, 'message': 'Must be under 100'},
  ],
}
```

#### Date/Time Pickers

```dart
{
  'id': 'birthDate',
  'label': 'Birth Date',
  'type': 'date',          // Date picker
  // or 'time'             // Time picker
  // or 'datetime'         // Date & Time picker
}
```

#### Dropdown

```dart
{
  'id': 'country',
  'label': 'Country',
  'type': 'dropdown',
  'options': [
    {'value': 'us', 'label': 'United States'},
    {'value': 'uk', 'label': 'United Kingdom'},
    {'value': 'ca', 'label': 'Canada'},
  ],
}
```

#### Checkbox & Switch

```dart
{
  'id': 'acceptTerms',
  'label': 'I accept the terms',
  'type': 'checkbox',      // Checkbox
  // or 'switcher'         // Switch/Toggle
  'required': true,
}
```

### Validation

#### Built-in Validation Types

```dart
{
  'validations': [
    // Minimum length
    {
      'type': 'minLength',
      'value': 5,
      'message': 'Must be at least 5 characters',
    },
    // Maximum length
    {
      'type': 'maxLength',
      'value': 50,
      'message': 'Must be less than 50 characters',
    },
    // Minimum value (for numbers)
    {
      'type': 'min',
      'value': 0,
      'message': 'Must be positive',
    },
    // Maximum value (for numbers)
    {
      'type': 'max',
      'value': 100,
      'message': 'Must be less than 100',
    },
    // Pattern matching (regex)
    {
      'type': 'pattern',
      'pattern': r'^[A-Z][a-z]+$',
      'message': 'Must start with uppercase letter',
    },
  ],
}
```

#### Required Fields

```dart
{
  'id': 'email',
  'label': 'Email *',
  'type': 'email',
  'required': true,  // Field is required
}
```

### React Native-style API

The controller provides methods similar to React Native form:

```dart
final controller = FromDataController();

// Append values to fields (auto-creates lists)
controller.append('tags', 'flutter');
controller.append('tags', 'dart');  
// Result: tags = ['flutter', 'dart']

// Get values
final tags = controller.get('tags');          // Get single field
final allData = controller.getAll();          // Get all fields

// Set values
controller.set('name', 'John');
controller.set('age', 30);

// Check existence
if (controller.has('name')) {
  print('Name exists: ${controller.get('name')}');
}

// Delete field
controller.delete('age');

// Clear fields
controller.clear(fieldIds: ['tags']);  // Clear specific fields
controller.clear();                     // Clear all fields
```

### Working with Any Data Type

#### Dropdown with Object Values

```dart
final schema = FormSchema.fromJson({
  'fields': [
    {
      'id': 'country',
      'label': 'Country',
      'type': 'dropdown',
      'options': [
        {
          'value': {'code': 'us', 'name': 'United States'},  // Object value
          'label': 'United States',
        },
        {
          'value': {'code': 'uk', 'name': 'United Kingdom'},
          'label': 'United Kingdom',
        },
      ],
    },
  ],
});

// Get selected value (entire object)
final country = controller.get('country');
print(country);  // {'code': 'us', 'name': 'United States'}
```

#### Dropdown with Integer Values

```dart
{
  'id': 'planId',
  'label': 'Plan ID',
  'type': 'dropdown',
  'options': [
    {'value': 1, 'label': 'Basic'},      // Integer value
    {'value': 2, 'label': 'Premium'},
    {'value': 3, 'label': 'Enterprise'},
  ],
}
```

#### Setting Values from Objects

```dart
final user = {
  'firstName': 'John',
  'lastName': 'Doe',
  'age': 30,
  'address': {'street': '123 Main St', 'city': 'NYC'},
};

// Extract and map values
controller.setValuesFromObject(user, {
  'name': (obj) => '${obj['firstName']} ${obj['lastName']}',
  'age': (obj) => obj['age'],
  'address': (obj) => obj['address'],  // Store entire object
});

// Get typed values
final address = controller.getAs<Map>('address');
final age = controller.getAs<int>('age');
```

#### Creating Options from Objects

```dart
final users = [
  {'id': 1, 'name': 'John'},
  {'id': 2, 'name': 'Jane'},
  {'id': 3, 'name': 'Bob'},
];

// Convert to FormFieldOptions
final options = users.map((user) => FormFieldOption.fromObject(
  value: user,              // Store entire object
  labelKey: 'name',         // Use 'name' as label
)).toList();
```

### Pre-populating Form Values

```dart
final initialValues = {
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
  'plan': 'premium',
};

FromDataForm(
  schema: schema,
  initialValues: initialValues,  // Pre-fill form
  onChanged: (values) {
    print('Current values: $values');
  },
)
```

### Form Submission

```dart
class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FromDataFormState>();

  void _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    // Validate form
    if (formState.validate()) {
      final values = formState.values;
      
      // Submit to API
      try {
        final response = await http.post(
          Uri.parse('/api/submit'),
          body: jsonEncode(values),
        );
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Form submitted successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FromDataForm(
        key: _formKey,
        schema: schema,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _handleSubmit,
          child: const Text('Submit'),
        ),
      ),
    );
  }
}
```

### Custom Field Builders

Override rendering for specific field types:

```dart
FromDataForm(
  schema: schema,
  customBuilders: {
    FormFieldType.text: (context, fieldContext) {
      // Custom text field widget
      return TextFormField(
        initialValue: fieldContext.value?.toString(),
        decoration: InputDecoration(
          labelText: fieldContext.schema.label,
          prefixIcon: const Icon(Icons.person),
        ),
        onChanged: fieldContext.onChanged,
      );
    },
  },
)
```

### Custom Layout Builder

Customize field layout:

```dart
FromDataForm(
  schema: schema,
  fieldLayoutBuilder: (context, schema, child) {
    // Wrap each field with custom layout
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  },
)
```

### Read-only Mode

Display form in view-only mode:

```dart
FromDataForm(
  schema: schema,
  readOnly: true,  // All fields become read-only
  initialValues: existingData,
)
```

## Advanced Examples

See the complete example app in `example/lib/main.dart` for:
- Comprehensive form with all field types
- Date/Time picker demos
- React Native-style API interactive demo
- Universal data type support examples

Run the example:

```bash
cd example
flutter run
```

## API Reference

### FormSchema

Main schema class for defining form structure.

```dart
FormSchema({
  required List<FormFieldSchema> fields,
  String? title,
  String? description,
  Map<String, dynamic> metadata = const {},
})

// From JSON
FormSchema.fromJson(Map<String, dynamic> json)
FormSchema.fromJsonString(String jsonString)
```

### FormFieldSchema

Defines a single form field.

```dart
FormFieldSchema({
  required String id,
  required String label,
  required FormFieldType type,
  String? hint,
  String? description,
  bool required = false,
  List<FormFieldOption> options = const [],
  List<ValidationRule> validations = const [],
  bool readOnly = false,
  String? placeholder,
  Map<String, dynamic> metadata = const {},
  dynamic initialValue,
})
```

### FromDataController

Manages form state and values.

```dart
FromDataController({
  FormSchema? schema,
  Map<String, dynamic>? values,
})

// Methods
dynamic get(String fieldId)
Map<String, dynamic> getAll()
void set(String fieldId, dynamic value)
void append(String fieldId, dynamic value)
void delete(String fieldId)
bool has(String fieldId)
void clear({List<String>? fieldIds})
T? getAs<T>(String fieldId)
void setValuesFromList<T>(List<T> items, Map<String, dynamic> Function(T, int) mapper)
void setValuesFromObject<T>(T object, Map<String, dynamic Function(T)> fieldMap)
```

### FromDataForm

Widget that renders the form.

```dart
FromDataForm({
  required FormSchema schema,
  FromDataController? controller,
  Map<String, dynamic>? initialValues,
  ValueChanged<Map<String, dynamic>>? onChanged,
  FieldLayoutBuilder? fieldLayoutBuilder,
  Map<FormFieldType, FromDataCustomBuilder>? customBuilders,
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  bool scrollable = true,
  EdgeInsetsGeometry? padding,
  bool readOnly = false,
})
```

## Additional Information

We welcome contributions and ideas! Feel free to open an issue or pull request.

- **Example app**: `example/lib/main.dart`
- **Report issues**: Open a GitHub issue in this repository
- **License**: See `LICENSE`
