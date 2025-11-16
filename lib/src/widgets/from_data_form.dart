import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/from_data_controller.dart';
import '../models/form_schema.dart';

/// Builder function for customizing the layout of form fields.
///
/// This function is called for each form field to build a custom layout
/// wrapper around the field widget. It receives the [BuildContext], the
/// [FormFieldSchema] for the field, and the child widget to wrap.
///
/// Example:
/// ```dart
/// FieldLayoutBuilder(
///   (context, schema, child) {
///     return Padding(
///       padding: EdgeInsets.symmetric(vertical: 8),
///       child: child,
///     );
///   },
/// )
/// ```
typedef FieldLayoutBuilder =
    Widget Function(BuildContext context, FormFieldSchema schema, Widget child);

typedef FromDataCustomBuilder =
    Widget Function(BuildContext context, FromDataCustomFieldContext field);

/// Context provided to custom field builders.
///
/// Contains all the information and callbacks needed to build a custom
/// form field widget, including the field schema, current value, change
/// handler, read-only state, and the form controller.
class FromDataCustomFieldContext {
  /// Creates a new [FromDataCustomFieldContext].
  const FromDataCustomFieldContext({
    required this.schema,
    required this.value,
    required this.onChanged,
    required this.readOnly,
    required this.controller,
  });

  final FormFieldSchema schema;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;
  final FromDataController controller;
}

/// A widget that renders a form based on a [FormSchema].
///
/// Automatically generates form fields based on the schema, handles
/// validation, state management, and value changes. Supports custom
/// field builders and layout builders for extensibility.
///
/// Example:
/// ```dart
/// FromDataForm(
///   schema: schema,
///   onChanged: (values) => print(values),
///   autovalidateMode: AutovalidateMode.onUserInteraction,
/// )
/// ```
class FromDataForm extends StatefulWidget {
  /// Creates a new [FromDataForm].
  ///
  /// The [schema] is required and defines the form structure. Optionally
  /// provide a [controller] for external state management, [initialValues]
  /// to pre-populate the form, and [onChanged] callback for value changes.
  const FromDataForm({
    super.key,
    required this.schema,
    this.controller,
    this.initialValues,
    this.onChanged,
    this.fieldLayoutBuilder,
    this.customBuilders,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.scrollable = true,
    this.padding,
    this.readOnly = false,
  });

  final FormSchema schema;
  final FromDataController? controller;
  final Map<String, dynamic>? initialValues;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final FieldLayoutBuilder? fieldLayoutBuilder;
  final Map<FormFieldType, FromDataCustomBuilder>? customBuilders;
  final AutovalidateMode autovalidateMode;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final bool readOnly;

  static FromDataFormState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<FromDataFormState>();
  }

  static FromDataFormState of(BuildContext context) {
    final state = maybeOf(context);
    assert(state != null, 'Không tìm thấy FromDataForm trong cây widget.');
    return state!;
  }

  @override
  State<FromDataForm> createState() => FromDataFormState();
}

