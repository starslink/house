import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/tenant.dart';
import '../providers/tenant_provider.dart';
import '../screens/contract_form_screen.dart';

class ContractDetailScreen extends StatelessWidget {
  final String tenantId;
  final String contractId;

  const ContractDetailScreen({
    super.key,
    required this.tenantId,
    required this.contractId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('合同详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ContractFormScreen(
                        tenantId: tenantId,
                        contractId: contractId,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              final tenantProvider = Provider.of<TenantProvider>(
                context,
                listen: false,
              );
              final tenant = tenantProvider.getTenantById(tenantId);
              final contract = tenant?.contracts.firstWhere(
                (c) => c.id == contractId,
                orElse:
                    () => Contract(
                      id: '',
                      tenantId: '',
                      content: '',
                      createdAt: DateTime.now(),
                    ),
              );

              if (contract != null && contract.id.isNotEmpty) {
                _printContract(context, tenant!, contract);
              }
            },
          ),
        ],
      ),
      body: Consumer<TenantProvider>(
        builder: (context, tenantProvider, child) {
          final tenant = tenantProvider.getTenantById(tenantId);

          if (tenant == null) {
            return const Center(child: Text('租客信息不存在'));
          }

          final contract = tenant.contracts.firstWhere(
            (c) => c.id == contractId,
            orElse:
                () => Contract(
                  id: '',
                  tenantId: '',
                  content: '',
                  createdAt: DateTime.now(),
                ),
          );

          if (contract.id.isEmpty) {
            return const Center(child: Text('合同信息不存在'));
          }

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
                            const Text(
                              '合同信息',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '创建日期: ${dateFormat.format(contract.createdAt)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          '租客: ${tenant.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('电话: ${tenant.phone}'),
                        Text('身份证号: ${tenant.idNumber}'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '合同内容',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.print),
                              label: const Text('打印'),
                              onPressed: () {
                                _printContract(context, tenant, contract);
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(contract.content),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _printContract(
    BuildContext context,
    Tenant tenant,
    Contract contract,
  ) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(
          await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf'),
        ),
      ),
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(child: pw.Text('房屋租赁合同')),
            // pw.SizedBox(height: 20),
            // pw.Text('租客信息:'),
            // pw.SizedBox(height: 5),
            // pw.Text('姓名: ${tenant.name}'),
            // pw.Text('电话: ${tenant.phone}'),
            // pw.Text('身份证号: ${tenant.idNumber}'),
            // pw.SizedBox(height: 20),
            // pw.Text('合同内容:'),
            // pw.SizedBox(height: 10),
            pw.Paragraph(text: contract.content),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
