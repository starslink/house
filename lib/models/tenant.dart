import 'package:intl/intl.dart';

class Tenant {
  final String id;
  final String name;
  final String phone;
  final String idNumber;
  final String? unitId;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final List<Contract> contracts;

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.idNumber,
    this.unitId,
    this.leaseStartDate,
    this.leaseEndDate,
    required this.contracts,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'idNumber': idNumber,
      'unitId': unitId,
      'leaseStartDate': leaseStartDate?.toIso8601String(),
      'leaseEndDate': leaseEndDate?.toIso8601String(),
      'contracts': contracts.map((contract) => contract.toMap()).toList(),
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      idNumber: map['idNumber'],
      unitId: map['unitId'],
      leaseStartDate:
          map['leaseStartDate'] != null
              ? DateTime.parse(map['leaseStartDate'])
              : null,
      leaseEndDate:
          map['leaseEndDate'] != null
              ? DateTime.parse(map['leaseEndDate'])
              : null,
      contracts: List<Contract>.from(
        map['contracts']?.map((x) => Contract.fromMap(x)) ?? [],
      ),
    );
  }

  String get leaseStatus {
    if (leaseStartDate == null || leaseEndDate == null) {
      return '无租约';
    }

    final now = DateTime.now();
    if (now.isBefore(leaseStartDate!)) {
      return '未开始';
    } else if (now.isAfter(leaseEndDate!)) {
      return '已结束';
    } else {
      return '租约中';
    }
  }

  String get formattedLeaseDate {
    if (leaseStartDate == null || leaseEndDate == null) {
      return '无租约';
    }

    final DateFormat formatter = DateFormat('yyyy年MM月dd日');
    return '${formatter.format(leaseStartDate!)} 至 ${formatter.format(leaseEndDate!)}';
  }
}

class Contract {
  final String id;
  final String tenantId;
  final String content;
  final DateTime createdAt;

  Contract({
    required this.id,
    required this.tenantId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Contract.fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'],
      tenantId: map['tenantId'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
