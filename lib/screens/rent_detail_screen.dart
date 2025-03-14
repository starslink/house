import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../providers/property_provider.dart';
import '../providers/rent_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/rent_form_screen.dart';

class RentDetailScreen extends StatelessWidget {
  final String rentRecordId;

  const RentDetailScreen({super.key, required this.rentRecordId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('租金详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => RentFormScreen(rentRecordId: rentRecordId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final rentProvider = Provider.of<RentProvider>(
                context,
                listen: false,
              );
              final propertyProvider = Provider.of<PropertyProvider>(
                context,
                listen: false,
              );
              final tenantProvider = Provider.of<TenantProvider>(
                context,
                listen: false,
              );

              final record = rentProvider.getRentRecordById(rentRecordId);
              if (record != null) {
                final property = propertyProvider.getPropertyByUnitId(
                  record.unitId,
                );
                final unit = propertyProvider.getUnitById(
                  property?.id ?? '',
                  record.unitId,
                );
                final tenant =
                    record.tenantId != null
                        ? tenantProvider.getTenantById(record.tenantId!)
                        : null;

                _printRentInvoice(context, record, property, unit, tenant);
              }
            },
          ),
        ],
      ),
      body: Consumer3<RentProvider, PropertyProvider, TenantProvider>(
        builder: (
          context,
          rentProvider,
          propertyProvider,
          tenantProvider,
          child,
        ) {
          final record = rentProvider.getRentRecordById(rentRecordId);

          if (record == null) {
            return Center(
              child: Text(
                '租金记录不存在',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }

          final property = propertyProvider.getPropertyByUnitId(record.unitId);
          final unit = propertyProvider.getUnitById(
            property?.id ?? '',
            record.unitId,
          );
          final tenant =
              record.tenantId != null
                  ? tenantProvider.getTenantById(record.tenantId!)
                  : null;

          final dateFormat = DateFormat('yyyy-MM-dd');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 基本信息卡片
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  record.formattedMonth,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
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
                              color:
                                  record.isPaid ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              record.isPaid ? '已付款' : '未付款',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      if (property != null)
                        _buildInfoRow(context, '房屋地址', property.address),
                      if (unit != null)
                        _buildInfoRow(context, '单元号', unit.unitNumber),
                      if (tenant != null)
                        _buildInfoRow(context, '租客', tenant.name),
                      if (record.isPaid && record.paidDate != null)
                        _buildInfoRow(
                          context,
                          '付款日期',
                          dateFormat.format(record.paidDate!),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 费用明细卡片
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '费用明细',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 30),

                      // 基础租金
                      _buildFeeRow(
                        context,
                        '基础租金',
                        '¥${record.baseRent.toStringAsFixed(2)}',
                      ),

                      const SizedBox(height: 16),

                      // 水费
                      _buildFeeRow(
                        context,
                        '水费',
                        '¥${record.waterFee.toStringAsFixed(2)}',
                        detail:
                            '(${record.previousWaterUsage.toStringAsFixed(2)} → ${record.waterUsage.toStringAsFixed(2)} 吨, ¥${record.waterRate.toStringAsFixed(2)}/吨)',
                      ),

                      const SizedBox(height: 16),

                      // 电费
                      _buildFeeRow(
                        context,
                        '电费',
                        '¥${record.electricityFee.toStringAsFixed(2)}',
                        detail:
                            '(${record.previousElectricityUsage.toStringAsFixed(2)} → ${record.electricityUsage.toStringAsFixed(2)} 度, ¥${record.electricityRate.toStringAsFixed(2)}/度)',
                      ),

                      const SizedBox(height: 16),

                      // 管理费
                      _buildFeeRow(
                        context,
                        '管理费',
                        '¥${record.managementFee.toStringAsFixed(2)}',
                      ),

                      const Divider(height: 30),

                      // 总计
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('总计'),
                            Text('¥${record.totalRent.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 操作按钮
              if (!record.isPaid)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('标记为已付款'),
                  onPressed: () async {
                    await rentProvider.markAsPaid(rentRecordId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('已标记为已付款'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('打印租金单'),
                onPressed: () {
                  _printRentInvoice(context, record, property, unit, tenant);
                },
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

  Widget _buildFeeRow(
    BuildContext context,
    String label,
    String value, {
    String? detail,
  }) {
    final theme = Theme.of(context);

    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printRentInvoice(
    BuildContext context,
    dynamic record,
    dynamic property,
    dynamic unit,
    dynamic tenant,
  ) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'),
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('租金收据')),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('收据编号: ${record.id.substring(0, 8)}'),
                  pw.Text(
                    '日期: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('租金月份: ${record.formattedMonth}'),
              pw.SizedBox(height: 10),
              pw.Text('房屋地址: ${property?.address ?? '未知'}'),
              pw.Text('单元号: ${unit?.unitNumber ?? '未知'}'),
              pw.Text('租客: ${tenant?.name ?? '未知'}'),
              pw.SizedBox(height: 20),
              pw.Text('费用明细:'),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('项目'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('金额'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('备注'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('基础租金'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.baseRent.toStringAsFixed(2)}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('水费'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.waterFee.toStringAsFixed(2)}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${record.previousWaterUsage.toStringAsFixed(2)} → ${record.waterUsage.toStringAsFixed(2)} 吨, ¥${record.waterRate.toStringAsFixed(2)}/吨',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('电费'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.electricityFee.toStringAsFixed(2)}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${record.previousElectricityUsage.toStringAsFixed(2)} → ${record.electricityUsage.toStringAsFixed(2)} 度, ¥${record.electricityRate.toStringAsFixed(2)}/度',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('管理费'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.managementFee.toStringAsFixed(2)}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('总计'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.totalRent.toStringAsFixed(2)}',
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
