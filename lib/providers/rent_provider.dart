import 'package:flutter/material.dart';
import '../models/rent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      final prefs = await SharedPreferences.getInstance();
      final rentRecordsJson = prefs.getString('rentRecords');

      if (rentRecordsJson != null) {
        final List<dynamic> decoded = jsonDecode(rentRecordsJson);
        _rentRecords = decoded.map((item) => RentRecord.fromMap(item)).toList();
      } else {
        // Add some sample data for demo
        _rentRecords = [
          RentRecord(
            id: '1',
            unitId: '101',
            tenantId: '1',
            month: DateTime(2023, 1),
            baseRent: 3000,
            waterUsage: 10.0,
            previousWaterUsage: 5.0,
            waterRate: 5.0,
            electricityUsage: 200.0,
            previousElectricityUsage: 150.0,
            electricityRate: 0.8,
            managementFee: 200.0,
            isPaid: true,
            paidDate: DateTime(2023, 1, 5),
          ),
          RentRecord(
            id: '2',
            unitId: '101',
            tenantId: '1',
            month: DateTime(2023, 2),
            baseRent: 3000,
            waterUsage: 15.0,
            previousWaterUsage: 10.0,
            waterRate: 5.0,
            electricityUsage: 250.0,
            previousElectricityUsage: 200.0,
            electricityRate: 0.8,
            managementFee: 200.0,
            isPaid: true,
            paidDate: DateTime(2023, 2, 5),
          ),
          RentRecord(
            id: '3',
            unitId: '101',
            tenantId: '1',
            month: DateTime(2023, 3),
            baseRent: 3000,
            waterUsage: 20.0,
            previousWaterUsage: 15.0,
            waterRate: 5.0,
            electricityUsage: 300.0,
            previousElectricityUsage: 250.0,
            electricityRate: 0.8,
            managementFee: 200.0,
            isPaid: false,
          ),
        ];
        await _saveRentRecords();
      }
    } catch (e) {
      _error = '加载租金记录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveRentRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final rentRecordsJson = jsonEncode(
      _rentRecords.map((r) => r.toMap()).toList(),
    );
    await prefs.setString('rentRecords', rentRecordsJson);
  }

  Future<void> addRentRecord(RentRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rentRecords.add(record);
      await _saveRentRecords();
    } catch (e) {
      _error = '添加租金记录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateRentRecord(RentRecord record) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _rentRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _rentRecords[index] = record;
        await _saveRentRecords();
      } else {
        _error = '未找到要更新的租金记录';
      }
    } catch (e) {
      _error = '更新租金记录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRentRecord(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _rentRecords.removeWhere((r) => r.id == id);
      await _saveRentRecords();
    } catch (e) {
      _error = '删除租金记录失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsPaid(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
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
        await _saveRentRecords();
      } else {
        _error = '未找到要标记为已付款的租金记录';
      }
    } catch (e) {
      _error = '标记为已付款失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
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
