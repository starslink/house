import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/rent.dart';
import '../providers/property_provider.dart';
import '../providers/rent_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/rent_form_screen.dart';

class RentDetailScreen extends StatelessWidget {
  final String rentRecordId;

  const RentDetailScreen({super.key, required this.rentRecordId});

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('租金记录不存在'));
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              record.formattedMonth,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    record.isPaid
                                        ? Colors.grey[800]
                                        : Colors.grey[400],
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
                          ],
                        ),
                        const Divider(height: 24),
                        if (property != null) Text('房屋地址: ${property.address}'),
                        if (unit != null) Text('单元号: ${unit.unitNumber}'),
                        if (tenant != null) Text('租客: ${tenant.name}'),
                        if (record.isPaid && record.paidDate != null)
                          Text('付款日期: ${dateFormat.format(record.paidDate!)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '费用明细',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildFeeRow(
                          '基础租金',
                          '¥${record.baseRent.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        _buildFeeRow(
                          '水费',
                          '¥${record.waterFee.toStringAsFixed(2)}',
                          detail:
                              '(${record.previousWaterUsage.toStringAsFixed(2)} → ${record.waterUsage.toStringAsFixed(2)} 吨, ¥${record.waterRate.toStringAsFixed(2)}/吨)',
                        ),
                        const SizedBox(height: 8),
                        _buildFeeRow(
                          '电费',
                          '¥${record.electricityFee.toStringAsFixed(2)}',
                          detail:
                              '(${record.previousElectricityUsage.toStringAsFixed(2)} → ${record.electricityUsage.toStringAsFixed(2)} 度, ¥${record.electricityRate.toStringAsFixed(2)}/度)',
                        ),
                        const SizedBox(height: 8),
                        _buildFeeRow(
                          '管理费',
                          '¥${record.managementFee.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '总计',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '¥${record.totalRent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!record.isPaid)
                  ElevatedButton(
                    onPressed: () async {
                      await rentProvider.markAsPaid(rentRecordId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已标记为已付款')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: const Text('标记为已付款'),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {String? detail}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (detail != null)
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printRentInvoice(
    BuildContext context,
    RentRecord record,
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
              pw.Center(
                child: pw.Text(
                  '租金收据',
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '收据编号: ${record.id.substring(0, 8)}',
                  ),
                  pw.Text(
                    '日期: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                '租金月份: ${record.formattedMonth}',
              ),
              pw.SizedBox(height: 10),
              pw.Text('房屋地址: ${property?.address ?? '未知'}'),
              pw.Text('单元号: ${unit?.unitNumber ?? '未知'}'),
              pw.Text('租客: ${tenant?.name ?? '未知'}'),
              pw.SizedBox(height: 20),
              pw.Text(
                '费用明细:',
              ),
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
                        child: pw.Text(
                          '项目',
                          // style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '金额',
                          // style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '备注',
                          // style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
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
                          // style: const pw.TextStyle(fontSize: 10),
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
                          // style: const pw.TextStyle(fontSize: 10),
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
                        child: pw.Text(
                          '总计',
                          // style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '¥${record.totalRent.toStringAsFixed(2)}',
                          // style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
              pw.SizedBox(height: 40),
              // pw.Row(
              //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              //   children: [
              //     pw.Column(
              //       crossAxisAlignment: pw.CrossAxisAlignment.start,
              //       children: [
              //         pw.Text('收款人签名:'),
              //         pw.SizedBox(height: 20),
              //         pw.Container(
              //           width: 150,
              //           height: 1,
              //           color: PdfColors.black,
              //         ),
              //       ],
              //     ),
              //     pw.Column(
              //       crossAxisAlignment: pw.CrossAxisAlignment.start,
              //       children: [
              //         pw.Text('付款人签名:'),
              //         pw.SizedBox(height: 20),
              //         pw.Container(
              //           width: 150,
              //           height: 1,
              //           color: PdfColors.black,
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
              pw.SizedBox(height: 40),
              // pw.Center(
              //   child: pw.Text(
              //     '感谢您的付款!',
              //     style: const pw.TextStyle(
              //       fontSize: 12,
              //       color: PdfColors.grey700,
              //     ),
              //   ),
              // ),
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