class FromDataFormState extends State<FromDataForm> {
  final _formKey = GlobalKey<FormState>();
  late FromDataController _controller;
  late bool _ownsController;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, List<FormFieldOption>> _dynamicOptions = {};
  final Map<String, bool> _loadingOptions = {};
  final Map<String, String?> _asyncValidationErrors = {};

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant FromDataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _disposeControllerIfNeeded();
      _setupController();
      return;
    }

    if (!identical(oldWidget.schema, widget.schema) && _ownsController) {
      final previousValues = _controller.values;
      _controller
        ..removeListener(_handleControllerChanged)
        ..dispose();
      _controller = FromDataController(
        schema: widget.schema,
        values: previousValues,
      );
      _controller.addListener(_handleControllerChanged);
      _syncTextControllers();
      setState(() {});
      return;
    }

    if (widget.initialValues != null &&
        !mapEquals(widget.initialValues, oldWidget.initialValues) &&
        _ownsController) {
      _controller.reset(values: widget.initialValues);
      _syncTextControllers();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposeControllerIfNeeded();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    super.dispose();
  }

  FromDataController get controller => _controller;

  Map<String, dynamic> get values => controller.values;

  bool validate() => _formKey.currentState?.validate() ?? false;

  void reset() {
    _formKey.currentState?.reset();
    if (_ownsController) {
      _controller.reset(values: widget.initialValues);
    }
    _syncTextControllers();
    setState(() {});
  }

  void _setupController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      _controller.addListener(_handleControllerChanged);
      if (_controller.schema == null && _ownsController == false) {
        final forwardedValues = _controller.values;
        _controller.removeListener(_handleControllerChanged);
        _controller = FromDataController(
          schema: widget.schema,
          values: forwardedValues,
        );
        _ownsController = true;
        _controller.addListener(_handleControllerChanged);
      }
    } else {
      _controller = FromDataController(
        schema: widget.schema,
        values: widget.initialValues,
      );
      _ownsController = true;
      _controller.addListener(_handleControllerChanged);
    }
    _syncTextControllers();
  }

  void _disposeControllerIfNeeded() {
    _controller.removeListener(_handleControllerChanged);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _handleControllerChanged() {
    widget.onChanged?.call(_controller.values);
    _syncTextControllers();
    if (mounted) {
      setState(() {});
    }
  }

  void _syncTextControllers() {
    for (final field in widget.schema.fields) {
      if (!_isTextField(field.type)) {
        continue;
      }
      final controller = _textControllers[field.id];
      final textValue = _controller.valueOf(field.id)?.toString() ?? '';
      if (controller != null && controller.text != textValue) {
        controller
          ..text = textValue
          ..selection = TextSelection.collapsed(offset: textValue.length);
      } else if (controller == null) {
        _textControllers[field.id] = TextEditingController(text: textValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.schema.title != null) {
      children.add(
        Text(
          widget.schema.title!,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
      children.add(const SizedBox(height: 8));
    }

    if (widget.schema.description != null) {
      children.add(
        Text(
          widget.schema.description!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    for (final field in widget.schema.fields) {
      final fieldWidget = _buildField(context, field);
      if (fieldWidget == null) {
        continue;
      }
      children.add(_wrapField(context, field, fieldWidget));
    }

    final form = Form(
      key: _formKey,
      autovalidateMode: widget.autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (widget.scrollable) {
      return SingleChildScrollView(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: form,
      );
    }

    return Padding(padding: widget.padding ?? EdgeInsets.zero, child: form);
  }

  Widget _wrapField(BuildContext context, FormFieldSchema field, Widget child) {
    if (widget.fieldLayoutBuilder != null) {
      return widget.fieldLayoutBuilder!(context, field, child);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }

  Widget? _buildField(BuildContext context, FormFieldSchema field) {
    if (widget.customBuilders != null &&
        widget.customBuilders!.containsKey(field.type)) {
      return _buildCustomField(
        context,
        field,
        widget.customBuilders![field.type]!,
      );
    }

    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
      case FormFieldType.password:
      case FormFieldType.multiline:
        return _buildTextField(context, field);
      case FormFieldType.number:
        return _buildNumberField(context, field);
      case FormFieldType.dropdown:
        return _buildDropdownField(context, field);
      case FormFieldType.checkbox:
        return _buildCheckboxField(context, field);
      case FormFieldType.switcher:
        return _buildSwitchField(context, field);
      case FormFieldType.date:
        return _buildDateField(context, field);
      case FormFieldType.time:
        return _buildTimeField(context, field);
      case FormFieldType.datetime:
        return _buildDateTimeField(context, field);
    }
  }

  Widget _buildCustomField(
    BuildContext context,
    FormFieldSchema field,
    FromDataCustomBuilder builder,
  ) {
    return FormField<dynamic>(
      initialValue: _controller.valueOf(field.id),
      validator: (value) => field.validate(value),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final customContext = FromDataCustomFieldContext(
          schema: field,
          value: state.value,
          readOnly: widget.readOnly || field.readOnly,
          controller: _controller,
          onChanged: (dynamic newValue) {
            state.didChange(newValue);
            _controller.setValue(field.id, newValue);
          },
        );
        final customWidget = builder(context, customContext);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customWidget,
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(BuildContext context, FormFieldSchema field) {
    final controller =
        _textControllers[field.id] ??
        TextEditingController(
          text: _controller.valueOf(field.id)?.toString() ?? '',
        );
    _textControllers[field.id] = controller;

    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly || field.readOnly,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint ?? field.placeholder,
        helperText: field.description,
      ),
      obscureText: field.type == FormFieldType.password,
      minLines: field.type == FormFieldType.multiline ? 3 : 1,
      maxLines: field.type == FormFieldType.multiline ? null : 1,
      keyboardType: _keyboardTypeFor(field.type),
      validator: (value) {
        final syncError = field.validate(value);
        if (syncError != null) {
          return syncError;
        }

        // Check for async validation errors (set separately)
        final asyncError = _asyncValidationErrors[field.id];
        if (asyncError != null) {
          return asyncError;
        }

        return null;
      },
      onChanged: (value) {
        _controller.setValue(field.id, value);
      },
    );
  }

  Widget _buildNumberField(BuildContext context, FormFieldSchema field) {
    final controller =
        _textControllers[field.id] ??
        TextEditingController(
          text: _controller.valueOf(field.id)?.toString() ?? '',
        );
    _textControllers[field.id] = controller;

    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly || field.readOnly,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint ?? field.placeholder,
        helperText: field.description,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final parsed = _tryParseNum(value);
        return field.validate(parsed);
      },
      onChanged: (value) {
        final parsed = _tryParseNum(value);
        _controller.setValue(
          field.id,
          value.trim().isEmpty ? null : parsed ?? value,
        );
      },
    );
  }

  Widget _buildDropdownField(BuildContext context, FormFieldSchema field) {
    final currentValue = _controller.valueOf(field.id);

    // Use dynamic options if available
    final options = _dynamicOptions[field.id] ?? field.options;
    final isLoading = _loadingOptions[field.id] ?? false;

    if (isLoading) {
      return DropdownButtonFormField<dynamic>(
        value: null,
        items: const [],
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.description ?? 'Đang tải...',
          suffixIcon: Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        onChanged: null,
      );
    }

    // Find matching option value
    dynamic selectedValue;
    try {
      final matchingOption = options.firstWhere(
        (option) => option.valueEquals(currentValue),
        orElse:
            () =>
                options.firstOrNull ??
                const FormFieldOption(value: null, label: ''),
      );
      selectedValue = matchingOption.value;
    } catch (e) {
      selectedValue = null;
    }

    return DropdownButtonFormField<dynamic>(
      value: selectedValue,
      items:
          options
              .map(
                (option) => DropdownMenuItem<dynamic>(
                  value: option.value,
                  child: Text(option.label),
                ),
              )
              .toList(),
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.description,
      ),
      validator: (value) => field.validate(value),
      onChanged:
          widget.readOnly || field.readOnly
              ? null
              : (value) {
                _controller.setValue(field.id, value);
              },
    );
  }

  Widget _buildCheckboxField(BuildContext context, FormFieldSchema field) {
    return FormField<bool>(
      initialValue: (_controller.valueOf(field.id) ?? false) as bool,
      validator: (value) => field.validate(value),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: state.value ?? false,
              onChanged:
                  widget.readOnly || field.readOnly
                      ? null
                      : (value) {
                        final resolvedValue = value ?? false;
                        state.didChange(resolvedValue);
                        _controller.setValue(field.id, resolvedValue);
                      },
              title: Text(field.label),
              subtitle:
                  field.description != null ? Text(field.description!) : null,
              controlAffinity: ListTileControlAffinity.leading,
              secondary:
                  hasError
                      ? Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 30,
                      )
                      : null,
              contentPadding: EdgeInsets.zero,
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  state.errorText ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSwitchField(BuildContext context, FormFieldSchema field) {
    return FormField<bool>(
      initialValue: (_controller.valueOf(field.id) ?? false) as bool,
      validator: (value) => field.validate(value),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: state.value ?? false,
              onChanged:
                  widget.readOnly || field.readOnly
                      ? null
                      : (value) {
                        state.didChange(value);
                        _controller.setValue(field.id, value);
                      },
              title: Text(field.label),
              subtitle:
                  field.description != null ? Text(field.description!) : null,
              secondary:
                  hasError
                      ? Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 30,
                      )
                      : null,
              contentPadding: EdgeInsets.zero,
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  state.errorText ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context, FormFieldSchema field) {
    final currentValue = _controller.valueOf(field.id);
    DateTime? selectedDate;
    if (currentValue is String) {
      selectedDate = DateTime.tryParse(currentValue);
    } else if (currentValue is DateTime) {
      selectedDate = currentValue;
    }

    return FormField<DateTime>(
      initialValue: selectedDate,
      validator: (value) => field.validate(value?.toIso8601String()),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap:
                  widget.readOnly || field.readOnly
                      ? null
                      : () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          state.didChange(date);
                          _controller.setValue(
                            field.id,
                            date.toIso8601String(),
                          );
                        }
                      },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: field.hint ?? field.placeholder ?? 'Chọn ngày',
                  helperText: field.description,
                  errorText: state.hasError ? state.errorText : null,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : field.hint ?? field.placeholder ?? 'Chọn ngày',
                  style:
                      selectedDate != null
                          ? null
                          : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeField(BuildContext context, FormFieldSchema field) {
    final currentValue = _controller.valueOf(field.id);
    TimeOfDay? selectedTime;
    if (currentValue is String) {
      final parts = currentValue.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    return FormField<TimeOfDay>(
      initialValue: selectedTime,
      validator:
          (value) => field.validate(
            value != null ? '${value.hour}:${value.minute}' : null,
          ),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap:
                  widget.readOnly || field.readOnly
                      ? null
                      : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          state.didChange(time);
                          _controller.setValue(
                            field.id,
                            '${time.hour}:${time.minute}',
                          );
                        }
                      },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: field.hint ?? field.placeholder ?? 'Chọn giờ',
                  helperText: field.description,
                  errorText: state.hasError ? state.errorText : null,
                  suffixIcon: const Icon(Icons.access_time),
                ),
                child: Text(
                  selectedTime != null
                      ? selectedTime!.format(context)
                      : field.hint ?? field.placeholder ?? 'Chọn giờ',
                  style:
                      selectedTime != null
                          ? null
                          : TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateTimeField(BuildContext context, FormFieldSchema field) {
    final currentValue = _controller.valueOf(field.id);
    DateTime? selectedDateTime;
    if (currentValue is String) {
      selectedDateTime = DateTime.tryParse(currentValue);
    } else if (currentValue is DateTime) {
      selectedDateTime = currentValue;
    }

    return FormField<DateTime>(
      initialValue: selectedDateTime,
      validator: (value) => field.validate(value?.toIso8601String()),
      autovalidateMode: widget.autovalidateMode,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap:
                        widget.readOnly || field.readOnly
                            ? null
                            : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDateTime ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime:
                                      selectedDateTime != null
                                          ? TimeOfDay(
                                            hour: selectedDateTime!.hour,
                                            minute: selectedDateTime!.minute,
                                          )
                                          : TimeOfDay.now(),
                                );
                                if (time != null) {
                                  final dateTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                  state.didChange(dateTime);
                                  _controller.setValue(
                                    field.id,
                                    dateTime.toIso8601String(),
                                  );
                                }
                              }
                            },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: field.label,
                        hintText:
                            field.hint ?? field.placeholder ?? 'Chọn ngày giờ',
                        helperText: field.description,
                        errorText: state.hasError ? state.errorText : null,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDateTime != null
                            ? '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}'
                            : field.hint ??
                                field.placeholder ??
                                'Chọn ngày giờ',
                        style:
                            selectedDateTime != null
                                ? null
                                : TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  bool _isTextField(FormFieldType type) {
    return switch (type) {
      FormFieldType.text ||
      FormFieldType.email ||
      FormFieldType.password ||
      FormFieldType.multiline ||
      FormFieldType.number => true,
      _ => false,
    };
  }

  TextInputType _keyboardTypeFor(FormFieldType type) {
    switch (type) {
      case FormFieldType.email:
        return TextInputType.emailAddress;
      case FormFieldType.number:
        return TextInputType.number;
      case FormFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  num? _tryParseNum(String? input) {
    if (input == null) {
      return null;
    }
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final intValue = int.tryParse(trimmed);
    if (intValue != null) {
      return intValue;
    }
    return double.tryParse(trimmed);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }
    return first;
  }
}
