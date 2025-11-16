import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:from_data/from_data.dart';

void main() {
  runApp(const FromDataExampleApp());
}

class FromDataExampleApp extends StatelessWidget {
  const FromDataExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'from_data Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainExampleScreen(),
    );
  }
}

class MainExampleScreen extends StatefulWidget {
  const MainExampleScreen({super.key});

  @override
  State<MainExampleScreen> createState() => _MainExampleScreenState();
}

class _MainExampleScreenState extends State<MainExampleScreen> {
  int _selectedIndex = 0;

  final List<ExampleTab> _tabs = [
    const ExampleTab(
      title: 'All Features',
      icon: Icons.apps,
      screen: ComprehensiveExample(),
    ),
    const ExampleTab(
      title: 'Date/Time Pickers',
      icon: Icons.calendar_today,
      screen: DateTimePickerExample(),
    ),
    const ExampleTab(
      title: 'React Native API',
      icon: Icons.code,
      screen: ReactNativeAPIExample(),
    ),
    const ExampleTab(
      title: 'Any Data Type',
      icon: Icons.storage,
      screen: AnyDataTypeExample(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('from_data Examples'), elevation: 0),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations:
                _tabs
                    .map(
                      (tab) => NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.title),
                      ),
                    )
                    .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _tabs[_selectedIndex].screen),
        ],
      ),
    );
  }
}

class ExampleTab {
  final String title;
  final IconData icon;
  final Widget screen;

