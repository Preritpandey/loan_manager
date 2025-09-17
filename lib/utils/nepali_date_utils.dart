import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

class NepaliDate {
  final int year;
  final int month;
  final int day;

  NepaliDate({required this.year, required this.month, required this.day});

  // Create from Gregorian (AD) date using nepali_date_picker's NepaliDateTime
  factory NepaliDate.fromGregorian(DateTime gregorianDate) {
    final ndt = picker.NepaliDateTime.fromDateTime(gregorianDate);
    return NepaliDate(year: ndt.year, month: ndt.month, day: ndt.day);
  }

  // Convert to Gregorian (AD) date using nepali_date_picker's NepaliDateTime
  DateTime toGregorian() {
    final ndt = picker.NepaliDateTime(year, month, day);
    final ad = ndt.toDateTime();
    // Normalize to Y-M-D (ignore time) to avoid timezone/dst off-by-one
    return DateTime(ad.year, ad.month, ad.day);
  }

  // Today's Nepali date (computed in Nepal Standard Time to avoid off-by-one issues)
  factory NepaliDate.today() {
    // Convert current UTC time to Nepal Standard Time (UTC+5:45) and strip time
    final nepalNow = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 45),
    );
    final nepalDateOnly = DateTime(nepalNow.year, nepalNow.month, nepalNow.day);
    final ndt = picker.NepaliDateTime.fromDateTime(nepalDateOnly);
    return NepaliDate(year: ndt.year, month: ndt.month, day: ndt.day);
  }

  String format() {
    final monthName = _getMonthName(month);
    return '$year $monthName $day';
  }

  static NepaliDate? parse(String dateString) {
    try {
      final parts = dateString.trim().split(' ');
      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final monthName = parts[1];
      final day = int.parse(parts[2]);

      final month = _getMonthNumber(monthName);
      if (month == null) return null;

      if (!isValid(year, month, day)) return null;
      return NepaliDate(year: year, month: month, day: day);
    } catch (_) {
      return null;
    }
  }

  static List<String> getMonthNames() {
    return const [
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
  }

  static int getCurrentYear() {
    // Derive from today's Nepali date in Nepal Standard Time
    return NepaliDate.today().year;
  }

  static List<int> getYears() {
    // Include previous 3 years and next 7 years (total 11),
    // so if current is 2082, list will include 2079, 2080, 2081 as well.
    final currentYear = getCurrentYear();
    const pastYears = 3;
    const futureYears = 7; // keep total count 11 like before
    return List.generate(
      pastYears + futureYears + 1,
      (index) => currentYear - pastYears + index,
    );
  }

  static int daysBetween(NepaliDate start, NepaliDate end) {
    final gregorianStart = start.toGregorian();
    final gregorianEnd = end.toGregorian();
    return gregorianEnd.difference(gregorianStart).inDays;
  }

  static int daysFromToday(NepaliDate nepaliDate) {
    final today = NepaliDate.today();
    return daysBetween(nepaliDate, today);
  }

  String formatForDisplay() {
    return format();
  }

  String formatForStorage() {
    return toGregorian().toIso8601String();
  }

  static NepaliDate? parseFromStorage(String dateString) {
    try {
      final gregorianDate = DateTime.parse(dateString);
      return NepaliDate.fromGregorian(gregorianDate);
    } catch (_) {
      return null;
    }
  }

  static String _getMonthName(int month) {
    final monthNames = getMonthNames();
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return 'Unknown';
  }

  static int? _getMonthNumber(String monthName) {
    final monthNames = getMonthNames();
    final index = monthNames.indexWhere(
      (name) => name.toLowerCase() == monthName.toLowerCase(),
    );
    return index != -1 ? index + 1 : null;
  }

  static bool isValid(int year, int month, int day) {
    // Quick range checks first
    if (year < 1970 || year > 2200) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 32) return false;

    try {
      picker.NepaliDateTime(year, month, day);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String toString() {
    return format();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NepaliDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;
}
