import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/customer_detail_controller.dart';
import '../models/organization_model.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orgId = Get.parameters['orgId'] ?? '';
    if (orgId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Missing orgId')));
    }
    final c = Get.put(CustomerDetailController(orgId), tag: orgId);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.offNamed('/customers'),
          ),
          title: Obx(() => Text(c.org.value?.name ?? 'Loading…')),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: c.load),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Members'),
              Tab(text: 'Activity'),
              Tab(text: 'Tickets'),
            ],
          ),
        ),
        body: Obx(() {
          if (c.loading.value && c.org.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c.error.value != null) {
            return Center(
                child: Text(c.error.value!,
                    style: const TextStyle(color: Colors.redAccent)));
          }
          final o = c.org.value;
          if (o == null) return const Center(child: Text('Not found'));
          return TabBarView(
            children: [
              _OverviewTab(org: o, memberCount: c.members.length),
              _MembersTab(members: c.members),
              const Center(
                child: Text(
                  'Phase 3 coming: activity timeline (customer-side logs from Postgres + staff actions from audit log, merged).',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ),
              const Center(
                child: Text(
                  'Phase 5 coming: support tickets scoped to this customer.',
                  style: TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Organization org;
  final int memberCount;
  const _OverviewTab({required this.org, required this.memberCount});

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(k,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12)),
          ),
          Expanded(child: SelectableText(v ?? '—')),
        ],
      ),
    );
  }

  String _fmt(DateTime? t) =>
      t == null ? '—' : DateFormat.yMMMd().add_jm().format(t.toLocal());

  String _phone(Organization o) {
    if (o.phone == null) return '—';
    if (o.phoneExtension == null || o.phoneExtension!.isEmpty) return o.phone!;
    return '${o.phone}  ext ${o.phoneExtension}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(org.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                SelectableText(
                  'ID: ${org.id}',
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
                const Divider(height: 32),
                _kv('Email', org.email),
                _kv('Phone', _phone(org)),
                _kv('Website', org.website),
                _kv('Industry', org.industry),
                _kv('Employees', org.numberOfEmployees?.toString()),
                _kv('Members (Atlas-visible)', memberCount.toString()),
                _kv('Address', org.address),
                _kv('Owner UID', org.ownerUid),
                _kv('Status', org.status),
                _kv('Created', _fmt(org.createdAt)),
                _kv('Updated', _fmt(org.updatedAt)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final RxList<OrgMember> members;
  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (members.isEmpty) {
        return const Center(child: Text('No members.'));
      }
      return Padding(
        padding: const EdgeInsets.all(16),
        child: DataTable2(
          columnSpacing: 18,
          horizontalMargin: 10,
          minWidth: 760,
          columns: const [
            DataColumn2(label: Text('Email'), size: ColumnSize.L),
            DataColumn2(label: Text('Role'), size: ColumnSize.S),
            DataColumn2(label: Text('Status'), size: ColumnSize.S),
            DataColumn2(label: Text('User UID'), size: ColumnSize.M),
            DataColumn2(label: Text('Accepted'), size: ColumnSize.S),
          ],
          rows: members
              .map((m) => DataRow2(cells: [
                    DataCell(Text(m.email ?? '—',
                        overflow: TextOverflow.ellipsis)),
                    DataCell(Text(m.role ?? '—')),
                    DataCell(Text(m.status ?? '—')),
                    DataCell(SelectableText(
                      m.userId ?? '—',
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace'),
                    )),
                    DataCell(Text(m.isAccepted ? 'Yes' : 'No')),
                  ]))
              .toList(),
        ),
      );
    });
  }
}
