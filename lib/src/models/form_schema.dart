import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Types of form fields supported by the library.
enum FormFieldType {
  /// Single-line text input field.
  text,

  /// Numeric input field.
  number,

  /// Email input field with email keyboard.
  email,

  /// Password input field with obscured text.
  password,

  /// Multi-line text input field.
  multiline,

  /// Dropdown selection field.
  dropdown,

  /// Checkbox field.
  checkbox,

  /// Switch/toggle field.
  switcher,

  /// Date picker field.
  date,

  /// Time picker field.
  time,

  /// Date and time picker field.
  datetime,
}

FormFieldType formFieldTypeFromString(String raw) {
  final value = raw.toLowerCase().trim();
  switch (value) {
    case 'text':
      return FormFieldType.text;
    case 'number':
      return FormFieldType.number;
    case 'email':
      return FormFieldType.email;
    case 'password':
      return FormFieldType.password;
    case 'multiline':
      return FormFieldType.multiline;
    case 'dropdown':
      return FormFieldType.dropdown;
    case 'checkbox':
      return FormFieldType.checkbox;
    case 'switch':
    case 'switcher':
      return FormFieldType.switcher;
    case 'date':
      return FormFieldType.date;
    case 'time':
      return FormFieldType.time;
    case 'datetime':
    case 'date-time':
      return FormFieldType.datetime;
    default:
      throw ArgumentError.value(raw, 'raw', 'Unsupported field type');
  }
}

enum ValidationType { minLength, maxLength, min, max, pattern, async }

ValidationType validationTypeFromString(String raw) {
  final value = raw.toLowerCase().trim();
  switch (value) {
    case 'minlength':
    case 'min_length':
    case 'min-length':
      return ValidationType.minLength;
    case 'maxlength':
    case 'max_length':
    case 'max-length':
      return ValidationType.maxLength;
    case 'min':
      return ValidationType.min;
    case 'max':
      return ValidationType.max;
    case 'pattern':
      return ValidationType.pattern;
    case 'async':
      return ValidationType.async;
    default:
      throw ArgumentError.value(raw, 'raw', 'Unsupported validation rule');
  }
}

/// Callback function for async validation.
///
/// Returns a Future that resolves to an error message (String) if validation
/// fails, or null if validation passes.
typedef AsyncValidator = Future<String?> Function(dynamic value);

/// A validation rule for form fields.
///
/// Defines validation constraints such as min/max length, min/max value,
/// pattern matching, or async validation. Each rule has a [type] and optional
/// parameters based on the type, along with an optional custom error [message].
@immutable
class ValidationRule {
  /// Creates a new [ValidationRule].
  ///
  /// The [type] determines what kind of validation is performed.
  /// For [ValidationType.minLength] and [ValidationType.maxLength], use [limit].
  /// For [ValidationType.min] and [ValidationType.max], use [limit] (num).
  /// For [ValidationType.pattern], use [pattern] (String).
  /// For [ValidationType.async], use [asyncValidator] (AsyncValidator).
  const ValidationRule({
    required this.type,
    this.limit,
    this.pattern,
    this.message,
    this.asyncValidator,
  });

  factory ValidationRule.fromJson(Map<String, dynamic> json) {
    final type = validationTypeFromString(json['type'] as String);
    final message = json['message'] as String?;

    switch (type) {
      case ValidationType.minLength:
      case ValidationType.maxLength:
        final limit = json['value'] ?? json['limit'];
        if (limit == null) {
          throw ArgumentError.value(
            json,
            'json',
            'Validation rule $type requires a numeric limit',
          );
        }
        return ValidationRule(
          type: type,
          limit: (limit as num).toInt(),
          message: message,
        );
      case ValidationType.min:
      case ValidationType.max:
        final limit = json['value'] ?? json['limit'];
        if (limit == null) {
          throw ArgumentError.value(
            json,
            'json',
            'Validation rule $type requires a numeric limit',
          );
        }
        return ValidationRule(
          type: type,
          limit: limit as num,
          message: message,
        );
      case ValidationType.pattern:
        final rawPattern = json['pattern'] ?? json['value'];
        if (rawPattern == null) {
          throw ArgumentError.value(
            json,
            'json',
            'Validation rule $type requires a pattern',
          );
        }
        return ValidationRule(
          type: type,
          pattern: rawPattern as String,
          message: message,
        );
      case ValidationType.async:
        // Async validation requires an asyncValidator callback, which cannot
        // be created from JSON. This must be added programmatically.
        return ValidationRule(type: type, message: message);
    }
  }

  final ValidationType type;
  final num? limit;
  final String? pattern;
  final String? message;
  final AsyncValidator? asyncValidator;

