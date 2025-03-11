import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rent_provider.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../models/rent.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class RentFormScreen extends StatefulWidget {
  final String? rentRecordId;
  final DateTime? initialMonth;

  const RentFormScreen({super.key, this.rentRecordId, this.initialMonth});

  @override
  State<RentFormScreen> createState() => _RentFormScreenState();
}

class _RentFormScreenState extends State<RentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _waterUsageController = TextEditingController();
  final _electricityUsageController = TextEditingController();

  bool _isEditing = false;
  RentRecord? _rentRecord;

  String? _selectedPropertyId;
  String? _selectedUnitId;
  DateTime _selectedMonth = DateTime.now();

  double _baseRent = 0;
  double _previousWaterUsage = 0;
  double _waterRate = 0;
  double _previousElectricityUsage = 0;
  double _electricityRate = 0;
  double _managementFee = 0;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.rentRecordId != null;

    if (widget.initialMonth != null) {
      _selectedMonth = widget.initialMonth!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        _loadRentRecord();
      }
    });
  }

  void _loadRentRecord() {
    final rentProvider = Provider.of<RentProvider>(context, listen: false);
    _rentRecord = rentProvider.getRentRecordById(widget.rentRecordId!);

    if (_rentRecord != null) {
      final propertyProvider = Provider.of<PropertyProvider>(
        context,
        listen: false,
      );
      final property = propertyProvider.getPropertyByUnitId(
        _rentRecord!.unitId,
      );

      setState(() {
        _selectedPropertyId = property?.id;
        _selectedUnitId = _rentRecord!.unitId;
        _selectedMonth = _rentRecord!.month;
        _baseRent = _rentRecord!.baseRent;
        _previousWaterUsage = _rentRecord!.previousWaterUsage;
        _waterRate = _rentRecord!.waterRate;
        _previousElectricityUsage = _rentRecord!.previousElectricityUsage;
        _electricityRate = _rentRecord!.electricityRate;
        _managementFee = _rentRecord!.managementFee;

        _waterUsageController.text = _rentRecord!.waterUsage.toString();
        _electricityUsageController.text =
            _rentRecord!.electricityUsage.toString();
      });
    }
  }

  void _updateUnitInfo() {
    if (_selectedUnitId != null) {
      final propertyProvider = Provider.of<PropertyProvider>(
        context,
        listen: false,
      );
      final property = propertyProvider.getPropertyByUnitId(_selectedUnitId!);
      final unit = propertyProvider.getUnitById(
        property?.id ?? '',
        _selectedUnitId!,
      );

      if (property != null && unit != null) {
        setState(() {
          _baseRent = unit.baseRent;
          _waterRate = property.waterRate;
          _electricityRate = property.electricityRate;
          _managementFee = property.managementFee;
        });

        // Get previous usage from the latest rent record
        final rentProvider = Provider.of<RentProvider>(context, listen: false);
        final latestRecord = rentProvider.getLatestRentRecord(_selectedUnitId!);

        if (latestRecord != null) {
          setState(() {
            _previousWaterUsage = latestRecord.waterUsage;
            _previousElectricityUsage = latestRecord.electricityUsage;
          });
        } else {
          setState(() {
            _previousWaterUsage = 0;
            _previousElectricityUsage = 0;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _waterUsageController.dispose();
    _electricityUsageController.dispose();
    super.dispose();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  double _calculateWaterFee() {
    if (_waterUsageController.text.isEmpty) return 0;

    final waterUsage = double.tryParse(_waterUsageController.text) ?? 0;
    return (waterUsage - _previousWaterUsage) * _waterRate;
  }

  double _calculateElectricityFee() {
    if (_electricityUsageController.text.isEmpty) return 0;

    final electricityUsage =
        double.tryParse(_electricityUsageController.text) ?? 0;
    return (electricityUsage - _previousElectricityUsage) * _electricityRate;
  }

  double _calculateTotalRent() {
    return _baseRent +
        _calculateWaterFee() +
        _calculateElectricityFee() +
        _managementFee;
  }

  Future<void> _saveRentRecord() async {
    if (_formKey.currentState!.validate()) {
      final rentProvider = Provider.of<RentProvider>(context, listen: false);
      final tenantProvider = Provider.of<TenantProvider>(
        context,
        listen: false,
      );

      final waterUsage = double.parse(_waterUsageController.text);
      final electricityUsage = double.parse(_electricityUsageController.text);

      // Get tenant ID
      String? tenantId;
      if (_selectedUnitId != null) {
        final tenant = tenantProvider.getTenantByUnitId(_selectedUnitId!);
        tenantId = tenant?.id;
      }

      if (_isEditing && _rentRecord != null) {
        final updatedRecord = RentRecord(
          id: _rentRecord!.id,
          unitId: _selectedUnitId!,
          tenantId: tenantId,
          month: _selectedMonth,
          baseRent: _baseRent,
          waterUsage: waterUsage,
          previousWaterUsage: _previousWaterUsage,
          waterRate: _waterRate,
          electricityUsage: electricityUsage,
          previousElectricityUsage: _previousElectricityUsage,
          electricityRate: _electricityRate,
          managementFee: _managementFee,
          isPaid: _rentRecord!.isPaid,
          paidDate: _rentRecord!.paidDate,
        );

        await rentProvider.updateRentRecord(updatedRecord);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('租金记录已更新')));
          Navigator.pop(context);
        }
      } else {
        final newRecord = RentRecord(
          id: const Uuid().v4(),
          unitId: _selectedUnitId!,
          tenantId: tenantId,
          month: _selectedMonth,
          baseRent: _baseRent,
          waterUsage: waterUsage,
          previousWaterUsage: _previousWaterUsage,
          waterRate: _waterRate,
          electricityUsage: electricityUsage,
          previousElectricityUsage: _previousElectricityUsage,
          electricityRate: _electricityRate,
          managementFee: _managementFee,
          isPaid: false,
        );

        await rentProvider.addRentRecord(newRecord);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('租金记录已添加')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑租金记录' : '添加租金记录')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '选择房屋',
                  hintText: '请选择房屋',
                ),
                value: _selectedPropertyId,
                items:
                    propertyProvider.properties.map((property) {
                      return DropdownMenuItem<String>(
                        value: property.id,
                        child: Text(property.address),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyId = value;
                    _selectedUnitId = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择房屋';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '选择单元',
                  hintText: '请选择单元',
                ),
                value: _selectedUnitId,
                items:
                    _selectedPropertyId != null
                        ? propertyProvider
                                .getPropertyById(_selectedPropertyId!)
                                ?.units
                                .map((unit) {
                                  return DropdownMenuItem<String>(
                                    value: unit.id,
                                    child: Text(unit.unitNumber),
                                  );
                                })
                                .toList() ??
                            []
                        : [],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                  _updateUnitInfo();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请选择单元';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectMonth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '月份',
                  hintText: '请选择月份',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('yyyy年MM月').format(_selectedMonth)),
                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '费用信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('基础租金')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_baseRent.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('上月水表读数')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${_previousWaterUsage.toStringAsFixed(2)} 吨',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('本月水表读数')),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _waterUsageController,
                            decoration: const InputDecoration(
                              hintText: '请输入本月水表读数',
                              suffixText: '吨',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入本月水表读数';
                              }
                              if (double.tryParse(value) == null) {
                                return '请输入有效的数字';
                              }
                              if (double.parse(value) < _previousWaterUsage) {
                                return '本月读数不能小于上月读数';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('水费单价')),
                        Expanded(
                          flex: 3,
                          child: Text('¥${_waterRate.toStringAsFixed(2)}/吨'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('水费小计')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_calculateWaterFee().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('上月电表读数')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '${_previousElectricityUsage.toStringAsFixed(2)} 度',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('本月电表读数')),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _electricityUsageController,
                            decoration: const InputDecoration(
                              hintText: '请输入本月电表读数',
                              suffixText: '度',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入本月电表读数';
                              }
                              if (double.tryParse(value) == null) {
                                return '请输入有效的数字';
                              }
                              if (double.parse(value) <
                                  _previousElectricityUsage) {
                                return '本月读数不能小于上月读数';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('电费单价')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_electricityRate.toStringAsFixed(2)}/度',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('电费小计')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_calculateElectricityFee().toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(flex: 2, child: Text('管理费')),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_managementFee.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            '总计',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '¥${_calculateTotalRent().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveRentRecord,
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
                          title: const Text('删除租金记录'),
                          content: const Text('确定要删除这个租金记录吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final rentProvider = Provider.of<RentProvider>(
                                  context,
                                  listen: false,
                                );
                                await rentProvider.deleteRentRecord(
                                  widget.rentRecordId!,
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(
                                    context,
                                  ); // Go back to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('租金记录已删除')),
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
                child: const Text('删除租金记录'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
