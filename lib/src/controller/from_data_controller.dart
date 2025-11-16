import 'package:flutter/foundation.dart';

import '../models/form_schema.dart';

/// Controller for managing form state, values, and validation.
///
/// Provides methods to set and retrieve form field values, validate fields,
/// and notify listeners of changes. Supports any data type (String, int,
/// double, bool, Map, List, Object, etc.) and automatically hydrates default
/// values from the schema on initialization.
class FromDataController extends ChangeNotifier {
  FromDataController({FormSchema? schema, Map<String, dynamic>? values})
    : _schema = schema,
      _values = Map<String, dynamic>.from(values ?? {}) {
    _hydrateDefaults();
  }

  final FormSchema? _schema;
  final Map<String, dynamic> _values;

  FormSchema? get schema => _schema;

  /// Gets all form values as an unmodifiable map.
  ///
  /// Values can be of any type (String, int, double, bool, Map, List, etc.).
  /// Similar to React Native form's `form.getAll()` or `form.values`.
  Map<String, dynamic> get values => Map<String, dynamic>.unmodifiable(_values);

  /// Gets all form values (alias for [values]).
  ///
  /// Similar to React Native form's `form.getAll()`. Returns all field values.
  /// Example:
  /// ```dart
  /// final allValues = controller.getAll();
  /// print(allValues);  // {'name': 'John', 'age': 30, ...}
  /// ```
  Map<String, dynamic> getAll() => values;

  /// Gets the value of a specific field.
  ///
  /// Returns the value as-is (any type). Returns null if field doesn't exist.
  dynamic valueOf(String fieldId) => _values[fieldId];

  /// Gets the value of a field (alias for [valueOf]).
  ///
  /// Similar to React Native form's `form.get()`. Returns the value as-is.
  /// Example:
  /// ```dart
  /// final name = controller.get('name');
  /// final age = controller.get('age');
  /// ```
  dynamic get(String fieldId) => valueOf(fieldId);

