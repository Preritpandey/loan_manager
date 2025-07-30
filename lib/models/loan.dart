// models/loan.dart
import 'package:hive/hive.dart';
part 'loan.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  int duration;
  @HiveField(3)
  double interestRate;
  @HiveField(4)
  String type;
  @HiveField(5)
  String jewelleryName;
  @HiveField(6)
  String serialNumber;
  @HiveField(7)
  String phone;
  @HiveField(8)
  String address;
  @HiveField(9)
  String description;
  @HiveField(10)
  double amountGiven;
  @HiveField(11)
  double amountReceived;

  Loan({
    required this.name,
    required this.date,
    required this.duration,
    required this.interestRate,
    required this.type,
    required this.jewelleryName,
    required this.serialNumber,
    required this.phone,
    required this.address,
    required this.description,
    required this.amountGiven,
    this.amountReceived = 0.0,
  });

  double get acquiredInterest {
    final daysPassed = DateTime.now().difference(date).inDays;
    final interestPerDay = (amountGiven * interestRate) / 100 / 30;
    return interestPerDay * daysPassed;
  }
}