  const ExampleTab({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

// Example 1: Comprehensive Example showing all features
class ComprehensiveExample extends StatefulWidget {
  const ComprehensiveExample({super.key});

  @override
  State<ComprehensiveExample> createState() => _ComprehensiveExampleState();
}

class _ComprehensiveExampleState extends State<ComprehensiveExample> {
  final _formKey = GlobalKey<FromDataFormState>();

  late final FormSchema _schema = FormSchema.fromJson({
    'title': 'Complete Registration Form',
    'description':
        'This form demonstrates all field types and features of from_data library.',
    'fields': [
      {
        'id': 'fullName',
        'label': 'Full Name *',
        'type': 'text',
        'required': true,
        'validations': [
          {
            'type': 'minLength',
            'value': 3,
            'message': 'Name must contain at least 3 characters.',
          },
        ],
      },
      {
        'id': 'email',
        'label': 'Email Address *',
        'type': 'email',
        'required': true,
        'validations': [
          {
            'type': 'pattern',
            'pattern': r'^[^@]+@[^@]+\.[^@]+$',
            'message': 'Please enter a valid email address.',
          },
        ],
      },
      {
        'id': 'password',
        'label': 'Password *',
        'type': 'password',
        'required': true,
        'validations': [
          {
            'type': 'minLength',
            'value': 8,
            'message': 'Password must be at least 8 characters.',
          },
        ],
      },
      {
        'id': 'birthDate',
        'label': 'Birth Date',
        'type': 'date',
        'hint': 'Select your birth date',
      },
      {
        'id': 'appointmentTime',
        'label': 'Appointment Time',
        'type': 'time',
        'hint': 'Select appointment time',
      },
      {
        'id': 'eventDateTime',
        'label': 'Event Date & Time',
        'type': 'datetime',
        'hint': 'Select event date and time',
      },
      {
        'id': 'age',
        'label': 'Age',
        'type': 'number',
        'validations': [
          {'type': 'min', 'value': 18, 'message': 'You must be at least 18.'},
          {
            'type': 'max',
            'value': 100,
            'message': 'Age must be less than 100.',
          },
        ],
      },
      {
        'id': 'country',
        'label': 'Country',
        'type': 'dropdown',
        'options': [
          {'value': 'us', 'label': 'United States'},
          {'value': 'uk', 'label': 'United Kingdom'},
          {'value': 'ca', 'label': 'Canada'},
          {'value': 'au', 'label': 'Australia'},
        ],
      },
      {
        'id': 'plan',
        'label': 'Subscription Plan',
        'type': 'dropdown',
        'options': [
          {'value': 'basic', 'label': 'Basic Plan', 'default': true},
          {'value': 'premium', 'label': 'Premium Plan'},
          {'value': 'enterprise', 'label': 'Enterprise Plan'},
        ],
      },
      {
        'id': 'bio',
        'label': 'Biography',
        'type': 'multiline',
        'hint': 'Tell us about yourself...',
        'description': 'Minimum 10 characters recommended',
        'validations': [
          {
            'type': 'minLength',
            'value': 10,
            'message': 'Biography should be at least 10 characters.',
          },
        ],
      },
      {
        'id': 'acceptTerms',
        'label': 'I agree to the terms and conditions *',
        'type': 'checkbox',
        'required': true,
      },
      {
        'id': 'newsletter',
        'label': 'Subscribe to newsletter',
        'type': 'switch',
        'initialValue': true,
      },
    ],
  });

  Map<String, dynamic> _formValues = const <String, dynamic>{};

  void _handleSubmit() {
    final state = _formKey.currentState;
    if (state == null) return;

    if (state.validate()) {
      final values = state.values;
      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Form Submitted Successfully!'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Form Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      const JsonEncoder.withIndent('  ').convert(values),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FromDataForm(
                key: _formKey,
                schema: _schema,
                onChanged: (values) {
                  setState(() {
                    _formValues = Map<String, dynamic>.from(values);
                  });
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _handleSubmit,
                        icon: const Icon(Icons.send),
                        label: const Text('Submit Form'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _formKey.currentState?.reset();
                        setState(() {
                          _formValues = const {};
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
                if (_formValues.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('Current Form Values'),
                    leading: const Icon(Icons.data_object),
                    initiallyExpanded: false,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          const JsonEncoder.withIndent(
                            '  ',
                          ).convert(_formValues),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Example 2: Date/Time/DateTime Pickers
class DateTimePickerExample extends StatefulWidget {
  const DateTimePickerExample({super.key});

  @override
  State<DateTimePickerExample> createState() => _DateTimePickerExampleState();
}

class _DateTimePickerExampleState extends State<DateTimePickerExample> {
  final _formKey = GlobalKey<FromDataFormState>();

  late final FormSchema _schema = FormSchema.fromJson({
    'title': 'Date & Time Pickers',
    'description': 'Demonstrates date, time, and datetime picker fields.',
    'fields': [
      {
        'id': 'birthDate',
        'label': 'Birth Date *',
        'type': 'date',
        'required': true,
        'hint': 'Select your birth date',
      },
      {
        'id': 'meetingTime',
        'label': 'Meeting Time',
        'type': 'time',
        'hint': 'Select meeting time',
      },
      {
        'id': 'eventDateTime',
        'label': 'Event Date & Time *',
        'type': 'datetime',
        'required': true,
        'hint': 'Select event date and time',
      },
      {
        'id': 'appointmentDate',
        'label': 'Appointment Date',
        'type': 'date',
        'hint': 'Select appointment date',
      },
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FromDataForm(
              key: _formKey,
              schema: _schema,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 24),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final values = _formKey.currentState!.values;
                    showDialog<void>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Selected Dates & Times'),
                            content: SingleChildScrollView(
                              child: Text(
                                const JsonEncoder.withIndent(
                                  '  ',
                                ).convert(values),
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Validate & Show Values'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example 3: React Native-style API
class ReactNativeAPIExample extends StatefulWidget {
  const ReactNativeAPIExample({super.key});

  @override
  State<ReactNativeAPIExample> createState() => _ReactNativeAPIExampleState();
}

class _ReactNativeAPIExampleState extends State<ReactNativeAPIExample> {
  late FromDataController _controller;
  Map<String, dynamic> _output = {};

  @override
  void initState() {
    super.initState();
    _controller = FromDataController();
    _updateOutput();
  }

  void _updateOutput() {
    setState(() {
      _output = {
        'values': _controller.getAll(),
        'has_name': _controller.has('name'),
        'has_age': _controller.has('age'),
        'has_tags': _controller.has('tags'),
        'exists_name': _controller.exists('name'),
        'exists_age': _controller.exists('age'),
      };
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'React Native-style API Demo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Demonstrates append(), get(), getAll(), set(), delete(), has(), and clear() methods.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.append('tags', 'flutter');
                    _updateOutput();
                    _showSnackBar('Appended "flutter" to tags');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Append "flutter" to tags'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.append('tags', 'dart');
                    _updateOutput();
                    _showSnackBar('Appended "dart" to tags');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Append "dart" to tags'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.set('name', 'John Doe');
                    _updateOutput();
                    _showSnackBar('Set name to "John Doe"');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Set name'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.set('age', 30);
                    _updateOutput();
                    _showSnackBar('Set age to 30');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Set age'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final name = _controller.get('name');
                    _showSnackBar('Name: $name');
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Get name'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final allData = _controller.getAll();
                    _showDialog('All Form Data', allData);
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Get all'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.delete('age');
                    _updateOutput();
                    _showSnackBar('Deleted age field');
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete age'),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.clear(fieldIds: ['tags']);
                    _updateOutput();
                    _showSnackBar('Cleared tags field');
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear tags'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _controller.clear();
                    _updateOutput();
                    _showSnackBar('Cleared all fields');
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear all'),
                  style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Output:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(_output),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDialog(String title, Map<String, dynamic> data) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Text(
                const JsonEncoder.withIndent('  ').convert(data),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

// Example 4: Any Data Type Support
class AnyDataTypeExample extends StatefulWidget {
  const AnyDataTypeExample({super.key});

  @override
  State<AnyDataTypeExample> createState() => _AnyDataTypeExampleState();
}

class _AnyDataTypeExampleState extends State<AnyDataTypeExample> {
  final _formKey = GlobalKey<FromDataFormState>();

  late final FormSchema _schema = _createSchema();

  FormSchema _createSchema() {
    // Create schema with dropdown options that have different data types
    final baseSchema = FormSchema.fromJson({
      'title': 'Universal Data Type Support',
      'description':
          'Demonstrates form fields accepting any data type (String, int, Map, List, Object, etc.)',
      'fields': [
        {'id': 'name', 'label': 'Name', 'type': 'text'},
        {
          'id': 'country',
          'label': 'Country (with Object values)',
          'type': 'dropdown',
          'options': [
            {
              'value': {'code': 'us', 'name': 'United States'},
              'label': 'United States',
            },
            {
              'value': {'code': 'uk', 'name': 'United Kingdom'},
              'label': 'United Kingdom',
            },
            {
              'value': {'code': 'ca', 'name': 'Canada'},
              'label': 'Canada',
            },
          ],
        },
        {
          'id': 'planId',
          'label': 'Plan ID (with Integer values)',
          'type': 'dropdown',
          'options': [
            {'value': 1, 'label': 'Basic Plan'},
            {'value': 2, 'label': 'Premium Plan'},
            {'value': 3, 'label': 'Enterprise Plan'},
          ],
        },
        {
          'id': 'tags',
          'label': 'Tags',
          'type': 'text',
          'hint': 'Tags will be stored as List',
        },
      ],
    });

    return baseSchema;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FromDataForm(
                    key: _formKey,
                    schema: _schema,
                    onChanged: (values) {
                      // Store tags as list
                      if (values.containsKey('tags') &&
                          values['tags'] is String &&
                          values['tags'].toString().isNotEmpty) {
                        final tagsString = values['tags'] as String;
                        final tagsList =
                            tagsString.split(',').map((e) => e.trim()).toList();
                        _formKey.currentState?.controller.setValue(
                          'tags',
                          tagsList,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Data Type Examples:',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDataTypeExample(
                            'String',
                            'name',
                            'John Doe',
                            'Text fields store String values',
                          ),
                          const SizedBox(height: 12),
                          _buildDataTypeExample(
                            'Object/Map',
                            'country',
                            "{'code': 'us', 'name': 'United States'}",
                            'Dropdown can store entire objects as values',
                          ),
                          const SizedBox(height: 12),
                          _buildDataTypeExample(
                            'Integer',
                            'planId',
                            '1, 2, or 3',
                            'Dropdown options can have numeric values',
                          ),
                          const SizedBox(height: 12),
                          _buildDataTypeExample(
                            'List',
                            'tags',
                            "['flutter', 'dart']",
                            'Enter comma-separated tags, stored as List',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final values = _formKey.currentState?.values ?? {};
                      showDialog<void>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Form Values with Types'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final entry in values.entries)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${entry.key}:',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Type: ${entry.value.runtimeType}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              'Value: ${entry.value}',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Show Values & Types'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeExample(
    String type,
    String fieldId,
    String exampleValue,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fieldId,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
        Text(
          'Example: $exampleValue',
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
