import 'package:nepali_utils/nepali_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

/// Utility class for working with Nepali (Bikram Sambat) dates
class NepaliDate {
  final int year;
  final int month;
  final int day;

  NepaliDate({required this.year, required this.month, required this.day});

  // --- FACTORY CONSTRUCTORS ---

  /// Create NepaliDate from Gregorian (AD) date
  factory NepaliDate.fromGregorian(DateTime gregorianDate) {
    final nepaliDate = gregorianDate.toNepaliDateTime();
    return NepaliDate(
      year: nepaliDate.year,
      month: nepaliDate.month,
      day: nepaliDate.day,
    );
  }

  /// Today's Nepali date
  /// Tries nepali_date_picker first (better timezone handling), then falls back to nepali_utils
  factory NepaliDate.today() {
    NepaliDate? calculatedDate;
    
    try {
      // Try nepali_date_picker's NepaliDateTime.now() first as it may handle timezones better
      final pickerNow = picker.NepaliDateTime.now();
      calculatedDate = NepaliDate(
        year: pickerNow.year,
        month: pickerNow.month,
        day: pickerNow.day,
      );
    } catch (e) {
      print('ERROR in picker.NepaliDateTime.now(): $e');
      // Fallback to nepali_utils with explicit local time handling
      try {
        // Get local DateTime and ensure it's in local timezone (not UTC)
        final localNow = DateTime.now().toLocal();
        // Create a date-only DateTime at noon local time to avoid timezone boundary issues
        final localDateAtNoon = DateTime(
          localNow.year,
          localNow.month,
          localNow.day,
          12, // noon
          0,
          0,
          0,
          0,
        );
        // Convert using fromDateTime which should respect the local timezone
        final nepaliDate = NepaliDateTime.fromDateTime(localDateAtNoon);
        calculatedDate = NepaliDate(
          year: nepaliDate.year,
          month: nepaliDate.month,
          day: nepaliDate.day,
        );
      } catch (e2) {
        print('ERROR in NepaliDateTime.fromDateTime fallback: $e2');
        // Final fallback: try NepaliDateTime.now() directly
        try {
          final nepaliNow = NepaliDateTime.now();
          calculatedDate = NepaliDate(
            year: nepaliNow.year,
            month: nepaliNow.month,
            day: nepaliNow.day,
          );
        } catch (e3) {
          print('ERROR in NepaliDateTime.now() final fallback: $e3');
          // Ultimate fallback to hardcoded date
          calculatedDate = NepaliDate(year: 2080, month: 7, day: 23);
        }
      }
    }
    
    return calculatedDate;
  }
  
  /// Subtract days from this NepaliDate
  /// Uses direct day subtraction to avoid timezone conversion issues
  NepaliDate subtractDays(int days) {
    if (days == 0) return this;
    if (days < 0) return addDays(-days);
    
    // For small day adjustments (like 1 day), directly manipulate the day field
    // This completely avoids timezone conversion issues
    if (days == 1 && day > 1) {
      // Simple case: just subtract 1 from day if it's not the first day
      return NepaliDate(year: year, month: month, day: day - 1);
    }
    
    // For larger adjustments or edge cases, use NepaliDateTime manipulation
    try {
      final nepaliDateTime = NepaliDateTime(year, month, day);
      final adjustedNepali = nepaliDateTime.subtract(Duration(days: days));
      return NepaliDate(
        year: adjustedNepali.year,
        month: adjustedNepali.month,
        day: adjustedNepali.day,
      );
    } catch (e) {
      // If direct manipulation fails, try going through Gregorian but use picker
      final gregorian = toGregorian();
      final adjustedGregorian = gregorian.subtract(Duration(days: days));
      try {
        final pickerDate = picker.NepaliDateTime.fromDateTime(adjustedGregorian);
        return NepaliDate(
          year: pickerDate.year,
          month: pickerDate.month,
          day: pickerDate.day,
        );
      } catch (e2) {
        return NepaliDate.fromGregorian(adjustedGregorian);
      }
    }
  }
  
