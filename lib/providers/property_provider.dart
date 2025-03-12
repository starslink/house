import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/property.dart';
import '../services/api_service.dart';

class PropertyProvider with ChangeNotifier {
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;

  PropertyProvider() {
    _loadProperties();
  }

  List<Property> get properties => _properties;

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> _loadProperties() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/properties');

      if (response != null && response['code'] == 200) {
        final List<dynamic> propertiesData = response['data'];
        _properties =
            propertiesData.map((item) {
              final List<dynamic> unitsData = item['units'] ?? [];
              final List<Unit> units =
                  unitsData
                      .map(
                        (unitItem) => Unit(
                          id: unitItem['id'],
                          unitNumber: unitItem['unitNumber'],
                          baseRent: double.parse(
                            unitItem['baseRent'].toString(),
                          ),
                          currentTenantId: unitItem['currentTenantId'],
                        ),
                      )
                      .toList();

              return Property(
                id: item['id'],
                address: item['address'],
                waterRate: double.parse(item['waterRate'].toString()),
                electricityRate: double.parse(
                  item['electricityRate'].toString(),
                ),
                managementFee: double.parse(item['managementFee'].toString()),
                units: units,
              );
            }).toList();
      } else {
        _error = response['message'] ?? '加载房屋数据失败';
      }
    } catch (e) {
      _error = '加载房屋数据失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProperties() async {
    await _loadProperties();
  }

  Future<void> addProperty(Property property) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/properties', {
        'address': property.address,
        'waterRate': property.waterRate,
        'electricityRate': property.electricityRate,
        'managementFee': property.managementFee,
      });

      if (response != null && response['code'] == 200) {
        final propertyData = response['data'];
        final newProperty = Property(
          id: propertyData['id'],
          address: property.address,
          waterRate: property.waterRate,
          electricityRate: property.electricityRate,
          managementFee: property.managementFee,
          units: [],
        );
        _properties.add(newProperty);
      } else {
        _error = response['message'] ?? '添加房屋失败';
      }
    } catch (e) {
      _error = '添加房屋失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProperty(Property property) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.put('/properties/${property.id}', {
        'address': property.address,
        'waterRate': property.waterRate,
        'electricityRate': property.electricityRate,
        'managementFee': property.managementFee,
      });

      if (response != null && response['code'] == 200) {
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          // Keep the existing units
          final existingUnits = _properties[index].units;
          _properties[index] = Property(
            id: property.id,
            address: property.address,
            waterRate: property.waterRate,
            electricityRate: property.electricityRate,
            managementFee: property.managementFee,
            units: existingUnits,
          );
        }
      } else {
        _error = response['message'] ?? '更新房屋失败';
      }
    } catch (e) {
      _error = '更新房屋失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProperty(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.delete('/properties/$id');

      if (response != null && response['code'] == 200) {
        _properties.removeWhere((p) => p.id == id);
      } else {
        _error = response['message'] ?? '删除房屋失败';
      }
    } catch (e) {
      _error = '删除房屋失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUnit(String propertyId, Unit unit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/units', {
        'propertyId': propertyId,
        'unitNumber': unit.unitNumber,
        'baseRent': unit.baseRent,
      });

      if (response != null && response['code'] == 200) {
        final unitData = response['data'];
        final newUnit = Unit(
          id: unitData['id'],
          unitNumber: unit.unitNumber,
          baseRent: unit.baseRent,
        );

        final index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) {
          final property = _properties[index];
          final units = List<Unit>.from(property.units);
          units.add(newUnit);

          _properties[index] = Property(
            id: property.id,
            address: property.address,
            waterRate: property.waterRate,
            electricityRate: property.electricityRate,
            managementFee: property.managementFee,
            units: units,
          );
        }
      } else {
        _error = response['message'] ?? '添加单元失败';
      }
    } catch (e) {
      _error = '添加单元失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUnit(String propertyId, Unit unit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.put('/units/${unit.id}', {
        'propertyId': propertyId,
        'unitNumber': unit.unitNumber,
        'baseRent': unit.baseRent,
        'currentTenantId': unit.currentTenantId,
      });

      if (response != null && response['code'] == 200) {
        final propertyIndex = _properties.indexWhere((p) => p.id == propertyId);
        if (propertyIndex != -1) {
          final property = _properties[propertyIndex];
          final unitIndex = property.units.indexWhere((u) => u.id == unit.id);

          if (unitIndex != -1) {
            final units = List<Unit>.from(property.units);
            units[unitIndex] = unit;

            _properties[propertyIndex] = Property(
              id: property.id,
              address: property.address,
              waterRate: property.waterRate,
              electricityRate: property.electricityRate,
              managementFee: property.managementFee,
              units: units,
            );
          }
        }
      } else {
        _error = response['message'] ?? '更新单元失败';
      }
    } catch (e) {
      _error = '更新单元失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUnit(String propertyId, String unitId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.delete('/units/$unitId');

      if (response != null && response['code'] == 200) {
        final propertyIndex = _properties.indexWhere((p) => p.id == propertyId);
        if (propertyIndex != -1) {
          final property = _properties[propertyIndex];
          final units = List<Unit>.from(property.units);
          units.removeWhere((u) => u.id == unitId);

          _properties[propertyIndex] = Property(
            id: property.id,
            address: property.address,
            waterRate: property.waterRate,
            electricityRate: property.electricityRate,
            managementFee: property.managementFee,
            units: units,
          );
        }
      } else {
        _error = response['message'] ?? '删除单元失败';
      }
    } catch (e) {
      _error = '删除单元失败: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Property? getPropertyById(String id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Unit? getUnitById(String propertyId, String unitId) {
    try {
      final property = _properties.firstWhere((p) => p.id == propertyId);
      return property.units.firstWhere((u) => u.id == unitId);
    } catch (e) {
      return null;
    }
  }

  List<Unit> getAllUnits() {
    final allUnits = <Unit>[];
    for (final property in _properties) {
      allUnits.addAll(property.units);
    }
    return allUnits;
  }

  Property? getPropertyByUnitId(String unitId) {
    try {
      return _properties.firstWhere((p) => p.units.any((u) => u.id == unitId));
    } catch (e) {
      return null;
    }
  }
}
