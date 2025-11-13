import 'dart:convert';

import 'package:flutter/foundation.dart';

enum FormFieldType {
  text,
  number,
  email,
  password,
  multiline,
  dropdown,
  checkbox,
  switcher,
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
    default:
      throw ArgumentError.value(raw, 'raw', 'Unsupported field type');
  }
}

enum ValidationType { minLength, maxLength, min, max, pattern }

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
    default:
      throw ArgumentError.value(raw, 'raw', 'Unsupported validation rule');
  }
}

@immutable
class ValidationRule {
  const ValidationRule({
    required this.type,
    this.limit,
    this.pattern,
    this.message,
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
    }
  }

  final ValidationType type;
  final num? limit;
  final String? pattern;
  final String? message;

  Map<String, dynamic> toJson() => switch (type) {
        ValidationType.minLength ||
        ValidationType.maxLength =>
          {'type': describeEnum(type), 'value': limit, 'message': message},
        ValidationType.min || ValidationType.max =>
          {'type': describeEnum(type), 'value': limit, 'message': message},
        ValidationType.pattern =>
          {'type': describeEnum(type), 'pattern': pattern, 'message': message},
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

@immutable
class FormFieldOption {
  const FormFieldOption({
    required this.value,
    required this.label,
    this.isDefault = false,
    this.metadata = const <String, dynamic>{},
  });

  factory FormFieldOption.fromJson(Map<String, dynamic> json) {
    return FormFieldOption(
      value: json['value'].toString(),
      label: json['label']?.toString() ?? json['value'].toString(),
      isDefault: json['default'] == true,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  final String value;
  final String label;
  final bool isDefault;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'default': isDefault,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class FormFieldSchema {
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
      FormFieldType.dropdown =>
        (json['options'] as List? ?? const <dynamic>[])
            .map((dynamic item) =>
                FormFieldOption.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
      _ => const <FormFieldOption>[],
    };

    final validations = (json['validations'] as List? ?? const [])
        .map((dynamic item) =>
            ValidationRule.fromJson(item as Map<String, dynamic>))
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
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ??
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
        'type': describeEnum(type),
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
      final isEmpty = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is Iterable && value.isEmpty);
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
}

@immutable
class FormSchema {
  const FormSchema({
    required this.fields,
    this.title,
    this.description,
    this.metadata = const <String, dynamic>{},
  });

  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List? ?? const <dynamic>[])
        .map((dynamic item) =>
            FormFieldSchema.fromJson(item as Map<String, dynamic>))
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
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ??
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