  /// Add days to this NepaliDate
  /// Uses direct Nepali date manipulation to avoid timezone conversion issues
  NepaliDate addDays(int days) {
    if (days == 0) return this;
    if (days < 0) return subtractDays(-days);
    
    // Directly manipulate Nepali date to avoid timezone conversion issues
    try {
      final nepaliDateTime = NepaliDateTime(year, month, day);
      final adjustedNepali = nepaliDateTime.add(Duration(days: days));
      return NepaliDate(
        year: adjustedNepali.year,
        month: adjustedNepali.month,
        day: adjustedNepali.day,
      );
    } catch (e) {
      // Fallback to Gregorian conversion if direct manipulation fails
      final gregorian = toGregorian();
      final adjustedGregorian = gregorian.add(Duration(days: days));
      // Use picker's conversion which might be more accurate
      try {
        final pickerDate = picker.NepaliDateTime.fromDateTime(adjustedGregorian);
        return NepaliDate(
          year: pickerDate.year,
          month: pickerDate.month,
          day: pickerDate.day,
        );
      } catch (e2) {
        return NepaliDate.fromGregorian(adjustedGregorian);
      }
    }
  }

  // --- CONVERSIONS ---

  /// Convert NepaliDate to Gregorian (AD) DateTime (normalized to Y-M-D)
  DateTime toGregorian() {
    final nepaliDate = NepaliDateTime(year, month, day);
    return nepaliDate.toDateTime();
  }

  // --- UTILITIES & FORMATTERS ---

  String format() {
    final monthName = _getMonthName(month);
    return '$year $monthName $day';
  }

  String formatForDisplay() => format();

  String formatForStorage() => toGregorian().toIso8601String();

  @override
  String toString() => format();

  // --- PARSING ---

  static NepaliDate? parse(String dateString) {
    try {
      final parts = dateString.trim().split(' ');
      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final monthName = parts[1];
      final day = int.parse(parts[2]);
      final month = _getMonthNumber(monthName);

      if (month == null || !isValid(year, month, day)) return null;
      return NepaliDate(year: year, month: month, day: day);
    } catch (_) {
      return null;
    }
  }

  static NepaliDate? parseFromStorage(String dateString) {
    try {
      final gregorianDate = DateTime.parse(dateString);
      return NepaliDate.fromGregorian(gregorianDate);
    } catch (_) {
      return null;
    }
  }

  // --- MONTHS & VALIDATION ---

  static List<String> getMonthNames() => const [
    'Baisakh',
    'Jestha',
    'Asar',
    'Shrawan',
    'Bhadra',
    'Ashoj',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  static String _getMonthName(int month) {
    final names = getMonthNames();
    if (month >= 1 && month <= 12) return names[month - 1];
    return 'Unknown';
  }

  static int? _getMonthNumber(String monthName) {
    final names = getMonthNames();
    final index = names.indexWhere(
      (name) => name.toLowerCase() == monthName.toLowerCase(),
    );
    return index != -1 ? index + 1 : null;
  }

  static int? getMonthNumber(String monthName) => _getMonthNumber(monthName);

  static bool isValid(int year, int month, int day) {
    if (year < 1970 || year > 2200) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 32) return false;
    try {
      final date = NepaliDateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (_) {
      return false;
    }
  }

  // --- YEAR HELPERS ---

  static int getCurrentYear() => NepaliDate.today().year;

  static List<int> getYears() {
    final current = getCurrentYear();
    const past = 3;
    const future = 7;
    return List.generate(past + future + 1, (i) => current - past + i);
  }

  // --- DATE DIFFERENCE HELPERS ---

  static int daysBetween(NepaliDate start, NepaliDate end) {
    final gStart = start.toGregorian();
    final gEnd = end.toGregorian();
    return gEnd.difference(gStart).inDays;
  }

  /// Returns how many days from today (positive = future, negative = past)
  static int daysFromToday(NepaliDate nepaliDate) {
    final today = NepaliDate.today();
    return daysBetween(today, nepaliDate);
  }

  // --- OVERRIDES ---

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NepaliDate &&
          other.year == year &&
          other.month == month &&
          other.day == day);

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}
