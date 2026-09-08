import 'package:list/models/loan.dart';

class LoanSerialNumberConfig {
  final String? customPrefix;
  final int padding;
  final bool autoSerialEnabled;

  const LoanSerialNumberConfig({
    this.customPrefix,
    this.padding = 2,
    this.autoSerialEnabled = true,
  });
}

class ParsedLoanSerial {
  final int number;
  final String prefix;
  final String separator;
  final String name;
  final bool valid;
  final SerialPattern pattern;

  const ParsedLoanSerial({
    required this.number,
    required this.prefix,
    required this.separator,
    required this.name,
    required this.valid,
    required this.pattern,
  });

  const ParsedLoanSerial.invalid()
      : number = 0,
        prefix = '',
        separator = '',
        name = '',
        valid = false,
        pattern = SerialPattern.invalid;
}

enum SerialPattern {
  invalid,
  numberOnly,
  numberSlashName,
  numberSpaceName,
  prefixNumberSpaceName,
  prefixNumberName,
  nameBasedPrefix,
  nameSlashNumber,
}

enum _SerialStrategy {
  numberOnly,
  numberSlashName,
  numberSpaceName,
  prefixNumberSpaceName,
  prefixNumberName,
  nameBasedPrefix,
}

class _ResolvedSerialStrategy {
  final _SerialStrategy type;
  final String prefix;
  final int padding;

  const _ResolvedSerialStrategy({
    required this.type,
    this.prefix = '',
    this.padding = 0,
  });
}

class LoanSerialNumberGenerator {
  const LoanSerialNumberGenerator._();

  static const defaultNewCustomerPadding = 2;

  static const Set<String> excludedCustomerNames = {
    'baaki',
    'examle',
  };

  static const Map<String, LoanSerialNumberConfig> customerConfigs = {
    'new pathivara sliver': LoanSerialNumberConfig(padding: 5),
    'new pathivara silver': LoanSerialNumberConfig(padding: 5),
    'new pathivara gold': LoanSerialNumberConfig(padding: 0),
    'baaki': LoanSerialNumberConfig(autoSerialEnabled: false),
    'examle': LoanSerialNumberConfig(autoSerialEnabled: false),
  };

  static final Map<String, _ResolvedSerialStrategy> _knownHistoricalStrategies = {
    _normalizeName('new kuwer jeweels'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.numberSlashName,
    ),
    _normalizeName('lijan jwellers'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.numberSlashName,
    ),
    _normalizeName('new pathivara sliver'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.prefixNumberSpaceName,
      prefix: 'PLS',
      padding: 5,
    ),
    _normalizeName('new pathivara silver'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.prefixNumberSpaceName,
      prefix: 'PLS',
      padding: 5,
    ),
    _normalizeName('new pathivara gold'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.prefixNumberSpaceName,
      prefix: 'pl',
      padding: 0,
    ),
    _normalizeName('khushi jwls'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.numberSlashName,
    ),
    _normalizeName('shiv durga jwls'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.numberSlashName,
    ),
    _normalizeName('chaudhary jewellers'): const _ResolvedSerialStrategy(
      type: _SerialStrategy.numberSpaceName,
    ),
  };

  static ParsedLoanSerial parseSerial(String serialNumber) {
    final serial = serialNumber.trim();
    if (serial.isEmpty) return const ParsedLoanSerial.invalid();
    if (RegExp(r'^0+$').hasMatch(serial)) return const ParsedLoanSerial.invalid();
    if (!RegExp(r'\d').hasMatch(serial)) return const ParsedLoanSerial.invalid();

    final nameBased = RegExp(r'^([A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)+)-0*(\d+)$')
        .firstMatch(serial);
    if (nameBased != null) {
      return _valid(
        number: int.parse(nameBased.group(2)!),
        prefix: nameBased.group(1)!.toUpperCase(),
        separator: '-',
        pattern: SerialPattern.nameBasedPrefix,
      );
    }

    final prefixNumber = RegExp(r'^([A-Za-z]{1,3})\s*0*(\d+)(?:(/|\s+|\.)\s*(.*))?$')
        .firstMatch(serial);
    if (prefixNumber != null) {
      final prefix = prefixNumber.group(1)!;
      final normalizedPrefix = prefix.toLowerCase();
      if (normalizedPrefix == 'pls' || normalizedPrefix == 'pl') {
        final rawSeparator = prefixNumber.group(3) ?? '';
        final tail = prefixNumber.group(4)?.trim() ?? '';
        return _valid(
          number: int.parse(prefixNumber.group(2)!),
          prefix: prefix,
          separator: rawSeparator.trim().isEmpty && tail.isNotEmpty
              ? ' '
              : rawSeparator.trim(),
          name: tail,
          pattern: tail.isEmpty
              ? SerialPattern.prefixNumberName
              : SerialPattern.prefixNumberSpaceName,
        );
      }
    }

    final numberWithAttachedName = RegExp(
      r'^0*(\d+)([A-Za-z].*)$',
    ).firstMatch(serial);
    if (numberWithAttachedName != null) {
      return _valid(
        number: int.parse(numberWithAttachedName.group(1)!),
        name: numberWithAttachedName.group(2)!.trim(),
        pattern: SerialPattern.numberSpaceName,
      );
    }

    final numberWithTail = RegExp(r'^0*(\d+)(?:(/|\s+|\.)\s*(.*))?$')
        .firstMatch(serial);
    if (numberWithTail != null) {
      final number = int.parse(numberWithTail.group(1)!);
      final rawSeparator = numberWithTail.group(2) ?? '';
      final tail = numberWithTail.group(3)?.trim() ?? '';
      if (number <= 0) return const ParsedLoanSerial.invalid();
      if (rawSeparator.isEmpty && tail.isEmpty) {
        return _valid(number: number, pattern: SerialPattern.numberOnly);
      }

      return _valid(
        number: number,
        separator: rawSeparator.trim().isEmpty ? ' ' : rawSeparator.trim(),
        name: tail,
        pattern: rawSeparator.trim() == '/'
            ? SerialPattern.numberSlashName
            : SerialPattern.numberSpaceName,
      );
    }

    final nameSlashNumber = RegExp(r'^(.+)/0*(\d+)$').firstMatch(serial);
    if (nameSlashNumber != null) {
      return _valid(
        number: int.parse(nameSlashNumber.group(2)!),
        separator: '/',
        name: nameSlashNumber.group(1)!.trim(),
        pattern: SerialPattern.nameSlashNumber,
      );
    }

    return const ParsedLoanSerial.invalid();
  }

