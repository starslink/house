import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property.dart';
import 'package:uuid/uuid.dart';

class PropertyFormScreen extends StatefulWidget {
  final String? propertyId;

  const PropertyFormScreen({super.key, this.propertyId});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _waterRateController = TextEditingController();
  final _electricityRateController = TextEditingController();
  final _managementFeeController = TextEditingController();

  bool _isEditing = false;
  Property? _property;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.propertyId != null;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProperty();
      });
    }
  }

  void _loadProperty() {
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    _property = propertyProvider.getPropertyById(widget.propertyId!);

    if (_property != null) {
      _addressController.text = _property!.address;
      _waterRateController.text = _property!.waterRate.toString();
      _electricityRateController.text = _property!.electricityRate.toString();
      _managementFeeController.text = _property!.managementFee.toString();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _waterRateController.dispose();
    _electricityRateController.dispose();
    _managementFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      final propertyProvider = Provider.of<PropertyProvider>(
        context,
        listen: false,
      );

      final address = _addressController.text.trim();
      final waterRate = double.parse(_waterRateController.text.trim());
      final electricityRate = double.parse(
        _electricityRateController.text.trim(),
      );
      final managementFee = double.parse(_managementFeeController.text.trim());

      if (_isEditing && _property != null) {
        final updatedProperty = Property(
          id: _property!.id,
          address: address,
          waterRate: waterRate,
          electricityRate: electricityRate,
          managementFee: managementFee,
          units: _property!.units,
        );

        await propertyProvider.updateProperty(updatedProperty);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('房屋信息已更新')));
          Navigator.pop(context);
        }
      } else {
        final newProperty = Property(
          id: const Uuid().v4(),
          address: address,
          waterRate: waterRate,
          electricityRate: electricityRate,
          managementFee: managementFee,
          units: [],
        );

        await propertyProvider.addProperty(newProperty);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('房屋已添加')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑房屋' : '添加房屋')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '房屋地址',
                hintText: '请输入房屋地址',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入房屋地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _waterRateController,
              decoration: const InputDecoration(
                labelText: '水费单价 (元/吨)',
                hintText: '请输入水费单价',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入水费单价';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _electricityRateController,
              decoration: const InputDecoration(
                labelText: '电费单价 (元/度)',
                hintText: '请输入电费单价',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入电费单价';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _managementFeeController,
              decoration: const InputDecoration(
                labelText: '管理费 (元/月)',
                hintText: '请输入管理费',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入管理费';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProperty,
              child: Text(_isEditing ? '更新' : '添加'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('删除房屋'),
                          content: const Text('确定要删除这个房屋吗？这将同时删除所有相关的单元信息。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final propertyProvider =
                                    Provider.of<PropertyProvider>(
                                      context,
                                      listen: false,
                                    );
                                await propertyProvider.deleteProperty(
                                  widget.propertyId!,
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(
                                    context,
                                  ); // Go back to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('房屋已删除')),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                  );
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('删除房屋'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
