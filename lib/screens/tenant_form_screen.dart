import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/property_provider.dart';
import '../models/tenant.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TenantFormScreen extends StatefulWidget {
  final String? tenantId;
  final bool showLeaseSection;

  const TenantFormScreen({
    super.key,
    this.tenantId,
    this.showLeaseSection = false,
  });

  @override
  State<TenantFormScreen> createState() => _TenantFormScreenState();
}

class _TenantFormScreenState extends State<TenantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();

  bool _isEditing = false;
  Tenant? _tenant;
  String? _selectedUnitId;
  DateTime? _leaseStartDate;
  DateTime? _leaseEndDate;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.tenantId != null;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTenant();
      });
    }
  }

  void _loadTenant() {
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    _tenant = tenantProvider.getTenantById(widget.tenantId!);

    if (_tenant != null) {
      _nameController.text = _tenant!.name;
      _phoneController.text = _tenant!.phone;
      _idNumberController.text = _tenant!.idNumber;
      _selectedUnitId = _tenant!.unitId;
      _leaseStartDate = _tenant!.leaseStartDate;
      _leaseEndDate = _tenant!.leaseEndDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectLeaseStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaseStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _leaseStartDate) {
      setState(() {
        _leaseStartDate = picked;
      });
    }
  }

  Future<void> _selectLeaseEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _leaseEndDate ??
          (_leaseStartDate != null
              ? _leaseStartDate!.add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _leaseEndDate) {
      setState(() {
        _leaseEndDate = picked;
      });
    }
  }

  Future<void> _saveTenant() async {
    if (_formKey.currentState!.validate()) {
      final tenantProvider = Provider.of<TenantProvider>(
        context,
        listen: false,
      );

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final idNumber = _idNumberController.text.trim();

      if (_isEditing && _tenant != null) {
        final updatedTenant = Tenant(
          id: _tenant!.id,
          name: name,
          phone: phone,
          idNumber: idNumber,
          unitId: _selectedUnitId,
          leaseStartDate: _leaseStartDate,
          leaseEndDate: _leaseEndDate,
          contracts: _tenant!.contracts,
        );

        await tenantProvider.updateTenant(updatedTenant);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('租客信息已更新')));
          Navigator.pop(context);
        }
      } else {
        final newTenant = Tenant(
          id: const Uuid().v4(),
          name: name,
          phone: phone,
          idNumber: idNumber,
          unitId: _selectedUnitId,
          leaseStartDate: _leaseStartDate,
          leaseEndDate: _leaseEndDate,
          contracts: [],
        );

        await tenantProvider.addTenant(newTenant);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('租客已添加')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final allUnits = propertyProvider.getAllUnits();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showLeaseSection ? '编辑租约' : (_isEditing ? '编辑租客' : '添加租客'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!widget.showLeaseSection) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  hintText: '请输入租客姓名',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '电话',
                  hintText: '请输入租客电话',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入电话';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(
                  labelText: '身份证号',
                  hintText: '请输入租客身份证号',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入身份证号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '分配单元',
                  hintText: '请选择要分配的单元',
                ),
                value: _selectedUnitId,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('无分配单元'),
                  ),
                  ...allUnits.map((unit) {
                    final property = propertyProvider.getPropertyByUnitId(
                      unit.id,
                    );
                    return DropdownMenuItem<String>(
                      value: unit.id,
                      child: Text(
                        '${property?.address ?? ''} - ${unit.unitNumber}',
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedUnitId = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              '租约信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectLeaseStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '租约开始日期',
                        hintText: '请选择',
                      ),
                      child: Text(
                        _leaseStartDate != null
                            ? DateFormat('yyyy-MM-dd').format(_leaseStartDate!)
                            : '请选择',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectLeaseEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '租约结束日期',
                        hintText: '请选择',
                      ),
                      child: Text(
                        _leaseEndDate != null
                            ? DateFormat('yyyy-MM-dd').format(_leaseEndDate!)
                            : '请选择',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveTenant,
              child: Text(
                widget.showLeaseSection ? '更新租约' : (_isEditing ? '更新' : '添加'),
              ),
            ),
            if (_isEditing && !widget.showLeaseSection) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('删除租客'),
                          content: const Text('确定要删除这个租客吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final tenantProvider =
                                    Provider.of<TenantProvider>(
                                      context,
                                      listen: false,
                                    );
                                await tenantProvider.deleteTenant(
                                  widget.tenantId!,
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Close dialog
                                  Navigator.pop(
                                    context,
                                  ); // Go back to previous screen
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('租客已删除')),
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
                child: const Text('删除租客'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
