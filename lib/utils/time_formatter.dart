import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class for formatting time consistently across the app
class TimeFormatter {
  /// Formats a Timestamp to 12-hour format (e.g., "2:30 PM")
  static String formatTime12Hour(dynamic time) {
    if (time == null) return '--';
    if (time is Timestamp) {
      final dateTime = time.toDate();
      return _formatDateTime12Hour(dateTime);
    }
    return time.toString();
  }

  /// Formats a Timestamp to 12-hour format, showing "Add Time" if null
  static String formatTimeWithAddPrompt(dynamic time) {
    if (time == null) return 'Add Time';
    if (time is Timestamp) {
      final dateTime = time.toDate();
      return _formatDateTime12Hour(dateTime);
    }
    return time.toString();
  }

  /// Formats DateTime to 12-hour format (e.g., "2:30 PM")
  static String _formatDateTime12Hour(DateTime dateTime) {
    final hour12 = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }

  /// Formats a Timestamp to relative time (e.g., "2h ago", "Just now")
  static String formatRelativeTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
