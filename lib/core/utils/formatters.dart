import 'package:intl/intl.dart';

final NumberFormat _peso = NumberFormat.currency(
  symbol: '₱',
  decimalDigits: 2,
);
final NumberFormat _quantity = NumberFormat.decimalPattern();
final DateFormat _dateTime = DateFormat('MMM d, yyyy • h:mm a');
final DateFormat _date = DateFormat('MMM d, yyyy');
final DateFormat _shortDate = DateFormat('MMM d');

/// Formats a numeric amount as Philippine pesos, e.g. `₱1,234.50`.
String formatPeso(num value) => _peso.format(value);

/// Formats a whole-number quantity with thousands separators.
String formatQuantity(int value) => _quantity.format(value);

/// Formats a date and time for tables and receipts.
String formatDateTime(DateTime value) => _dateTime.format(value.toLocal());

/// Formats a date only.
String formatDate(DateTime value) => _date.format(value.toLocal());

/// Formats a short month/day label, useful for chart axes.
String formatShortDate(DateTime value) => _shortDate.format(value.toLocal());

/// Parses a user-entered amount, returning null when it is invalid.
double? tryParseAmount(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Converts a nullable string to a trimmed value or null.
String? nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
