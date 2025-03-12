import 'package:intl/intl.dart';

class RentRecord {
  final String id;
  final String unitId;
  final String? tenantId;
  final DateTime month;
  final double baseRent;
  final double waterUsage;
  final double previousWaterUsage;
  final double waterRate;
  final double electricityUsage;
  final double previousElectricityUsage;
  final double electricityRate;
  final double managementFee;
  final bool isPaid;
  final DateTime? paidDate;

  RentRecord({
    required this.id,
    required this.unitId,
    this.tenantId,
    required this.month,
    required this.baseRent,
    required this.waterUsage,
    required this.previousWaterUsage,
    required this.waterRate,
    required this.electricityUsage,
    required this.previousElectricityUsage,
    required this.electricityRate,
    required this.managementFee,
    this.isPaid = false,
    this.paidDate,
  });

  double get waterFee => (waterUsage - previousWaterUsage) * waterRate;

  double get electricityFee => (electricityUsage - previousElectricityUsage) * electricityRate;

  double get totalRent => baseRent + waterFee + electricityFee + managementFee;

  String get formattedMonth {
    final DateFormat formatter = DateFormat('yyyy年MM月');
    return formatter.format(month);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unitId': unitId,
      'tenantId': tenantId,
      'month': month.toIso8601String(),
      'baseRent': baseRent,
      'waterUsage': waterUsage,
      'previousWaterUsage': previousWaterUsage,
      'waterRate': waterRate,
      'electricityUsage': electricityUsage,
      'previousElectricityUsage': previousElectricityUsage,
      'electricityRate': electricityRate,
      'managementFee': managementFee,
      'isPaid': isPaid,
      'paidDate': paidDate?.toIso8601String(),
    };
  }

  factory RentRecord.fromMap(Map<String, dynamic> map) {
    return RentRecord(
      id: map['id'],
      unitId: map['unitId'],
      tenantId: map['tenantId'],
      month: DateTime.parse(map['month']),
      baseRent: map['baseRent'],
      waterUsage: map['waterUsage'],
      previousWaterUsage: map['previousWaterUsage'],
      waterRate: map['waterRate'],
      electricityUsage: map['electricityUsage'],
      previousElectricityUsage: map['previousElectricityUsage'],
      electricityRate: map['electricityRate'],
      managementFee: map['managementFee'],
      isPaid: map['isPaid'],
      paidDate: map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
    );
  }
}