import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/customer_org_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/ticket_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';

Future<void> showCreateTicketDialog(BuildContext context, CustomerOrg org) {
  return showDialog(
    context: context,
    builder: (_) => _CreateTicketDialog(org: org),
  );
}

class _CreateTicketDialog extends StatefulWidget {
  final CustomerOrg org;
  const _CreateTicketDialog({required this.org});

  @override
  State<_CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<_CreateTicketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final _reporterEmail = TextEditingController();
  TicketPriority _priority = TicketPriority.normal;
  bool _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    _reporterEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AtlasColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.support_agent,
                        color: AtlasColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New support ticket',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AtlasColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.org.name,
                            style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _Label('Subject'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _subject,
                  decoration: const InputDecoration(
                    hintText: 'Short summary of the issue',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _Label('Reporter email (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _reporterEmail,
                  decoration: const InputDecoration(
                    hintText: 'customer@example.com',
                  ),
                ),
                const SizedBox(height: 14),

                _Label('Priority'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: TicketPriority.values.map((p) {
                    final sel = _priority == p;
                    return ChoiceChip(
                      label: Text(p.label),
                      selected: sel,
                      selectedColor: AtlasColors.accent,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : AtlasColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _priority = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                _Label('Description'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Steps to reproduce, expected vs actual, links…',
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add, size: 16),
                        label: Text(_saving ? 'Creating…' : 'Create ticket'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final id = await TicketService.instance.createTicket(
      orgId: widget.org.id,
      orgName: widget.org.name,
      subject: _subject.text,
      description: _description.text,
      priority: _priority,
      reportedByEmail:
          _reporterEmail.text.trim().isEmpty ? null : _reporterEmail.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    Get.toNamed(AtlasRoutes.ticketDetail, arguments: id);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AtlasColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}
