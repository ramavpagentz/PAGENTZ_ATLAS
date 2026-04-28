import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/models/customer_org_model.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/ticket_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';
import '../../../utils/routes.dart';
import '../../tickets/widgets/create_ticket_dialog.dart';
import '../../tickets/widgets/ticket_chips.dart';
import 'add_internal_note_dialog.dart';

/// Support tab — combines:
///   • Existing tickets list (was the inline `_TicketsTab` content)
///   • Internal notes timeline (new) — reads `ADDED_INTERNAL_NOTE` events
///     from `staff_audit_logs` filtered to this org, so notes any staff
///     member added show up across the team.
///
/// Spec section 13 also calls for "Recent Teams/Zoom sessions" which we
/// can't render today (no recordings collection). Once a `support_sessions`
/// collection exists this widget is the place to add that section.
class SupportTab extends StatelessWidget {
  final CustomerOrg org;
  const SupportTab({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TicketsCard(org: org),
        const SizedBox(height: AtlasSpace.lg),
        _InternalNotesCard(orgId: org.id, orgName: org.name),
      ],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Tickets card
// ───────────────────────────────────────────────────────────────────────

class _TicketsCard extends StatelessWidget {
  final CustomerOrg org;
  const _TicketsCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Support tickets for this organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => showCreateTicketDialog(context, org),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New ticket'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<List<SupportTicket>>(
            stream: TicketService.instance.watchForOrg(org.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final tickets = snap.data ?? const [];
              if (tickets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 32, color: AtlasColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No tickets yet for this organization.',
                          style: TextStyle(
                              color: AtlasColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: tickets.map((t) => _TicketRow(ticket: t)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Get.toNamed(AtlasRoutes.ticketDetail, arguments: ticket.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                ticket.ticketNumber,
                style: const TextStyle(
                  color: AtlasColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ticket.assignedToName != null)
                    Text(
                      'Assigned to ${ticket.assignedToName}',
                      style: const TextStyle(
                        color: AtlasColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PriorityPill(priority: ticket.priority),
            const SizedBox(width: 6),
            StatusPill(status: ticket.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 16, color: AtlasColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// Internal notes card
// ───────────────────────────────────────────────────────────────────────

class _InternalNotesCard extends StatelessWidget {
  final String orgId;
  final String orgName;
  const _InternalNotesCard({required this.orgId, required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Internal notes (staff-only)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AtlasColors.textPrimary,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => showAddInternalNoteDialog(
                    context: context,
                    orgId: orgId,
                    orgName: orgName,
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add note'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text(
              'Notes added via the "Add internal note" quick action. Staff-only — '
              'never shown to the customer. Stored in `staff_audit_logs`.',
              style: TextStyle(
                fontSize: 11.5,
                color: AtlasColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          const Divider(height: 1, color: AtlasColors.divider),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('staff_audit_logs')
                .where('action', isEqualTo: 'ADDED_INTERNAL_NOTE')
                .where('targetType', isEqualTo: 'org')
                .where('targetId', isEqualTo: orgId)
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load notes: ${snap.error}',
                    style: const TextStyle(
                        color: AtlasColors.danger, fontSize: 12),
                  ),
                );
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Text(
                      'No internal notes yet. Click "Add note" to record one.',
                      style: AtlasText.smallMuted,
                    ),
                  ),
                );
              }
              return Column(
                children: docs
                    .map((d) => _NoteRow(data: d.data()))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NoteRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy · HH:mm');
    final ts = data['timestamp'];
    final when = ts is Timestamp ? ts.toDate() : null;
    final author = (data['staffEmail'] as String?) ?? 'staff';
    final changes = data['changes'];
    final note = changes is Map ? (changes['note']?.toString() ?? '') : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                author,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF78350F),
                ),
              ),
              const Spacer(),
              if (when != null)
                Text(
                  fmt.format(when),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF92400E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            note.isEmpty ? '(empty note)' : note,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF78350F),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
