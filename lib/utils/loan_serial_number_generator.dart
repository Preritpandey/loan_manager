import 'package:list/models/loan.dart';

class LoanSerialNumberGenerator {
  const LoanSerialNumberGenerator._();

  static String generate({
    required String customerName,
    required List<Loan> existingLoans,
  }) {
    final parts = customerName
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final first = parts.isEmpty ? 'us' : _lettersOnly(parts.first);
    final last = parts.length < 2 ? first : _lettersOnly(parts.last);
    final prefix = '${_take(first, 2)}-${_takeConsonants(last)}';
    final normalizedName = customerName.trim().toLowerCase();
    final customerLoans = existingLoans.where(
      (loan) => loan.name.trim().toLowerCase() == normalizedName,
    );
    final usedSerials = existingLoans.map((loan) => loan.serialNumber).toSet();
    var sequence = customerLoans.length + 1;
    var candidate = _format(prefix, sequence);
    while (usedSerials.contains(candidate)) {
      sequence++;
      candidate = _format(prefix, sequence);
    }
    return candidate;
  }

  static String _lettersOnly(String value) {
    final letters = value.replaceAll(RegExp(r'[^a-z]'), '');
    return letters.isEmpty ? 'us' : letters;
  }

  static String _take(String value, int count) {
    return value.length >= count
        ? value.substring(0, count)
        : value.padRight(count, 'x');
  }

  static String _takeConsonants(String value) {
    final consonants = value.replaceAll(RegExp(r'[aeiou]'), '');
    if (consonants.length >= 2) return consonants.substring(0, 2);
    return _take(value, 2);
  }

  static String _format(String prefix, int sequence) {
    return '$prefix${sequence.toString().padLeft(2, '0')}';
  }
}
