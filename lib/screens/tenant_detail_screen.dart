import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tenant_provider.dart';
import '../providers/property_provider.dart';
import '../providers/rent_provider.dart';
import '../models/tenant.dart';
import '../screens/tenant_form_screen.dart';
import '../screens/contract_form_screen.dart';
import '../screens/contract_detail_screen.dart';
import '../screens/rent_detail_screen.dart';
import 'package:intl/intl.dart';

class TenantDetailScreen extends StatelessWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('租客信息不存在'));
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTenantInfo(context, tenant, unitInfo),
                const SizedBox(height: 24),
                _buildLeaseInfo(context, tenant),
                const SizedBox(height: 24),
                _buildContractsSection(context, tenant),
                const SizedBox(height: 24),
                _buildRentRecordsSection(context, rentRecords),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTenantInfo(
    BuildContext context,
    Tenant tenant,
    String unitInfo,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '基本信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('姓名', tenant.name),
            _buildInfoRow('电话', tenant.phone),
            _buildInfoRow('身份证号', tenant.idNumber),
            _buildInfoRow('单元', unitInfo),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaseInfo(BuildContext context, Tenant tenant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '租约信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
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
                  child: const Text('编辑租约'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('租约状态', tenant.leaseStatus),
            _buildInfoRow('租约期限', tenant.formattedLeaseDate),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsSection(BuildContext context, Tenant tenant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '合同管理',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('添加合同'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ContractFormScreen(tenantId: tenant.id),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tenant.contracts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('暂无合同')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tenant.contracts.length,
                itemBuilder: (context, index) {
                  final contract = tenant.contracts[index];
                  final dateFormat = DateFormat('yyyy-MM-dd');

                  return ListTile(
                    title: Text('合同 #${index + 1}'),
                    subtitle: Text(
                      '创建日期: ${dateFormat.format(contract.createdAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
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
    );
  }

  Widget _buildRentRecordsSection(
    BuildContext context,
    List<dynamic> rentRecords,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '租金记录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (rentRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('暂无租金记录')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rentRecords.length,
                itemBuilder: (context, index) {
                  final record = rentRecords[index];

                  return ListTile(
                    title: Text(record.formattedMonth),
                    subtitle: Text(
                      '总计: ¥${record.totalRent.toStringAsFixed(2)}',
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
                            color: record.isPaid ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            record.isPaid ? '已付款' : '未付款',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  RentDetailScreen(rentRecordId: record.id),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
