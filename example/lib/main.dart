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
      title: 'from_data demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DynamicFormDemo(),
    );
  }
}

class DynamicFormDemo extends StatefulWidget {
  const DynamicFormDemo({super.key});

  @override
  State<DynamicFormDemo> createState() => _DynamicFormDemoState();
}

class _DynamicFormDemoState extends State<DynamicFormDemo> {
  final _formKey = GlobalKey<FromDataFormState>();

  late final FormSchema _schema = FormSchema.fromJson({
    'title': 'Service Registration',
    'description':
        'Please provide your details below. Fields marked with * are required.',
    'fields': [
      {
        'id': 'fullName',
        'label': 'Full name *',
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
        'label': 'Email *',
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
        'id': 'age',
        'label': 'Age',
        'type': 'number',
        'validations': [
          {'type': 'min', 'value': 18, 'message': 'You must be at least 18.'},
        ],
      },
      {
        'id': 'plan',
        'label': 'Plan',
        'type': 'dropdown',
        'options': [
          {'value': 'basic', 'label': 'Basic', 'default': true},
          {'value': 'premium', 'label': 'Premium'},
          {'value': 'enterprise', 'label': 'Enterprise'},
        ],
      },
      {
        'id': 'notes',
        'label': 'Additional notes',
        'type': 'multiline',
        'hint': 'For example: specific requests or context',
      },
      {
        'id': 'accept',
        'label': 'I agree to the terms of use *',
        'type': 'checkbox',
        'required': true,
      },
      {
        'id': 'newsletter',
        'label': 'Subscribe to weekly newsletter',
        'type': 'switch',
        'initialValue': true,
      },
    ],
  });

  Map<String, dynamic> _livePreview = const <String, dynamic>{};
  Map<String, dynamic>? _submittedValues;

  void _handleSubmit() {
    final state = _formKey.currentState;
    if (state == null) {
      return;
    }
    if (state.validate()) {
      final values = state.values;
      setState(() => _submittedValues = Map<String, dynamic>.from(values));
      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Submission successful'),
              content: Text(const JsonEncoder.withIndent('  ').convert(values)),
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
          content: Text('Please double-check the required fields.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jsonEncoder = const JsonEncoder.withIndent('  ');
    return Scaffold(
      appBar: AppBar(title: const Text('from_data demo')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FromDataForm(
                key: _formKey,
                schema: _schema,
                onChanged:
                    (values) => setState(() {
                      _livePreview = Map<String, dynamic>.from(values);
                    }),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Current values',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    jsonEncoder.convert(_livePreview),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (_submittedValues != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Submitted result',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      jsonEncoder.convert(_submittedValues!),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.send, size: 30),
                    onPressed: _handleSubmit,
                    label: const Text('Submit form'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
