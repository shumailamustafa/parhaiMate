import 'package:intl/intl.dart';

/// Pure Dart date, time, and duration formatting utilities.
abstract final class DateTimeUtils {
  static String toDateKey(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return DateTime.now();
    }
    final year = int.tryParse(parts[0]) ?? 2026;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return DateTime(year, month, day);
  }

  static DateTime startOfDay(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final day = startOfDay(date);
    // Monday = 1 ... Sunday = 7
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime endOfWeekExclusive(DateTime date) {
    return startOfWeek(date).add(const Duration(days: 7));
  }

  static String formatMinutes(int totalMinutes) {
    if (totalMinutes <= 0) {
      return '0m';
    }
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  static String formatSecondsAsMinutesLabel(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0m';
    }
    final minutes = totalSeconds ~/ 60;
    if (minutes == 0) {
      return '<1m';
    }
    return formatMinutes(minutes);
  }

  static String formatTimerClock(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String formatClockTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM').format(dateTime.toLocal());
  }

  static String formatShortDate(DateTime dateTime) {
    return DateFormat('EEE, d MMM').format(dateTime.toLocal());
  }

  static String formatMonthYear(DateTime dateTime) {
    return DateFormat('MMMM yyyy').format(dateTime.toLocal());
  }

  static String greetingForHour(int hour) {
    if (hour < 12) {
      return 'Good Morning!';
    }
    if (hour < 17) {
      return 'Good Afternoon!';
    }
    return 'Good Evening!';
  }
}
