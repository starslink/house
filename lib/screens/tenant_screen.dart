import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/property_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/tenant_detail_screen.dart';
import '../screens/tenant_form_screen.dart';

class TenantScreen extends StatelessWidget {
  const TenantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('租客管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TenantFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TenantProvider, PropertyProvider>(
        builder: (context, tenantProvider, propertyProvider, child) {
          if (tenantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (tenantProvider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('暂无租客信息'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TenantFormScreen(),
                        ),
                      );
                    },
                    child: const Text('添加租客'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tenantProvider.tenants.length,
            itemBuilder: (context, index) {
              final tenant = tenantProvider.tenants[index];
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

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text(
                      tenant.name.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(tenant.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('电话: ${tenant.phone}'),
                      Text('单元: $unitInfo'),
                      Text(
                        '租约: ${tenant.leaseStatus}',
                        style: TextStyle(
                          color:
                              tenant.leaseStatus == '租约中'
                                  ? Colors.black
                                  : Colors.grey,
                          fontWeight:
                              tenant.leaseStatus == '租约中'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TenantFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
