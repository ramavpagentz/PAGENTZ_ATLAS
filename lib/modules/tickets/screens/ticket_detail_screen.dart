import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/customer_service.dart';
import '../../../core/services/ticket_service.dart';
import '../../../modules/auth/controller/auth_controller.dart';
import '../../customers/controller/customer_controller.dart';
import '../../impersonation/widgets/start_impersonation_modal.dart';
import '../../../theme/atlas_colors.dart';
import '../../../utils/routes.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/ticket_chips.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ticketId = Get.arguments as String?;
    if (ticketId == null) {
      return AppShell(
        currentRoute: AtlasRoutes.tickets,
        pageTitle: 'Ticket',
        child: _NoTicket(),
      );
    }

    return AppShell(
      currentRoute: AtlasRoutes.tickets,
      pageTitle: 'Ticket',
      child: StreamBuilder<SupportTicket?>(
        stream: TicketService.instance.watchOne(ticketId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final ticket = snap.data;
          if (ticket == null) return _NoTicket();
          return _TicketBody(ticket: ticket);
        },
      ),
    );
  }
}

class _NoTicket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AtlasColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Ticket not found.',
            style: TextStyle(color: AtlasColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Get.offAllNamed(AtlasRoutes.tickets),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to queue'),
          ),
        ],
      ),
    );
  }
}

class _TicketBody extends StatefulWidget {
  final SupportTicket ticket;
  const _TicketBody({required this.ticket});

  @override
  State<_TicketBody> createState() => _TicketBodyState();
}

