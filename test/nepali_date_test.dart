import 'package:flutter_test/flutter_test.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:nepali_utils/nepali_utils.dart';

void main() {
  group('NepaliDate Tests', () {
    test('should create today\'s Nepali date', () {
      final today = NepaliDate.today();
      expect(today, isNotNull);
      expect(today.year, greaterThan(2000));
      expect(today.month, greaterThan(0));
      expect(today.month, lessThanOrEqualTo(12));
      expect(today.day, greaterThan(0));
      expect(today.day, lessThanOrEqualTo(32));
    });

    test('should format Nepali date correctly', () {
      final date = NepaliDate(year: 2082, month: 4, day: 10);
      final formatted = date.format();
      expect(formatted, '2082 Shrawan 10');
    });

    test('should parse Nepali date string correctly', () {
      final parsed = NepaliDate.parse('2082 Shrawan 10');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2082);
      expect(parsed.month, 4);
      expect(parsed.day, 10);
    });

    test('should handle invalid Nepali date string', () {
      final parsed = NepaliDate.parse('invalid date');
      expect(parsed, isNull);
    });

    test(
      'should convert between Gregorian and Nepali dates (match nepali_utils)',
      () {
        final gregorianDate = DateTime(2025, 8, 19);
        final expectedBack = NepaliDateTime.fromDateTime(
          gregorianDate,
        ).toDateTime();

        final nepaliDate = NepaliDate.fromGregorian(gregorianDate);
        final convertedBack = nepaliDate.toGregorian();

        expect(convertedBack.year, expectedBack.year);
        expect(convertedBack.month, expectedBack.month);
        expect(convertedBack.day, expectedBack.day);
      },
    );

    test('should get month names', () {
      final monthNames = NepaliDate.getMonthNames();
      expect(monthNames.length, 12);
      expect(monthNames, contains('Baisakh'));
      expect(monthNames, contains('Shrawan'));
      expect(monthNames, contains('Chaitra'));
    });

    test('should validate Nepali dates', () {
      expect(NepaliDate.isValid(2082, 4, 10), isTrue);
      expect(NepaliDate.isValid(2082, 13, 10), isFalse); // Invalid month
      expect(NepaliDate.isValid(2082, 4, 35), isFalse); // Invalid day
      expect(
        NepaliDate.isValid(1900, 4, 10),
        isFalse,
      ); // Out of supported range
    });

    test('wrapper should match nepali_utils for a known date', () {
      final ad = DateTime(2025, 8, 19);
      final ndt = NepaliDateTime.fromDateTime(ad);
      final wrapped = NepaliDate.fromGregorian(ad);

      expect(wrapped.year, ndt.year);
      expect(wrapped.month, ndt.month);
      expect(wrapped.day, ndt.day);
    });

    test('roundtrip should match nepali_utils mapping', () {
      final ad = DateTime(2025, 8, 19);
      final wrapped = NepaliDate.fromGregorian(ad);
      final back = wrapped.toGregorian();
      final expectedBack = NepaliDateTime.fromDateTime(ad).toDateTime();

      expect(back.year, expectedBack.year);
      expect(back.month, expectedBack.month);
      expect(back.day, expectedBack.day);
    });
  });
}