  static String generate({
    required String customerName,
    required List<Loan> existingLoans,
    String? borrowerName,
    Map<String, LoanSerialNumberConfig> configs = customerConfigs,
  }) {
    final normalizedName = _normalizeName(customerName);
    final config = configs[normalizedName] ?? const LoanSerialNumberConfig();
    if (!config.autoSerialEnabled || excludedCustomerNames.contains(normalizedName)) {
      return '';
    }

    final customerLoans = existingLoans
        .where((loan) => _normalizeName(loan.name) == normalizedName)
        .toList();
    final parsedHistory = customerLoans
        .map((loan) => parseSerial(loan.serialNumber))
        .where((serial) => serial.valid)
        .toList();

    final strategy = parsedHistory.isNotEmpty
        ? _historicalStrategy(normalizedName, parsedHistory)
        : _newCustomerStrategy(customerName, config);
    final usedSerials = existingLoans
        .map((loan) => loan.serialNumber.trim().toLowerCase())
        .toSet();
    var nextNumber = parsedHistory.isEmpty
        ? 1
        : parsedHistory.map((serial) => serial.number).reduce(_max) + 1;
    var candidate = _format(strategy, nextNumber, borrowerName ?? customerName);

    while (usedSerials.contains(candidate.trim().toLowerCase())) {
      nextNumber++;
      candidate = _format(strategy, nextNumber, borrowerName ?? customerName);
    }
    return candidate;
  }

  static bool shouldAutoReplaceSerial({
    required String serialNumber,
    required String customerName,
    required List<Loan> existingLoans,
    Map<String, LoanSerialNumberConfig> configs = customerConfigs,
  }) {
    if (serialNumber.trim().isEmpty) return true;

    final normalizedName = _normalizeName(customerName);
    final config = configs[normalizedName] ?? const LoanSerialNumberConfig();
    if (!config.autoSerialEnabled || excludedCustomerNames.contains(normalizedName)) {
      return false;
    }

    final parsed = parseSerial(serialNumber);
    if (!parsed.valid) return false;

    final customerHistory = existingLoans
        .where((loan) => _normalizeName(loan.name) == normalizedName)
        .map((loan) => parseSerial(loan.serialNumber))
        .where((serial) => serial.valid)
        .toList();
    final strategy = customerHistory.isNotEmpty
        ? _historicalStrategy(normalizedName, customerHistory)
        : _newCustomerStrategy(customerName, config);

    return _matchesStrategy(parsed, strategy);
  }

  static String generatePrefix(String loanTakerName) {
    final words = loanTakerName
        .trim()
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((word) => word.isNotEmpty)
        .where((word) => !_genericWords.contains(word))
        .toList();
    final significantWords = words.isEmpty
        ? loanTakerName
            .trim()
            .toUpperCase()
            .split(RegExp(r'[^A-Z0-9]+'))
            .where((word) => word.isNotEmpty)
            .toList()
        : words;

    if (significantWords.isEmpty) return 'LO-TA';
    if (significantWords.length == 1) return _take(significantWords.first, 4);

    final first = _take(significantWords.first, 2);
    final last = _take(significantWords.last, 2);
    return '$first-$last';
  }

