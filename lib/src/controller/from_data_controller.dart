import 'package:flutter/foundation.dart';

import '../models/form_schema.dart';

class FromDataController extends ChangeNotifier {
  FromDataController({FormSchema? schema, Map<String, dynamic>? values})
    : _schema = schema,
      _values = Map<String, dynamic>.from(values ?? {}) {
    _hydrateDefaults();
  }

  final FormSchema? _schema;
  final Map<String, dynamic> _values;

  FormSchema? get schema => _schema;

  Map<String, dynamic> get values => Map<String, dynamic>.unmodifiable(_values);

  dynamic valueOf(String fieldId) => _values[fieldId];

  void setValue(String fieldId, dynamic value, {bool notify = true}) {
    if (_values[fieldId] == value) {
      return;
    }
    _values[fieldId] = value;
    if (notify) {
      notifyListeners();
    }
  }

  void patchValues(Map<String, dynamic> values, {bool notify = true}) {
    var didChange = false;
    values.forEach((key, value) {
      if (_values[key] != value) {
        _values[key] = value;
        didChange = true;
      }
    });

    if (didChange && notify) {
      notifyListeners();
    }
  }

  void reset({Map<String, dynamic>? values}) {
    _values
      ..clear()
      ..addAll(values ?? const {});
    _hydrateDefaults();
    notifyListeners();
  }

  String? validateField(String fieldId) {
    final schemaField = _schema?.fieldById(fieldId);
    if (schemaField == null) {
      return null;
    }
    return schemaField.validate(_values[fieldId]);
  }

  Map<String, String?> validateAll() {
    final schema = _schema;
    if (schema == null) {
      return const {};
    }
    final result = <String, String?>{};
    for (final field in schema.fields) {
      result[field.id] = field.validate(_values[field.id]);
    }
    return result;
  }

  void _hydrateDefaults() {
    final schema = _schema;
    if (schema == null) {
      return;
    }

    for (final field in schema.fields) {
      if (_values.containsKey(field.id)) {
        continue;
      }
      if (field.initialValue != null) {
        _values[field.id] = field.initialValue;
        continue;
      }
      if (field.type == FormFieldType.checkbox ||
          field.type == FormFieldType.switcher) {
        _values[field.id] = false;
        continue;
      }
      if (field.type == FormFieldType.dropdown) {
        final defaultOption = field.options.firstWhere(
          (option) => option.isDefault == true,
          orElse:
              () =>
                  field.options.isEmpty
                      ? const FormFieldOption(value: '', label: '')
                      : field.options.first,
        );
        if (defaultOption.value.isNotEmpty) {
          _values[field.id] = defaultOption.value;
        }
      }
    }
  }
}
