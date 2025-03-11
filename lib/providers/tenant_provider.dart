import 'package:flutter/material.dart';
import '../models/tenant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TenantProvider with ChangeNotifier {
  List<Tenant> _tenants = [];
  bool _isLoading = false;
  String? _error;

  TenantProvider() {
    _loadTenants();
  }

  List<Tenant> get tenants => _tenants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final tenantsJson = prefs.getString('tenants');

      if (tenantsJson != null) {
        final List<dynamic> decoded = jsonDecode(tenantsJson);
        _tenants = decoded.map((item) => Tenant.fromMap(item)).toList();
      } else {
        // Add some sample data for demo
        _tenants = [
          Tenant(
            id: '1',
            name: '张三',
            phone: '13800138000',
            idNumber: '110101199001011234',
            unitId: '101',
            leaseStartDate: DateTime(2023, 1, 1),
            leaseEndDate: DateTime(2024, 1, 1),
            contracts: [
              Contract(
                id: '1',
                tenantId: '1',
                content: '这是一份租赁合同...',
                createdAt: DateTime(2023, 1, 1),
              ),
            ],
          ),
          Tenant(
            id: '2',
            name: '李四',
            phone: '13900139000',
            idNumber: '110101199102022345',
            unitId: '102',
            leaseStartDate: DateTime(2023, 2, 1),
            leaseEndDate: DateTime(2024, 2, 1),
            contracts: [
              Contract(
                id: '2',
                tenantId: '2',
                content: '这是一份租赁合同...',
                createdAt: DateTime(2023, 2, 1),
              ),
            ],
          ),
        ];
        await _saveTenants();
      }
    } catch (e) {
      _error = '加载租客数据失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveTenants() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantsJson = jsonEncode(_tenants.map((t) => t.toMap()).toList());
    await prefs.setString('tenants', tenantsJson);
  }

  Future<void> addTenant(Tenant tenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tenants.add(tenant);
      await _saveTenants();
    } catch (e) {
      _error = '添加租客失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTenant(Tenant tenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        _tenants[index] = tenant;
        await _saveTenants();
      } else {
        _error = '未找到要更新的租客';
      }
    } catch (e) {
      _error = '更新租客失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTenant(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tenants.removeWhere((t) => t.id == id);
      await _saveTenants();
    } catch (e) {
      _error = '删除租客失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addContract(String tenantId, Contract contract) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _tenants.indexWhere((t) => t.id == tenantId);
      if (index != -1) {
        final tenant = _tenants[index];
        final contracts = List<Contract>.from(tenant.contracts);
        contracts.add(contract);

        _tenants[index] = Tenant(
          id: tenant.id,
          name: tenant.name,
          phone: tenant.phone,
          idNumber: tenant.idNumber,
          unitId: tenant.unitId,
          leaseStartDate: tenant.leaseStartDate,
          leaseEndDate: tenant.leaseEndDate,
          contracts: contracts,
        );

        await _saveTenants();
      } else {
        _error = '未找到要添加合同的租客';
      }
    } catch (e) {
      _error = '添加合同失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateContract(String tenantId, Contract contract) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tenantIndex = _tenants.indexWhere((t) => t.id == tenantId);
      if (tenantIndex != -1) {
        final tenant = _tenants[tenantIndex];
        final contractIndex = tenant.contracts.indexWhere(
          (c) => c.id == contract.id,
        );

        if (contractIndex != -1) {
          final contracts = List<Contract>.from(tenant.contracts);
          contracts[contractIndex] = contract;

          _tenants[tenantIndex] = Tenant(
            id: tenant.id,
            name: tenant.name,
            phone: tenant.phone,
            idNumber: tenant.idNumber,
            unitId: tenant.unitId,
            leaseStartDate: tenant.leaseStartDate,
            leaseEndDate: tenant.leaseEndDate,
            contracts: contracts,
          );

          await _saveTenants();
        } else {
          _error = '未找到要更新的合同';
        }
      } else {
        _error = '未找到要更新合同的租客';
      }
    } catch (e) {
      _error = '更新合同失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteContract(String tenantId, String contractId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tenantIndex = _tenants.indexWhere((t) => t.id == tenantId);
      if (tenantIndex != -1) {
        final tenant = _tenants[tenantIndex];
        final contracts = List<Contract>.from(tenant.contracts);
        contracts.removeWhere((c) => c.id == contractId);

        _tenants[tenantIndex] = Tenant(
          id: tenant.id,
          name: tenant.name,
          phone: tenant.phone,
          idNumber: tenant.idNumber,
          unitId: tenant.unitId,
          leaseStartDate: tenant.leaseStartDate,
          leaseEndDate: tenant.leaseEndDate,
          contracts: contracts,
        );

        await _saveTenants();
      } else {
        _error = '未找到要删除合同的租客';
      }
    } catch (e) {
      _error = '删除合同失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Tenant? getTenantById(String id) {
    try {
      return _tenants.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Tenant? getTenantByUnitId(String unitId) {
    try {
      return _tenants.firstWhere((t) => t.unitId == unitId);
    } catch (e) {
      return null;
    }
  }

  Contract? getContractById(String tenantId, String contractId) {
    try {
      final tenant = _tenants.firstWhere((t) => t.id == tenantId);
      return tenant.contracts.firstWhere((c) => c.id == contractId);
    } catch (e) {
      return null;
    }
  }
}
