import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/customer_directory_controller.dart';

class CustomerDirectoryScreen extends StatelessWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CustomerDirectoryController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offAllNamed('/home'),
        ),
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.reload,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText:
                          'Search by name, email, website, industry',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (v) => c.searchQuery.value = v,
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => Text(
                      '${c.filtered.length} of ${c.orgs.length}',
                      style: const TextStyle(color: Colors.white60),
                    )),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (c.loading.value && c.orgs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.error.value != null) {
                return Center(
                  child: Text(c.error.value!,
                      style: const TextStyle(color: Colors.redAccent)),
                );
              }
              final rows = c.filtered;
              if (rows.isEmpty) {
                return const Center(
                    child: Text('No customers match your search.'));
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable2(
                  columnSpacing: 20,
                  horizontalMargin: 12,
                  minWidth: 900,
                  columns: const [
                    DataColumn2(label: Text('Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('Industry'), size: ColumnSize.S),
                    DataColumn2(label: Text('Website'), size: ColumnSize.M),
                    DataColumn2(label: Text('Email'), size: ColumnSize.L),
                    DataColumn2(
                        label: Text('Employees'),
                        size: ColumnSize.S,
                        numeric: true),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Created'), size: ColumnSize.M),
                  ],
                  rows: rows
                      .map((o) => DataRow2(
                            onTap: () =>
                                Get.toNamed('/customers/${o.id}'),
                            cells: [
                              DataCell(Text(o.name,
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(o.industry ?? '—',
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(o.website ?? '—',
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(o.email ?? '—',
                                  overflow: TextOverflow.ellipsis)),
                              DataCell(Text(
                                  o.numberOfEmployees?.toString() ?? '—')),
                              DataCell(_StatusChip(status: o.status)),
                              DataCell(Text(o.createdAt != null
                                  ? DateFormat.yMMMd().format(o.createdAt!)
                                  : '—')),
                            ],
                          ))
                      .toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String? status;
  const _StatusChip({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status;
    if (s == null || s.isEmpty) return const Text('—');
    Color bg;
    switch (s.toLowerCase()) {
      case 'active':
        bg = Colors.green.withValues(alpha: 0.2);
        break;
      case 'disabled':
      case 'suspended':
        bg = Colors.red.withValues(alpha: 0.2);
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(s, style: const TextStyle(fontSize: 11)),
    );
  }
}
