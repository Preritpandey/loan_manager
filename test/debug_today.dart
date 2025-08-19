import 'package:nepali_utils/nepali_utils.dart';

void main() {
  print('=== Debug Today\'s Date ===');

  final now = DateTime.now();
  print('Gregorian today: ${now.year}-${now.month}-${now.day}');

  final nepaliNow = NepaliDateTime.now();
  print(
    'Nepali today (nepali_utils): ${nepaliNow.year} ${_getMonthName(nepaliNow.month)} ${nepaliNow.day}',
  );

  // Check what nepali_utils thinks is the conversion for today
  final converted = NepaliDateTime.fromDateTime(now);
  print(
    'Converted from DateTime.now(): ${converted.year} ${_getMonthName(converted.month)} ${converted.day}',
  );

  // Check if there's a timezone issue by using UTC
  final utcNow = DateTime.now().toUtc();
  final utcConverted = NepaliDateTime.fromDateTime(utcNow);
  print(
    'UTC converted: ${utcConverted.year} ${_getMonthName(utcConverted.month)} ${utcConverted.day}',
  );

  // Check what date nepali_utils thinks corresponds to Bhadra 3, 2082
  try {
    final bhadra3 = NepaliDateTime(2082, 5, 3); // Bhadra is month 5
    final gregorian = bhadra3.toDateTime();
    print(
      'Bhadra 3, 2082 → Gregorian: ${gregorian.year}-${gregorian.month}-${gregorian.day}',
    );
  } catch (e) {
    print('Error creating Bhadra 3, 2082: $e');
  }

  // Check what date nepali_utils thinks corresponds to Bhadra 4, 2082
  try {
    final bhadra4 = NepaliDateTime(2082, 5, 4); // Bhadra is month 5
    final gregorian = bhadra4.toDateTime();
    print(
      'Bhadra 4, 2082 → Gregorian: ${gregorian.year}-${gregorian.month}-${gregorian.day}',
    );
  } catch (e) {
    print('Error creating Bhadra 4, 2082: $e');
  }
}

String _getMonthName(int month) {
  final names = [
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
  return names[month - 1];
}
