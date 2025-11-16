## 0.3.4

### New Features

- **Date/Time/DateTime pickers**: Added support for `date`, `time`, and `datetime` field types with native pickers
- **Universal data type support**: Form values and options now support any data type (String, int, double, bool, Map, List, Object, etc.)
- **React Native-style API**: Added convenient methods similar to React Native form:
  - `append()` - Append values to fields (auto-creates lists)
  - `get()` - Get field value (alias for valueOf)
  - `getAll()` - Get all form values (alias for values)
  - `set()` - Set field value (alias for setValue)
  - `delete()` - Delete a field
  - `has()` - Check if field exists with non-null value
  - `clear()` - Clear specific or all fields
- **Enhanced FormFieldOption**: 
  - Value can now be any type (not just String)
  - Added `FormFieldOption.fromObject()` factory for creating options from objects
  - Added `valueEquals()` method for smart value comparison
- **New controller methods**:
  - `valueOfAs<T>()` and `getAs<T>()` - Get typed values
  - `setValuesFromList()` - Set values from list of objects with mapping
  - `setValuesFromObject()` - Set values from object with field mapping
  - `setValues()` - Shorthand for patchValues
  - `exists()` - Check if field exists (regardless of value)
- **Improved validation**: Enhanced validation to handle all data types (String, List, Map, etc.)

### Improvements

- Better handling of empty values across all data types
- Improved dropdown field to work with any value type
- Enhanced documentation with examples for new features

## 0.1.0

- Initial release of `from_data` featuring dynamic schemas, controller, and form widget.
- Added showcase example app and basic test coverage.
