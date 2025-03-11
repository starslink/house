import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../models/tenant.dart';
import 'package:uuid/uuid.dart';

class ContractFormScreen extends StatefulWidget {
  final String tenantId;
  final String? contractId;

  const ContractFormScreen({
    super.key,
    required this.tenantId,
    this.contractId,
  });

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  bool _isEditing = false;
  Contract? _contract;
  Tenant? _tenant;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.contractId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    _tenant = tenantProvider.getTenantById(widget.tenantId);

    if (_tenant != null && _isEditing) {
      _contract = tenantProvider.getContractById(
        widget.tenantId,
        widget.contractId!,
      );

      if (_contract != null) {
        _contentController.text = _contract!.content;
      }
    } else if (_tenant != null) {
      // Load template for new contract
      _contentController.text = _generateContractTemplate();
    }
  }

  String _generateContractTemplate() {
    if (_tenant == null) return '';

    return '''
甲方（出租方）：____________
乙方（承租方）：${_tenant!.name}
身份证号：${_tenant!.idNumber}
联系电话：${_tenant!.phone}

根据《中华人民共和国合同法》及有关法律、法规的规定，甲乙双方在平等、自愿、协商一致的基础上，就房屋租赁事宜达成如下协议：

一、房屋基本情况
1. 房屋地址：__________________
2. 房屋面积：__________平方米
3. 房屋用途：居住

二、租赁期限
1. 租赁期自________年____月____日起至________年____月____日止，共____个月。

三、租金及支付方式
1. 月租金为人民币____元整。
2. 租金支付方式：按月/季度/半年/年支付。
3. 支付时间：每月/季/半年/年的____日前支付。

四、押金
1. 乙方应支付押金人民币____元整。
2. 合同期满或解除后，如乙方无违约行为，甲方应在乙方搬出并结清所有费用后____日内退还押金。

五、其他费用
1. 水费：由乙方按____元/吨支付。
2. 电费：由乙方按____元/度支付。
3. 物业管理费：由乙方按____元/月支付。
4. 其他费用：__________________

六、甲方的权利和义务
1. 按约定向乙方提供房屋。
2. 负责房屋的维修养护。
3. 不得擅自提高租金或者解除合同。

七、乙方的权利和义务
1. 按约定支付租金及其他费用。
2. 合理使用房屋及设施。
3. 不得擅自改变房屋结构或用途。
4. 不得擅自转租。

八、合同解除
1. 经双方协商一致，可以解除合同。
2. 因不可抗力导致合同无法履行的，可以解除合同。
3. 一方违约，另一方有权解除合同并要求赔偿损失。

九、违约责任
1. 甲方违约，应赔偿乙方损失并退还已收取的租金和押金。
2. 乙方违约，甲方有权没收押金并要求赔偿损失。

十、争议解决
因本合同引起的争议，双方应协商解决；协商不成的，可向房屋所在地人民法院提起诉讼。

十一、其他约定事项
__________________

本合同一式两份，甲乙双方各执一份，具有同等法律效力。
甲方（签字）：__________________    乙方（签字）：__________________
日期：________年____月____日       日期：________年____月____日
''';
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveContract() async {
    if (_formKey.currentState!.validate()) {
      final tenantProvider = Provider.of<TenantProvider>(
        context,
        listen: false,
      );

      final content = _contentController.text;

      if (_isEditing && _contract != null) {
        final updatedContract = Contract(
          id: _contract!.id,
          tenantId: widget.tenantId,
          content: content,
          createdAt: _contract!.createdAt,
        );

        await tenantProvider.updateContract(widget.tenantId, updatedContract);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('合同已更新')));
          Navigator.pop(context);
        }
      } else {
        final newContract = Contract(
          id: const Uuid().v4(),
          tenantId: widget.tenantId,
          content: content,
          createdAt: DateTime.now(),
        );

        await tenantProvider.addContract(widget.tenantId, newContract);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('合同已添加')));
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑合同' : '添加合同'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveContract),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '合同内容',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入合同内容';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveContract,
                      child: Text(_isEditing ? '更新' : '添加'),
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('删除合同'),
                            content: const Text('确定要删除这个合同吗？'),
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
                                  await tenantProvider.deleteContract(
                                    widget.tenantId,
                                    widget.contractId!,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(
                                      context,
                                    ); // Go back to previous screen
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('合同已删除')),
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
                  child: const Text('删除合同'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
