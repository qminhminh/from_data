import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controller/from_data_controller.dart';
import '../models/form_schema.dart';

typedef FieldLayoutBuilder = Widget Function(
  BuildContext context,
  FormFieldSchema schema,
  Widget child,
);

typedef FromDataCustomBuilder = Widget Function(
  BuildContext context,
  FromDataCustomFieldContext field,
);

class FromDataCustomFieldContext {
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

class FromDataForm extends StatefulWidget {
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
          ..selection =
              TextSelection.collapsed(offset: textValue.length);
      } else if (controller == null) {
        _textControllers[field.id] = TextEditingController(text: textValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (widget.schema.title != null) {
      children.add(Text(
        widget.schema.title!,
        style: Theme.of(context).textTheme.titleLarge,
      ));
      children.add(const SizedBox(height: 8));
    }

    if (widget.schema.description != null) {
      children.add(Text(
        widget.schema.description!,
        style: Theme.of(context).textTheme.bodyMedium,
      ));
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

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: form,
    );
  }

  Widget _wrapField(
    BuildContext context,
    FormFieldSchema field,
    Widget child,
  ) {
    if (widget.fieldLayoutBuilder != null) {
      return widget.fieldLayoutBuilder!(context, field, child);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: child,
    );
  }

  Widget? _buildField(BuildContext context, FormFieldSchema field) {
    if (widget.customBuilders != null &&
        widget.customBuilders!.containsKey(field.type)) {
      return _buildCustomField(context, field, widget.customBuilders![field.type]!);
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
    final controller = _textControllers[field.id] ??
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
      validator: (value) => field.validate(value),
      onChanged: (value) => _controller.setValue(field.id, value),
    );
  }

  Widget _buildNumberField(BuildContext context, FormFieldSchema field) {
    final controller = _textControllers[field.id] ??
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
      validator: (value) => field.validate(_tryParseNum(value)),
      onChanged: (value) {
        final parsed = _tryParseNum(value);
        _controller.setValue(field.id, value.trim().isEmpty ? null : parsed ?? value);
      },
    );
  }

  Widget _buildDropdownField(BuildContext context, FormFieldSchema field) {
    final currentValue =
        (_controller.valueOf(field.id) ?? field.options.firstOrNull?.value)
            ?.toString();
    return DropdownButtonFormField<String>(
      value: field.options.any((option) => option.value == currentValue)
          ? currentValue
          : null,
      items: field.options
          .map(
            (option) => DropdownMenuItem<String>(
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
      onChanged: widget.readOnly || field.readOnly
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
              onChanged: widget.readOnly || field.readOnly
                  ? null
                  : (value) {
                      final resolvedValue = value ?? false;
                      state.didChange(resolvedValue);
                      _controller.setValue(field.id, resolvedValue);
                    },
              title: Text(field.label),
              subtitle: field.description != null
                  ? Text(field.description!)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: hasError
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
              onChanged: widget.readOnly || field.readOnly
                  ? null
                  : (value) {
                      state.didChange(value);
                      _controller.setValue(field.id, value);
                    },
              title: Text(field.label),
              subtitle: field.description != null
                  ? Text(field.description!)
                  : null,
              secondary: hasError
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

  bool _isTextField(FormFieldType type) {
    return switch (type) {
      FormFieldType.text ||
      FormFieldType.email ||
      FormFieldType.password ||
      FormFieldType.multiline ||
      FormFieldType.number =>
        true,
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

