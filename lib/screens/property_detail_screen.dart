import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../models/property.dart';
import '../screens/property_form_screen.dart';
import '../screens/unit_form_screen.dart';
import '../screens/tenant_detail_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房屋详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PropertyFormScreen(propertyId: propertyId),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<PropertyProvider, TenantProvider>(
        builder: (context, propertyProvider, tenantProvider, child) {
          final property = propertyProvider.getPropertyById(propertyId);

          if (property == null) {
            return const Center(child: Text('房屋信息不存在'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyInfo(context, property),
                const SizedBox(height: 24),
                _buildUnitsSection(context, property, tenantProvider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UnitFormScreen(propertyId: propertyId),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPropertyInfo(BuildContext context, Property property) {
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
            _buildInfoRow('地址', property.address),
            _buildInfoRow('水费单价', '¥${property.waterRate}/吨'),
            _buildInfoRow('电费单价', '¥${property.electricityRate}/度'),
            _buildInfoRow('管理费', '¥${property.managementFee}/月'),
            _buildInfoRow('单元数量', '${property.units.length}'),
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

  Widget _buildUnitsSection(
    BuildContext context,
    Property property,
    TenantProvider tenantProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '单元列表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('添加单元'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UnitFormScreen(propertyId: propertyId),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: property.units.length,
          itemBuilder: (context, index) {
            final unit = property.units[index];
            final tenant = tenantProvider.getTenantByUnitId(unit.id);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '单元号: ${unit.unitNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('基础租金: ¥${unit.baseRent}/月'),
                    Text(
                      '租客: ${tenant != null ? tenant.name : "暂无"}',
                      style: TextStyle(
                        color: tenant != null ? Colors.black : Colors.grey,
                        fontWeight: tenant != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => UnitFormScreen(
                                  propertyId: propertyId,
                                  unitId: unit.id,
                                ),
                          ),
                        );
                      },
                    ),
                    if (tenant != null)
                      IconButton(
                        icon: const Icon(Icons.person, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      TenantDetailScreen(tenantId: tenant.id),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