  /// Gets the value of a field as a specific type.
  ///
  /// Example:
  /// ```dart
  /// final name = controller.valueOfAs<String>('name');
  /// final age = controller.valueOfAs<int>('age');
  /// final data = controller.valueOfAs<Map>('metadata');
  /// ```
  T? valueOfAs<T>(String fieldId) {
    final value = _values[fieldId];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Gets the value of a field as a specific type (alias for [valueOfAs]).
  ///
  /// Example:
  /// ```dart
  /// final name = controller.getAs<String>('name');
  /// final age = controller.getAs<int>('age');
  /// ```
  T? getAs<T>(String fieldId) => valueOfAs<T>(fieldId);

  /// Checks if a field exists and has a non-null value.
  ///
  /// Similar to React Native form's `form.has()`. Returns true if field exists
  /// and value is not null.
  /// Example:
  /// ```dart
  /// if (controller.has('name')) {
  ///   print('Name exists: ${controller.get('name')}');
  /// }
  /// ```
  bool has(String fieldId) =>
      _values.containsKey(fieldId) && _values[fieldId] != null;

  /// Checks if a field exists (regardless of value).
  ///
  /// Returns true if field exists, even if value is null.
  bool exists(String fieldId) => _values.containsKey(fieldId);

  /// Sets a single field value.
  ///
  /// [value] can be any type (String, int, double, bool, Map, List, Object, etc.).
  void setValue(String fieldId, dynamic value, {bool notify = true}) {
    if (_values[fieldId] == value) {
      return;
    }
    _values[fieldId] = value;
    if (notify) {
      notifyListeners();
    }
  }

  /// Sets a single field value (alias for [setValue]).
  ///
  /// Similar to React Native form's `form.set()`. Sets or updates a field value.
  /// Example:
  /// ```dart
  /// controller.set('name', 'John');
  /// controller.set('age', 30);
  /// ```
  void set(String fieldId, dynamic value, {bool notify = true}) {
    setValue(fieldId, value, notify: notify);
  }

  /// Appends a value to a field.
  ///
  /// Similar to React Native form's `form.append()`. If field doesn't exist,
  /// creates it. If field is a List, appends to the list. Otherwise, replaces the value.
  /// Example:
  /// ```dart
  /// controller.append('tags', 'flutter');  // Creates ['flutter'] or appends to existing list
  /// controller.append('name', 'John');     // Sets 'John' (field doesn't exist or not a list)
  /// ```
  void append(String fieldId, dynamic value, {bool notify = true}) {
    final existingValue = _values[fieldId];
    if (existingValue is List) {
      // Append to existing list
      final newList = List.from(existingValue)..add(value);
      _values[fieldId] = newList;
    } else if (existingValue == null) {
      // Field doesn't exist, create as list if value is not null
      _values[fieldId] = [value];
    } else {
      // Field exists but is not a list, replace the value
      _values[fieldId] = value;
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Deletes a field from the form.
  ///
  /// Similar to React Native form's `form.delete()`. Removes the field and its value.
  /// Example:
  /// ```dart
  /// controller.delete('name');
  /// if (!controller.has('name')) {
  ///   print('Name field deleted');
  /// }
  /// ```
  void delete(String fieldId, {bool notify = true}) {
    if (_values.containsKey(fieldId)) {
      _values.remove(fieldId);
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Clears all fields or specific fields.
  ///
  /// If [fieldIds] is provided, clears only those fields. Otherwise clears all fields.
  /// Example:
  /// ```dart
  /// controller.clear(['name', 'email']);  // Clear specific fields
  /// controller.clear();                    // Clear all fields
  /// ```
  void clear({List<String>? fieldIds, bool notify = true}) {
    if (fieldIds != null) {
      for (final fieldId in fieldIds) {
        _values.remove(fieldId);
      }
    } else {
      _values.clear();
    }
    if (notify) {
      notifyListeners();
    }
  }

  /// Updates multiple field values at once.
  ///
  /// Values can be any type. Only notifies listeners once if any value changes.
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

  /// Sets values from a list of objects using field mapping.
  ///
  /// Useful when you have a list of objects and want to extract specific fields.
  /// Example:
  /// ```dart
  /// final users = [
  ///   {'name': 'John', 'email': 'john@example.com'},
  ///   {'name': 'Jane', 'email': 'jane@example.com'},
  /// ];
  /// controller.setValuesFromList(users, (item, index) => {
  ///   return {
  ///     'name_$index': item['name'],
  ///     'email_$index': item['email'],
  ///   };
  /// });
  /// ```
  void setValuesFromList<T>(
    List<T> items,
    Map<String, dynamic> Function(T item, int index) mapper, {
    bool notify = true,
  }) {
    final newValues = <String, dynamic>{};
    for (var i = 0; i < items.length; i++) {
      newValues.addAll(mapper(items[i], i));
    }
    patchValues(newValues, notify: notify);
  }

  /// Sets values from an object using field mapping.
  ///
  /// Useful when you have an object and want to extract specific fields.
  /// Example:
  /// ```dart
  /// final user = {
  ///   'firstName': 'John',
  ///   'lastName': 'Doe',
  ///   'age': 30,
  ///   'address': {'street': '123 Main St', 'city': 'NYC'},
  /// };
  /// controller.setValuesFromObject(user, {
  ///   'name': (obj) => '${obj['firstName']} ${obj['lastName']}',
  ///   'age': (obj) => obj['age'],
  ///   'address': (obj) => obj['address'],
  /// });
  /// ```
  void setValuesFromObject<T>(
    T object,
    Map<String, dynamic Function(T object)> fieldMap, {
    bool notify = true,
  }) {
    final newValues = <String, dynamic>{};
    fieldMap.forEach((fieldId, extractor) {
      try {
        newValues[fieldId] = extractor(object);
      } catch (e) {
        // Skip fields that fail to extract
      }
    });
    patchValues(newValues, notify: notify);
  }

  /// Sets values directly from a map (shorthand for patchValues).
  ///
  /// Example:
  /// ```dart
  /// controller.setValues({
  ///   'name': 'John',
  ///   'age': 30,
  ///   'tags': ['developer', 'flutter'],
  ///   'metadata': {'key': 'value'},
  /// });
  /// ```
  void setValues(Map<String, dynamic> values, {bool notify = true}) {
    patchValues(values, notify: notify);
  }

  /// Resets the form with optional new values.
  ///
  /// Values can be any type. Clears all existing values before setting new ones.
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
                      ? const FormFieldOption(value: null, label: '')
                      : field.options.first,
        );
        if (defaultOption.value != null) {
          _values[field.id] = defaultOption.value;
        }
      }
    }
  }
}
