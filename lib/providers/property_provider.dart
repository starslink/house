import 'package:flutter/material.dart';
import '../models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      final prefs = await SharedPreferences.getInstance();
      final propertiesJson = prefs.getString('properties');

      if (propertiesJson != null) {
        final List<dynamic> decoded = jsonDecode(propertiesJson);
        _properties = decoded.map((item) => Property.fromMap(item)).toList();
      } else {
        // Add some sample data for demo
        _properties = [
          Property(
            id: '1',
            address: '北京市海淀区中关村大街1号',
            waterRate: 5.0,
            electricityRate: 0.8,
            managementFee: 200.0,
            units: [
              Unit(id: '101', unitNumber: '101', baseRent: 3000),
              Unit(id: '102', unitNumber: '102', baseRent: 3200),
              Unit(id: '201', unitNumber: '201', baseRent: 3500),
              Unit(id: '202', unitNumber: '202', baseRent: 3800),
            ],
          ),
          Property(
            id: '2',
            address: '上海市浦东新区张江高科技园区',
            waterRate: 4.5,
            electricityRate: 0.75,
            managementFee: 180.0,
            units: [
              Unit(id: '101A', unitNumber: '101A', baseRent: 4000),
              Unit(id: '102A', unitNumber: '102A', baseRent: 4200),
              Unit(id: '201A', unitNumber: '201A', baseRent: 4500),
            ],
          ),
        ];
        await _saveProperties();
      }
    } catch (e) {
      _error = '加载房屋数据失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final propertiesJson = jsonEncode(
      _properties.map((p) => p.toMap()).toList(),
    );
    await prefs.setString('properties', propertiesJson);
  }

  Future<void> addProperty(Property property) async {
    _isLoading = true;
    notifyListeners();

    try {
      _properties.add(property);
      await _saveProperties();
    } catch (e) {
      _error = '添加房屋失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProperty(Property property) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        await _saveProperties();
      } else {
        _error = '未找到要更新的房屋';
      }
    } catch (e) {
      _error = '更新房屋失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProperty(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _properties.removeWhere((p) => p.id == id);
      await _saveProperties();
    } catch (e) {
      _error = '删除房屋失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUnit(String propertyId, Unit unit) async {
    _isLoading = true;
    notifyListeners();

    try {
      final index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        final property = _properties[index];
        final units = List<Unit>.from(property.units);
        units.add(unit);

        _properties[index] = Property(
          id: property.id,
          address: property.address,
          waterRate: property.waterRate,
          electricityRate: property.electricityRate,
          managementFee: property.managementFee,
          units: units,
        );

        await _saveProperties();
      } else {
        _error = '未找到要添加单元的房屋';
      }
    } catch (e) {
      _error = '添加单元失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUnit(String propertyId, Unit unit) async {
    _isLoading = true;
    notifyListeners();

    try {
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

          await _saveProperties();
        } else {
          _error = '未找到要更新的单元';
        }
      } else {
        _error = '未找到要更新单元的房屋';
      }
    } catch (e) {
      _error = '更新单元失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteUnit(String propertyId, String unitId) async {
    _isLoading = true;
    notifyListeners();

    try {
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

        await _saveProperties();
      } else {
        _error = '未找到要删除单元的房屋';
      }
    } catch (e) {
      _error = '删除单元失败: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
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