class _TicketBodyState extends State<_TicketBody> {
  final _replyController = TextEditingController();
  bool _internalNote = false;
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final df = DateFormat('MMM d, yyyy · HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Get.offAllNamed(AtlasRoutes.tickets),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to queue'),
          style: TextButton.styleFrom(foregroundColor: AtlasColors.textSecondary),
        ),
        const SizedBox(height: 12),

        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AtlasColors.cardBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    t.ticketNumber,
                    style: const TextStyle(
                      color: AtlasColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusPill(status: t.status),
                  const SizedBox(width: 6),
                  PriorityPill(priority: t.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.subject,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AtlasColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _MetaItem(icon: Icons.business, text: t.orgName),
                  _MetaItem(
                    icon: Icons.person_outline,
                    text: t.reportedByEmail ?? 'Unknown reporter',
                  ),
                  _MetaItem(
                    icon: Icons.access_time,
                    text: 'Created ${df.format(t.createdAt)}',
                  ),
                  if (t.assignedToName != null)
                    _MetaItem(
                      icon: Icons.assignment_ind_outlined,
                      text: 'Assigned to ${t.assignedToName}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Two-column: messages + sidebar
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 900;
          final main = Column(
            children: [
              // Description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AtlasColors.cardBg,
                  border: Border.all(color: AtlasColors.cardBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.description.isEmpty ? '(no description)' : t.description,
                      style: const TextStyle(fontSize: 13.5, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _MessageThread(ticketId: t.id),
              const SizedBox(height: 16),
              _ReplyComposer(
                controller: _replyController,
                internalNote: _internalNote,
                sending: _sending,
                onToggleInternal: (v) => setState(() => _internalNote = v),
                onSend: () => _sendReply(t.id),
              ),
            ],
          );
          final sidebar = _Sidebar(ticket: t);

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: main),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: sidebar),
              ],
            );
          }
          return Column(children: [main, const SizedBox(height: 16), sidebar]);
        }),
      ],
    );
  }

  Future<void> _sendReply(String ticketId) async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    final auth = Get.find<AuthController>();
    final staff = auth.currentStaff.value;
    if (staff == null) return;

    setState(() => _sending = true);
    await TicketService.instance.addMessage(
      ticketId: ticketId,
      body: body,
      internalNote: _internalNote,
      staff: staff,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _replyController.clear();
    });
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AtlasColors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: AtlasColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _MessageThread extends StatelessWidget {
  final String ticketId;
  const _MessageThread({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d · HH:mm');
    return StreamBuilder<List<TicketMessage>>(
      stream: TicketService.instance.watchMessages(ticketId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final messages = snap.data ?? const [];
        if (messages.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AtlasColors.cardBg,
              border: Border.all(color: AtlasColors.cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No messages yet. Start the conversation below.',
                style: TextStyle(color: AtlasColors.textMuted, fontSize: 13),
              ),
            ),
          );
        }
        return Column(
          children: messages.map((m) {
            final isStaff = m.authorType == 'staff';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: m.internalNote
                    ? AtlasColors.warningSoft
                    : isStaff
                        ? AtlasColors.accentSoft
                        : AtlasColors.cardBg,
                border: Border.all(
                  color: m.internalNote
                      ? AtlasColors.warning.withValues(alpha: 0.3)
                      : AtlasColors.cardBorder,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isStaff
                            ? AtlasColors.accent
                            : AtlasColors.textMuted,
                        child: Text(
                          m.authorName.isNotEmpty
                              ? m.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AtlasColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isStaff ? AtlasColors.accent : AtlasColors.textMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isStaff ? 'STAFF' : 'CUSTOMER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (m.internalNote) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AtlasColors.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'INTERNAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        df.format(m.timestamp),
                        style: const TextStyle(
                          color: AtlasColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.body,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool internalNote;
  final bool sending;
  final ValueChanged<bool> onToggleInternal;
  final VoidCallback onSend;

  const _ReplyComposer({
    required this.controller,
    required this.internalNote,
    required this.sending,
    required this.onToggleInternal,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: internalNote
                  ? 'Internal note (not visible to customer)…'
                  : 'Reply to customer…',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Switch(
                value: internalNote,
                activeThumbColor: AtlasColors.warning,
                onChanged: onToggleInternal,
              ),
              const SizedBox(width: 6),
              Text(
                internalNote ? 'Internal note' : 'Customer reply',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: internalNote
                      ? AtlasColors.warning
                      : AtlasColors.textSecondary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 14),
                label: Text(sending ? 'Sending…' : 'Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final SupportTicket ticket;
  const _Sidebar({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtlasColors.cardBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TicketStatus.values.map((s) {
                  final sel = ticket.status == s;
                  return InkWell(
                    onTap: sel
                        ? null
                        : () => TicketService.instance.updateStatus(ticket.id, s),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AtlasColors.accent : AtlasColors.cardBg,
                        border: Border.all(
                          color: sel ? AtlasColors.accent : AtlasColors.cardBorder,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s.label,
                        style: TextStyle(
                          color: sel ? Colors.white : AtlasColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AtlasColors.cardBorder),
              const SizedBox(height: 16),

              const Text(
                'PRIORITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TicketPriority.values.map((p) {
                  final sel = ticket.priority == p;
                  return InkWell(
                    onTap: sel
                        ? null
                        : () => TicketService.instance.updatePriority(ticket.id, p),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AtlasColors.accent : AtlasColors.cardBg,
                        border: Border.all(
                          color: sel ? AtlasColors.accent : AtlasColors.cardBorder,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color: sel ? Colors.white : AtlasColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AssignmentCard(ticket: ticket),
        const SizedBox(height: 16),
        _CustomerContextCard(ticket: ticket),
      ],
    );
  }
}

class _CustomerContextCard extends StatelessWidget {
  final SupportTicket ticket;
  const _CustomerContextCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: CustomerService.instance.getOrganization(ticket.orgId),
      builder: (context, snap) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AtlasColors.cardBg,
            border: Border.all(color: AtlasColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CUSTOMER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AtlasColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AtlasColors.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.business, size: 14, color: AtlasColors.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.orgName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AtlasColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (snap.data != null)
                          Text(
                            (snap.data!.plan ?? 'free').toUpperCase(),
                            style: const TextStyle(
                              color: AtlasColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final controller = Get.put(CustomerController());
                    controller.openCustomer(ticket.orgId);
                    Get.toNamed(AtlasRoutes.customerDetail, arguments: ticket.orgId);
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open customer'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: snap.data == null
                      ? null
                      : () => showStartImpersonationModal(context, snap.data!),
                  icon: const Icon(Icons.person_outline, size: 14),
                  label: const Text('Impersonate from ticket'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final SupportTicket ticket;
  const _AssignmentCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ASSIGNMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AtlasColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ticket.assignedToName ?? 'Unassigned',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ticket.assignedToName == null
                  ? AtlasColors.textMuted
                  : AtlasColors.textPrimary,
              fontStyle: ticket.assignedToName == null
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final auth = Get.find<AuthController>();
                final staff = auth.currentStaff.value;
                if (staff != null) {
                  TicketService.instance.assignTo(ticket.id, staff);
                }
              },
              icon: const Icon(Icons.person_pin, size: 14),
              label: const Text('Claim ticket'),
            ),
          ),
        ],
      ),
    );
  }
}
