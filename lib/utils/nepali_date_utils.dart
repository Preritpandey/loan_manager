import 'package:nepali_utils/nepali_utils.dart';

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

  /// Today's Nepali date (using nepali_utils)
  factory NepaliDate.today() {
    try {
      final now = NepaliDateTime.now();
      return NepaliDate(
        year: now.year,
        month: now.month,
        day: now.day,
      );
    } catch (e) {
      print('ERROR in NepaliDate.today(): $e');
      print('Stack trace: ${StackTrace.current}');
      // Fallback to hardcoded date
      return NepaliDate(year: 2080, month: 7, day: 23);
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
