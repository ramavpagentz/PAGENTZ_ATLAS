import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../customers/models/organization_model.dart';
import '../../customers/services/customer_service.dart';
import '../models/ticket_models.dart';
import '../services/ticket_service.dart';

class NewTicketModal extends StatefulWidget {
  /// Optional: preselect an org. When provided, the org field is locked.
  final String? lockedOrgId;
  final String? lockedOrgName;

  const NewTicketModal({super.key, this.lockedOrgId, this.lockedOrgName});

  @override
  State<NewTicketModal> createState() => _NewTicketModalState();
}

class _NewTicketModalState extends State<NewTicketModal> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _reporterEmailCtl = TextEditingController();
  Organization? _org;
  List<Organization> _orgs = const [];
  TicketPriority _priority = TicketPriority.normal;
  bool _loadingOrgs = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.lockedOrgId == null) {
      _loadOrgs();
    }
  }

  Future<void> _loadOrgs() async {
    setState(() => _loadingOrgs = true);
    try {
      final list = await CustomerService.instance.listOrganizations();
      if (!mounted) return;
      setState(() {
        _orgs = list;
        _loadingOrgs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOrgs = false;
        _error = 'Failed to load orgs: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final orgId = widget.lockedOrgId ?? _org?.id;
      final orgName = widget.lockedOrgName ?? _org?.name;
      final t = await TicketService.instance.createTicket(
        subject: _subjectCtl.text.trim(),
        description: _descCtl.text.trim(),
        priority: _priority,
        orgId: orgId,
        orgName: orgName,
        reportedByEmail: _reporterEmailCtl.text.trim().isEmpty
            ? null
            : _reporterEmailCtl.text.trim(),
      );
      if (!mounted) return;
      Get.back<SupportTicket>(result: t);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New support ticket'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _subjectCtl,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Subject is required (min 3 chars)'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 10)
                      ? 'Describe the issue (min 10 chars)'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TicketPriority>(
                        initialValue: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: TicketPriority.values
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ))
                            .toList(),
                        onChanged: (p) =>
                            setState(() => _priority = p ?? TicketPriority.normal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: widget.lockedOrgId != null
                          ? InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Customer',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(widget.lockedOrgName ??
                                  widget.lockedOrgId!),
                            )
                          : DropdownButtonFormField<Organization>(
                              initialValue: _org,
                              decoration: const InputDecoration(
                                labelText: 'Customer (optional)',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<Organization>(
                                    value: null, child: Text('— none —')),
                                ..._orgs.map((o) => DropdownMenuItem(
                                      value: o,
                                      child: Text(o.name,
                                          overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: _loadingOrgs
                                  ? null
                                  : (o) => setState(() => _org = o),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reporterEmailCtl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Reporter email (optional)',
                    hintText: 'customer contact that reported the issue',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Get.back<void>(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create ticket'),
        ),
      ],
    );
  }
}
