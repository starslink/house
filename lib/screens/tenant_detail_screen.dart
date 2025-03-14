import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/property_provider.dart';
import '../providers/rent_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/contract_detail_screen.dart';
import '../screens/contract_form_screen.dart';
import '../screens/rent_detail_screen.dart';
import '../screens/tenant_form_screen.dart';

class TenantDetailScreen extends StatelessWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('租客详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TenantFormScreen(tenantId: tenantId),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer3<TenantProvider, PropertyProvider, RentProvider>(
        builder: (
          context,
          tenantProvider,
          propertyProvider,
          rentProvider,
          child,
        ) {
          final tenant = tenantProvider.getTenantById(tenantId);

          if (tenant == null) {
            return Center(
              child: Text(
                '租客信息不存在',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }

          String unitInfo = '无分配单元';
          if (tenant.unitId != null) {
            final property = propertyProvider.getPropertyByUnitId(
              tenant.unitId!,
            );
            final unit = propertyProvider.getUnitById(
              property?.id ?? '',
              tenant.unitId!,
            );

            if (property != null && unit != null) {
              unitInfo = '${property.address} - ${unit.unitNumber}';
            }
          }

          final rentRecords =
              tenant.unitId != null
                  ? rentProvider.getRentRecordsByUnitId(tenant.unitId!)
                  : [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 租客基本信息卡片
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                tenant.name.substring(0, 1),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tenant.phone,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getLeaseStatusColor(tenant.leaseStatus),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tenant.leaseStatus,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      _buildInfoRow(context, '姓名', tenant.name),
                      _buildInfoRow(context, '电话', tenant.phone),
                      _buildInfoRow(context, '身份证号', tenant.idNumber),
                      _buildInfoRow(context, '单元', unitInfo),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 租约信息卡片
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '租约信息',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑租约'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TenantFormScreen(
                                        tenantId: tenant.id,
                                        showLeaseSection: true,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(context, '租约状态', tenant.leaseStatus),
                      _buildInfoRow(context, '租约期限', tenant.formattedLeaseDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 合同管理卡片
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '合同管理',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('添加合同'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ContractFormScreen(
                                        tenantId: tenant.id,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (tenant.contracts.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无合同',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tenant.contracts.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final contract = tenant.contracts[index];
                            final dateFormat = DateFormat('yyyy-MM-dd');

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                '合同 #${index + 1}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '创建日期: ${dateFormat.format(contract.createdAt)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.primary,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ContractDetailScreen(
                                          tenantId: tenant.id,
                                          contractId: contract.id,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 租金记录卡片
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '租金记录',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      if (rentRecords.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无租金记录',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onBackground
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rentRecords.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final record = rentRecords[index];

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                record.formattedMonth,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '总计: ¥${record.totalRent.toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          record.isPaid
                                              ? Colors.green
                                              : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      record.isPaid ? '已付款' : '未付款',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => RentDetailScreen(
                                          rentRecordId: record.id,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLeaseStatusColor(String status) {
    switch (status) {
      case '租约中':
        return Colors.green;
      case '未开始':
        return Colors.orange;
      case '已结束':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