  Map<String, dynamic> toJson() => switch (type) {
    ValidationType.minLength || ValidationType.maxLength => {
      'type': type.name,
      'value': limit,
      'message': message,
    },
    ValidationType.min || ValidationType.max => {
      'type': type.name,
      'value': limit,
      'message': message,
    },
    ValidationType.pattern => {
      'type': type.name,
      'pattern': pattern,
      'message': message,
    },
    ValidationType.async => {'type': type.name, 'message': message},
  };

  String? validate(FormFieldSchema field, dynamic value) {
    if (value == null) {
      return null;
    }

    switch (type) {
      case ValidationType.minLength:
        final stringValue = value.toString();
        if (stringValue.length < (limit ?? 0).toInt()) {
          return message ??
              'Trường "${field.label}" tối thiểu ${(limit ?? 0).toInt()} ký tự.';
        }
        break;
      case ValidationType.maxLength:
        final stringValue = value.toString();
        if (stringValue.length > (limit ?? 0).toInt()) {
          return message ??
              'Trường "${field.label}" tối đa ${(limit ?? 0).toInt()} ký tự.';
        }
        break;
      case ValidationType.min:
        final numericValue = _asNum(value);
        if (numericValue != null && numericValue < (limit ?? 0)) {
          return message ??
              'Trường "${field.label}" phải lớn hơn hoặc bằng ${limit ?? 0}.';
        }
        break;
      case ValidationType.max:
        final numericValue = _asNum(value);
        if (numericValue != null && numericValue > (limit ?? 0)) {
          return message ??
              'Trường "${field.label}" phải nhỏ hơn hoặc bằng ${limit ?? 0}.';
        }
        break;
      case ValidationType.pattern:
        final stringValue = value.toString();
        if (pattern != null && !RegExp(pattern!).hasMatch(stringValue)) {
          return message ??
              'Trường "${field.label}" không đúng định dạng yêu cầu.';
        }
        break;
      case ValidationType.async:
        // Async validation is handled separately if asyncValidator is provided
        // This sync validate method skips async validation
        break;
    }

    return null;
  }
}