  static ParsedLoanSerial _valid({
    required int number,
    String prefix = '',
    String separator = '',
    String name = '',
    required SerialPattern pattern,
  }) {
    if (number <= 0) return const ParsedLoanSerial.invalid();
    return ParsedLoanSerial(
      number: number,
      prefix: prefix,
      separator: separator,
      name: name,
      valid: true,
      pattern: pattern,
    );
  }

  static _ResolvedSerialStrategy _historicalStrategy(
    String normalizedCustomerName,
    List<ParsedLoanSerial> parsedHistory,
  ) {
    final known = _knownHistoricalStrategies[normalizedCustomerName];
    if (known != null) return known;

    final counts = <SerialPattern, int>{};
    for (final serial in parsedHistory) {
      counts[serial.pattern] = (counts[serial.pattern] ?? 0) + 1;
    }
    final dominant = counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    ).key;
    final matching = parsedHistory.lastWhere(
      (serial) => serial.pattern == dominant,
      orElse: () => parsedHistory.last,
    );

    switch (dominant) {
      case SerialPattern.numberSlashName:
      case SerialPattern.nameSlashNumber:
        return const _ResolvedSerialStrategy(type: _SerialStrategy.numberSlashName);
      case SerialPattern.numberSpaceName:
        return const _ResolvedSerialStrategy(type: _SerialStrategy.numberSpaceName);
      case SerialPattern.prefixNumberSpaceName:
        return _ResolvedSerialStrategy(
          type: _SerialStrategy.prefixNumberSpaceName,
          prefix: matching.prefix,
          padding: _paddingForPrefix(matching.prefix),
        );
      case SerialPattern.prefixNumberName:
        return _ResolvedSerialStrategy(
          type: _SerialStrategy.prefixNumberName,
          prefix: matching.prefix,
          padding: _paddingForPrefix(matching.prefix),
        );
      case SerialPattern.nameBasedPrefix:
        return _ResolvedSerialStrategy(
          type: _SerialStrategy.nameBasedPrefix,
          prefix: matching.prefix,
          padding: defaultNewCustomerPadding,
        );
      case SerialPattern.numberOnly:
      case SerialPattern.invalid:
        return const _ResolvedSerialStrategy(type: _SerialStrategy.numberOnly);
    }
  }

  static _ResolvedSerialStrategy _newCustomerStrategy(
    String customerName,
    LoanSerialNumberConfig config,
  ) {
    final prefix = (config.customPrefix?.trim().isNotEmpty ?? false)
        ? config.customPrefix!.trim().toUpperCase()
        : generatePrefix(customerName);
    return _ResolvedSerialStrategy(
      type: _SerialStrategy.nameBasedPrefix,
      prefix: prefix,
      padding: config.padding,
    );
  }

  static String _format(
    _ResolvedSerialStrategy strategy,
    int number,
    String borrowerName,
  ) {
    final padded = strategy.padding > 0
        ? number.toString().padLeft(strategy.padding, '0')
        : number.toString();
    switch (strategy.type) {
      case _SerialStrategy.numberOnly:
        return number.toString();
      case _SerialStrategy.numberSlashName:
        return '$number/$borrowerName';
      case _SerialStrategy.numberSpaceName:
        return '$number $borrowerName';
      case _SerialStrategy.prefixNumberSpaceName:
        return '${strategy.prefix}$padded $borrowerName';
      case _SerialStrategy.prefixNumberName:
        return '${strategy.prefix}$padded';
      case _SerialStrategy.nameBasedPrefix:
        return '${strategy.prefix}-$padded';
    }
  }

  static bool _matchesStrategy(
    ParsedLoanSerial parsed,
    _ResolvedSerialStrategy strategy,
  ) {
    switch (strategy.type) {
      case _SerialStrategy.numberOnly:
        return parsed.pattern == SerialPattern.numberOnly;
      case _SerialStrategy.numberSlashName:
        return parsed.pattern == SerialPattern.numberSlashName ||
            parsed.pattern == SerialPattern.nameSlashNumber;
      case _SerialStrategy.numberSpaceName:
        return parsed.pattern == SerialPattern.numberSpaceName;
      case _SerialStrategy.prefixNumberSpaceName:
      case _SerialStrategy.prefixNumberName:
        return parsed.prefix.toLowerCase() == strategy.prefix.toLowerCase();
      case _SerialStrategy.nameBasedPrefix:
        return parsed.pattern == SerialPattern.nameBasedPrefix &&
            parsed.prefix.toUpperCase() == strategy.prefix.toUpperCase();
    }
  }

  static int _paddingForPrefix(String prefix) {
    return prefix.toLowerCase() == 'pls' ? 5 : 0;
  }

  static int _max(int a, int b) => a > b ? a : b;

  static String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _take(String value, int count) {
    if (value.length >= count) return value.substring(0, count);
    return value.padRight(count, 'X');
  }

  static const Set<String> _genericWords = {
    'THE',
    'AND',
    'OF',
    'LOAN',
    'SHOP',
    'STORE',
  };
}
