import 'package:flutter/material.dart';

import '../models/rent.dart';
import '../services/api_service.dart';

class RentProvider with ChangeNotifier {
  List<RentRecord> _rentRecords = [];
  bool _isLoading = false;
  String? _error;

  RentProvider() {
    _loadRentRecords();
  }

  List<RentRecord> get rentRecords => _rentRecords;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> _loadRentRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/rent-records');

      if (response != null && response['code'] == 200) {
        final List<dynamic> rentRecordsData = response['data'];
        _rentRecords =
            rentRecordsData
                .map(
                  (item) => RentRecord(
                    id: item['id'],
                    unitId: item['unitId'],
                    tenantId: item['tenantId'],
                    month: DateTime.parse(item['month']),
                    baseRent: double.parse(item['baseRent'].toString()),
                    waterUsage: double.parse(item['waterUsage'].toString()),
                    previousWaterUsage: double.parse(
                      item['previousWaterUsage'].toString(),
                    ),
                    waterRate: double.parse(item['waterRate'].toString()),
                    electricityUsage: double.parse(
                      item['electricityUsage'].toString(),
                    ),
                    previousElectricityUsage: double.parse(
                      item['previousElectricityUsage'].toString(),
                    ),
                    electricityRate: double.parse(
                      item['electricityRate'].toString(),
                    ),
                    managementFee: double.parse(
                      item['managementFee'].toString(),
                    ),
                    isPaid: item['isPaid'],
                    paidDate:
                        item['paidDate'] != null
                            ? DateTime.parse(item['paidDate'])
                            : null,
                  ),
                )
                .toList();
      } else {
        _error = response['message'] ?? '加载租金记录失败';
      }
    } catch (e) {
      _error = '加载租金记录失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshRentRecords() async {
    await _loadRentRecords();
  }

  Future<void> addRentRecord(RentRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/rent-records', {
        'unitId': record.unitId,
        'tenantId': record.tenantId,
        'month': record.month.toIso8601String(),
        'baseRent': record.baseRent,
        'waterUsage': record.waterUsage,
        'previousWaterUsage': record.previousWaterUsage,
        'waterRate': record.waterRate,
        'electricityUsage': record.electricityUsage,
        'previousElectricityUsage': record.previousElectricityUsage,
        'electricityRate': record.electricityRate,
        'managementFee': record.managementFee,
        'isPaid': record.isPaid,
        'paidDate': record.paidDate?.toIso8601String(),
      });

      if (response != null && response['code'] == 200) {
        final rentRecordData = response['data'];
        final newRecord = RentRecord(
          id: rentRecordData['id'],
          unitId: record.unitId,
          tenantId: record.tenantId,
          month: record.month,
          baseRent: record.baseRent,
          waterUsage: record.waterUsage,
          previousWaterUsage: record.previousWaterUsage,
          waterRate: record.waterRate,
          electricityUsage: record.electricityUsage,
          previousElectricityUsage: record.previousElectricityUsage,
          electricityRate: record.electricityRate,
          managementFee: record.managementFee,
          isPaid: record.isPaid,
          paidDate: record.paidDate,
        );
        _rentRecords.add(newRecord);
      } else {
        _error = response['message'] ?? '添加租金记录失败';
      }
    } catch (e) {
      _error = '添加租金记录失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRentRecord(RentRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.put('/rent-records/${record.id}', {
        'unitId': record.unitId,
        'tenantId': record.tenantId,
        'month': record.month.toIso8601String(),
        'baseRent': record.baseRent,
        'waterUsage': record.waterUsage,
        'previousWaterUsage': record.previousWaterUsage,
        'waterRate': record.waterRate,
        'electricityUsage': record.electricityUsage,
        'previousElectricityUsage': record.previousElectricityUsage,
        'electricityRate': record.electricityRate,
        'managementFee': record.managementFee,
        'isPaid': record.isPaid,
        'paidDate': record.paidDate?.toIso8601String(),
      });

      if (response != null && response['code'] == 200) {
        final index = _rentRecords.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          _rentRecords[index] = record;
        }
      } else {
        _error = response['message'] ?? '更新租金记录失败';
      }
    } catch (e) {
      _error = '更新租金记录失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRentRecord(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.delete('/rent-records/$id');

      if (response != null && response['code'] == 200) {
        _rentRecords.removeWhere((r) => r.id == id);
      } else {
        _error = response['message'] ?? '删除租金记录失败';
      }
    } catch (e) {
      _error = '删除租金记录失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsPaid(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post(
        '/rent-records/$id/mark-as-paid',
        {},
      );

      if (response != null && response['code'] == 200) {
        final index = _rentRecords.indexWhere((r) => r.id == id);
        if (index != -1) {
          final record = _rentRecords[index];
          _rentRecords[index] = RentRecord(
            id: record.id,
            unitId: record.unitId,
            tenantId: record.tenantId,
            month: record.month,
            baseRent: record.baseRent,
            waterUsage: record.waterUsage,
            previousWaterUsage: record.previousWaterUsage,
            waterRate: record.waterRate,
            electricityUsage: record.electricityUsage,
            previousElectricityUsage: record.previousElectricityUsage,
            electricityRate: record.electricityRate,
            managementFee: record.managementFee,
            isPaid: true,
            paidDate: DateTime.now(),
          );
        }
      } else {
        _error = response['message'] ?? '标记为已付款失败';
      }
    } catch (e) {
      _error = '标记为已付款失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  RentRecord? getRentRecordById(String id) {
    try {
      return _rentRecords.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  List<RentRecord> getRentRecordsByUnitId(String unitId) {
    return _rentRecords.where((r) => r.unitId == unitId).toList();
  }

  List<RentRecord> getRentRecordsByTenantId(String tenantId) {
    return _rentRecords.where((r) => r.tenantId == tenantId).toList();
  }

  List<RentRecord> getRentRecordsByMonth(DateTime month) {
    return _rentRecords
        .where(
          (r) => r.month.year == month.year && r.month.month == month.month,
        )
        .toList();
  }

  RentRecord? getLatestRentRecord(String unitId) {
    try {
      final records = getRentRecordsByUnitId(unitId);
      records.sort((a, b) => b.month.compareTo(a.month));
      return records.first;
    } catch (e) {
      return null;
    }
  }
}
