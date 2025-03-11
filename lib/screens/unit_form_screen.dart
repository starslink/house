import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../models/property.dart';
import 'package:uuid/uuid.dart';

class UnitFormScreen extends StatefulWidget {
  final String propertyId;
  final String? unitId;

  const UnitFormScreen({super.key, required this.propertyId, this.unitId});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNumberController = TextEditingController();
  final _baseRentController = TextEditingController();

  bool _isEditing = false;
  Unit? _unit;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.unitId != null;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadUnit();
      });
    }
  }

  void _loadUnit() {
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    _unit = propertyProvider.getUnitById(widget.propertyId, widget.unitId!);

    if (_unit != null) {
      _unitNumberController.text = _unit!.unitNumber;
      _baseRentController.text = _unit!.baseRent.toString();
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _baseRentController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (_formKey.currentState!.validate()) {
      final propertyProvider = Provider.of<PropertyProvider>(
        context,
        listen: false,
      );

      final unitNumber = _unitNumberController.text.trim();
      final baseRent = double.parse(_baseRentController.text.trim());

      if (_isEditing && _unit != null) {
        final updatedUnit = Unit(
          id: _unit!.id,
          unitNumber: unitNumber,
          baseRent: baseRent,
          currentTenantId: _unit!.currentTenantId,
        );

        await propertyProvider.updateUnit(widget.propertyId, updatedUnit);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('单元信息已更新')));
          Navigator.pop(context);
        }
      } else {
        final newUnit = Unit(
          id: const Uuid().v4(),
          unitNumber: unitNumber,
          baseRent: baseRent,
        );

        await propertyProvider.addUnit(widget.propertyId, newUnit);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('单元已添加')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑单元' : '添加单元')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _unitNumberController,
              decoration: const InputDecoration(
                labelText: '单元号',
                hintText: '请输入单元号，例如: 101',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入单元号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baseRentController,
              decoration: const InputDecoration(
                labelText: '基础租金 (元/月)',
                hintText: '请输入基础租金',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入基础租金';
                }
                if (double.tryParse(value) == null) {
                  return '请输入有效的数字';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveUnit,
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
                          title: const Text('删除单元'),
                          content: const Text('确定要删除这个单元吗？'),
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
                                await propertyProvider.deleteUnit(
                                  widget.propertyId,
                                  widget.unitId!,
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(
                                    context,
                                  ); // Go back to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('单元已删除')),
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
                child: const Text('删除单元'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
