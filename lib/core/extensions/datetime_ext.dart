import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get formatted => DateFormat('MMM d, yyyy').format(this);
  String get shortFormatted => DateFormat('dd/MM/yyyy').format(this);
  String get timeFormatted => DateFormat('MMM d, yyyy • h:mm a').format(this);
  String get monthYear => DateFormat('MMMM yyyy').format(this);

  /// Returns "Today", "Yesterday", or a formatted date
  String get relative {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(year, month, day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return formatted;
  }
}
