import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tenant.dart';
import '../services/api_service.dart';

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
      final response = await ApiService.get('/tenants');

      if (response != null && response['code'] == 200) {
        final List<dynamic> tenantsData = response['data'];
        _tenants =
            tenantsData.map((item) {
              final List<dynamic> contractsData = item['contracts'] ?? [];
              final List<Contract> contracts =
                  contractsData
                      .map(
                        (contractItem) => Contract(
                          id: contractItem['id'],
                          tenantId: contractItem['tenantId'],
                          content: contractItem['content'],
                          createdAt: DateTime.parse(contractItem['createdAt']),
                        ),
                      )
                      .toList();

              return Tenant(
                id: item['id'],
                name: item['name'],
                phone: item['phone'],
                idNumber: item['idNumber'],
                unitId: item['unitId'],
                leaseStartDate:
                    item['leaseStartDate'] != null
                        ? DateTime.parse(item['leaseStartDate'])
                        : null,
                leaseEndDate:
                    item['leaseEndDate'] != null
                        ? DateTime.parse(item['leaseEndDate'])
                        : null,
                contracts: contracts,
              );
            }).toList();
      } else {
        _error = response['message'] ?? '加载租客数据失败';
      }
    } catch (e) {
      _error = '加载租客数据失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTenants() async {
    await _loadTenants();
  }

  Future<void> addTenant(Tenant tenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/tenants', {
        'name': tenant.name,
        'phone': tenant.phone,
        'idNumber': tenant.idNumber,
        'unitId': tenant.unitId,
        'leaseStartDate': tenant.leaseStartDate?.toIso8601String(),
        'leaseEndDate': tenant.leaseEndDate?.toIso8601String(),
      });

      if (response != null && response['code'] == 200) {
        final tenantData = response['data'];
        final newTenant = Tenant(
          id: tenantData['id'],
          name: tenant.name,
          phone: tenant.phone,
          idNumber: tenant.idNumber,
          unitId: tenant.unitId,
          leaseStartDate: tenant.leaseStartDate,
          leaseEndDate: tenant.leaseEndDate,
          contracts: [],
        );
        _tenants.add(newTenant);
      } else {
        _error = response['message'] ?? '添加租客失败';
      }
    } catch (e) {
      _error = '添加租客失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.put('/tenants/${tenant.id}', {
        'name': tenant.name,
        'phone': tenant.phone,
        'idNumber': tenant.idNumber,
        'unitId': tenant.unitId,
        'leaseStartDate': tenant.leaseStartDate?.toIso8601String(),
        'leaseEndDate': tenant.leaseEndDate?.toIso8601String(),
      });

      if (response != null && response['code'] == 200) {
        final index = _tenants.indexWhere((t) => t.id == tenant.id);
        if (index != -1) {
          // Keep the existing contracts
          final existingContracts = _tenants[index].contracts;
          _tenants[index] = Tenant(
            id: tenant.id,
            name: tenant.name,
            phone: tenant.phone,
            idNumber: tenant.idNumber,
            unitId: tenant.unitId,
            leaseStartDate: tenant.leaseStartDate,
            leaseEndDate: tenant.leaseEndDate,
            contracts: existingContracts,
          );
        }
      } else {
        _error = response['message'] ?? '更新租客失败';
      }
    } catch (e) {
      _error = '更新租客失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTenant(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.delete('/tenants/$id');

      if (response != null && response['code'] == 200) {
        _tenants.removeWhere((t) => t.id == id);
      } else {
        _error = response['message'] ?? '删除租客失败';
      }
    } catch (e) {
      _error = '删除租客失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContract(String tenantId, Contract contract) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/contracts', {
        'tenantId': tenantId,
        'content': contract.content,
      });

      if (response != null && response['code'] == 200) {
        final contractData = response['data'];
        final newContract = Contract(
          id: contractData['id'],
          tenantId: tenantId,
          content: contract.content,
          createdAt: DateTime.parse(contractData['createdAt']),
        );

        final index = _tenants.indexWhere((t) => t.id == tenantId);
        if (index != -1) {
          final tenant = _tenants[index];
          final contracts = List<Contract>.from(tenant.contracts);
          contracts.add(newContract);

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
        }
      } else {
        _error = response['message'] ?? '添加合同失败';
      }
    } catch (e) {
      _error = '添加合同失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateContract(String tenantId, Contract contract) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.put('/contracts/${contract.id}', {
        'tenantId': tenantId,
        'content': contract.content,
      });

      if (response != null && response['code'] == 200) {
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
          }
        }
      } else {
        _error = response['message'] ?? '更新合同失败';
      }
    } catch (e) {
      _error = '更新合同失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteContract(String tenantId, String contractId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.delete('/contracts/$contractId');

      if (response != null && response['code'] == 200) {
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
        }
      } else {
        _error = response['message'] ?? '删除合同失败';
      }
    } catch (e) {
      _error = '删除合同失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
