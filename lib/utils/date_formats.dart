String _twoDigits(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime dateTime) {
  final day = _twoDigits(dateTime.day);
  final month = _twoDigits(dateTime.month);
  final year = dateTime.year.toString();
  final hour = _twoDigits(dateTime.hour);
  final minute = _twoDigits(dateTime.minute);
  return '$day.$month.$year $hour:$minute';
}

String formatDate(DateTime dateTime) {
  final day = _twoDigits(dateTime.day);
  final month = _twoDigits(dateTime.month);
  final year = dateTime.year.toString();
  return '$day.$month.$year';
}

/// Formats date for filename: ddMMyyyy (e.g., 03012025)
String formatDateForFilename(DateTime dateTime) {
  final day = _twoDigits(dateTime.day);
  final month = _twoDigits(dateTime.month);
  final year = dateTime.year.toString();
  return '$day$month$year';
}