num? _asNum(dynamic value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

/// Represents an option for a dropdown form field.
///
/// Each option has a [value] (the actual value stored, can be any type),
/// a [label] (displayed text), an optional default flag, and optional metadata.
///
/// Example:
/// ```dart
/// FormFieldOption(
///   value: 'option1',  // Can be String, int, Map, List, or any type
///   label: 'Option 1',
///   isDefault: true,
/// )
/// ```
@immutable
class FormFieldOption {
  /// Creates a new [FormFieldOption].
  ///
  /// The [value] can be any type (String, int, double, Map, List, Object, etc.)
  /// and [label] is required. [isDefault] indicates if this option should be
  /// selected by default, and [metadata] can contain additional custom data.
  const FormFieldOption({
    required this.value,
    required this.label,
    this.isDefault = false,
    this.metadata = const <String, dynamic>{},
  });

  /// Creates a [FormFieldOption] from a JSON map.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "value": "option1",  // or any other type: number, object, array, etc.
  ///   "label": "Option 1",
  ///   "default": false,
  ///   "metadata": {}
  /// }
  /// ```
  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      value: json['value'], // Preserve original type
      label: json['label']?.toString() ?? json['value']?.toString() ?? '',
      isDefault: json['default'] == true,
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  /// Creates a [FormFieldOption] from any object with label extraction.
  ///
  /// Useful when you have a list of objects and want to convert them to options.
  /// ```dart
  /// final users = [
  ///   {'id': 1, 'name': 'John'},
  ///   {'id': 2, 'name': 'Jane'},
  /// ];
  /// final options = users.map((user) => FormFieldOption.fromObject(
  ///   value: user,
  ///   labelKey: 'name',
  /// )).toList();
  /// ```
  factory FormFieldOption.fromObject({
    required dynamic value,
    String? labelKey,
    String? labelValue,
    bool isDefault = false,
    Map<String, dynamic> metadata = const {},
  }) {
    String label;
    if (labelValue != null) {
      label = labelValue;
    } else if (labelKey != null && value is Map) {
      label = value[labelKey]?.toString() ?? value.toString();
    } else {
      label = value.toString();
    }
    return FormFieldOption(
      value: value,
      label: label,
      isDefault: isDefault,
      metadata: metadata,
    );
  }

  /// The value of this option. Can be any type (String, int, Map, List, etc.).
  final dynamic value;

  /// The displayed label for this option.
  final String label;

  /// Whether this option should be selected by default.
  final bool isDefault;

  /// Additional metadata for this option.
  final Map<String, dynamic> metadata;

  /// Gets the value as a String, converting if necessary.
  String get valueAsString => value?.toString() ?? '';

  /// Compares the option value with another value, handling any type.
  bool valueEquals(dynamic other) {
    if (value == other) return true;
    // Try string comparison as fallback
    return value?.toString() == other?.toString();
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'default': isDefault,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

/// Schema definition for a single form field.
///
/// Contains all the configuration needed to render and validate a form field,
/// including its type, label, validation rules, options (for dropdowns),
/// and initial value.
@immutable
class FormFieldSchema {
  /// Creates a new [FormFieldSchema].
  ///
  /// The [id] must be unique within a form. [label] is displayed to the user.
  /// [type] determines the field's input type. [options] are required for
  /// dropdown fields. [validations] define validation rules. [initialValue]
  /// sets the default value.
  const FormFieldSchema({
    required this.id,
    required this.label,
    required this.type,
    this.hint,
    this.description,
    this.required = false,
    this.options = const <FormFieldOption>[],
    this.validations = const <ValidationRule>[],
    this.readOnly = false,
    this.placeholder,
    this.metadata = const <String, dynamic>{},
    this.initialValue,
  });

  factory FormFieldSchema.fromJson(Map<String, dynamic> json) {
    final type = formFieldTypeFromString(json['type'] as String);
    final options = switch (type) {
      FormFieldType.dropdown => (json['options'] as List? ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                FormFieldOption.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      _ => const <FormFieldOption>[],
    };

    final validations = (json['validations'] as List? ?? const [])
        .map(
          (dynamic item) =>
              ValidationRule.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);

    return FormFieldSchema(
      id: json['id'].toString(),
      label: json['label']?.toString() ?? json['id'].toString(),
      type: type,
      hint: json['hint']?.toString(),
      description: json['description']?.toString(),
      required: json['required'] == true,
      options: options,
      validations: validations,
      readOnly: json['readOnly'] == true,
      placeholder: json['placeholder']?.toString(),
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      initialValue: json['initialValue'],
    );
  }

  final String id;
  final String label;
  final FormFieldType type;
  final String? hint;
  final String? description;
  final bool required;
  final List<FormFieldOption> options;
  final List<ValidationRule> validations;
  final bool readOnly;
  final String? placeholder;
  final Map<String, dynamic> metadata;
  final dynamic initialValue;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'type': type.name,
    if (hint != null) 'hint': hint,
    if (description != null) 'description': description,
    if (placeholder != null) 'placeholder': placeholder,
    'required': required,
    'readOnly': readOnly,
    if (options.isNotEmpty)
      'options': options.map((option) => option.toJson()).toList(),
    if (validations.isNotEmpty)
      'validations': validations.map((rule) => rule.toJson()).toList(),
    if (metadata.isNotEmpty) 'metadata': metadata,
    if (initialValue != null) 'initialValue': initialValue,
  };

  String? validate(dynamic value) {
    if (required) {
      final isEmpty = _isEmptyValue(value);
      if (isEmpty) {
        return 'Vui lòng nhập "${label}".';
      }
    }

    for (final rule in validations) {
      final result = rule.validate(this, value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Checks if a value is empty, handling all types.
  static bool _isEmptyValue(dynamic value) {
    if (value == null) return true;

    if (value is String) {
      return value.trim().isEmpty;
    }

    if (value is Iterable) {
      return value.isEmpty;
    }

    if (value is Map) {
      return value.isEmpty;
    }

    // For numeric types, 0 is not considered empty
    // For boolean, false is not considered empty
    return false;
  }
}

/// Complete form schema containing multiple fields.
///
/// Represents a complete form configuration with a list of [FormFieldSchema]
/// objects, optional title and description, and metadata.
@immutable
class FormSchema {
  /// Creates a new [FormSchema].
  ///
  /// The [fields] list must contain at least one field. [title] and
  /// [description] are displayed at the top of the form if provided.
  const FormSchema({
    required this.fields,
    this.title,
    this.description,
    this.metadata = const <String, dynamic>{},
  });

  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List? ?? const <dynamic>[])
        .map(
          (dynamic item) =>
              FormFieldSchema.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);

    if (fields.isEmpty) {
      throw ArgumentError.value(
        json,
        'json',
        'Một schema hợp lệ phải có ít nhất một phần tử trong "fields".',
      );
    }

    return FormSchema(
      fields: fields,
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      metadata:
          (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  factory FormSchema.fromJsonString(String jsonString) =>
      FormSchema.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  final List<FormFieldSchema> fields;
  final String? title;
  final String? description;
  final Map<String, dynamic> metadata;

  FormFieldSchema? fieldById(String fieldId) {
    try {
      return fields.firstWhere((field) => field.id == fieldId);
    } on StateError {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    'fields': fields.map((field) => field.toJson()).toList(),
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}
