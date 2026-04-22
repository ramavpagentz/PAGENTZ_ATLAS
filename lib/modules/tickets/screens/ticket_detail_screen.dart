import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../auth/controller/staff_auth_controller.dart';
import '../controller/ticket_detail_controller.dart';
import '../models/ticket_models.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late final String ticketId;
  late final TicketDetailController c;
  final _replyCtl = TextEditingController();
  bool _internalNote = false;

  @override
  void initState() {
    super.initState();
    ticketId = Get.parameters['ticketId'] ?? '';
    c = Get.put(TicketDetailController(ticketId), tag: ticketId);
  }

  @override
  Widget build(BuildContext context) {
    if (ticketId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Missing ticketId')));
    }
    final auth = Get.find<StaffAuthController>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.offNamed('/tickets'),
        ),
        title: Obx(() => Text(
            c.ticket.value == null
                ? 'Loading…'
                : '${c.ticket.value!.ticketNumber}  ·  ${c.ticket.value!.subject}',
            overflow: TextOverflow.ellipsis)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: c.load),
        ],
      ),
      body: Obx(() {
        if (c.loading.value && c.ticket.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value != null) {
          return Center(
              child: Text(c.error.value!,
                  style: const TextStyle(color: Colors.redAccent)));
        }
        final t = c.ticket.value;
        if (t == null) return const SizedBox.shrink();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: _MessagesPane(
                ticket: t,
                messages: c.messages,
                replyCtl: _replyCtl,
                internalNote: _internalNote,
                onToggleInternal: (v) =>
                    setState(() => _internalNote = v),
                onSend: _send,
                busy: c.busy,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: _MetaPane(
                ticket: t,
                controller: c,
                currentUid: auth.firebaseUser.value?.uid,
                currentName: auth.staffUser.value?.displayName ?? '',
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _send() async {
    final body = _replyCtl.text.trim();
    if (body.isEmpty) return;
    await c.sendMessage(body: body, internalNote: _internalNote);
    _replyCtl.clear();
    setState(() => _internalNote = false);
  }
}

class _MessagesPane extends StatelessWidget {
  final SupportTicket ticket;
  final RxList<TicketMessage> messages;
  final TextEditingController replyCtl;
  final bool internalNote;
  final ValueChanged<bool> onToggleInternal;
  final VoidCallback onSend;
  final RxBool busy;

  const _MessagesPane({
    required this.ticket,
    required this.messages,
    required this.replyCtl,
    required this.internalNote,
    required this.onToggleInternal,
    required this.onSend,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _DescriptionCard(ticket: ticket),
                const SizedBox(height: 12),
                if (messages.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No messages yet.',
                          style: TextStyle(color: Colors.white60)),
                    ),
                  )
                else
                  ...messages.map((m) => _MessageBubble(msg: m)),
              ],
            );
          }),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: replyCtl,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: internalNote
                      ? 'Internal note (not visible to customer)'
                      : 'Reply to customer',
                  border: const OutlineInputBorder(),
                  filled: internalNote,
                  fillColor: internalNote
                      ? Colors.amber.withValues(alpha: 0.1)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Internal note'),
                    selected: internalNote,
                    onSelected: onToggleInternal,
                    avatar: const Icon(Icons.shield_outlined, size: 14),
                  ),
                  const Spacer(),
                  Obx(() => FilledButton.icon(
                        onPressed: busy.value ? null : onSend,
                        icon: const Icon(Icons.send, size: 16),
                        label: Text(internalNote ? 'Add note' : 'Send reply'),
                      )),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final SupportTicket ticket;
  const _DescriptionCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16),
                const SizedBox(width: 8),
                Text(
                  ticket.reportedByEmail ??
                      (ticket.reportedByUid ?? 'Internal (staff-created)'),
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                if (ticket.createdAt != null)
                  Text(
                    DateFormat('MMM d, HH:mm').format(
                        ticket.createdAt!.toLocal()),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(
              ticket.description.isEmpty
                  ? '(no description)'
                  : ticket.description,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bg = msg.internalNote
        ? Colors.amber.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.04);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: msg.internalNote
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                msg.internalNote
                    ? Icons.shield_outlined
                    : Icons.chat_bubble_outline,
                size: 14,
                color: msg.internalNote ? Colors.amber : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                msg.authorName ?? msg.authorUid ?? 'unknown',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (msg.internalNote) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('INTERNAL',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.amber,
                          fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              if (msg.timestamp != null)
                Text(
                  DateFormat('MMM d, HH:mm').format(msg.timestamp!.toLocal()),
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(msg.body, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _MetaPane extends StatelessWidget {
  final SupportTicket ticket;
  final TicketDetailController controller;
  final String? currentUid;
  final String currentName;

  const _MetaPane({
    required this.ticket,
    required this.controller,
    required this.currentUid,
    required this.currentName,
  });

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11)),
          ),
          Expanded(child: SelectableText(v ?? '—')),
        ],
      ),
    );
  }

  String _fmt(DateTime? t) =>
      t == null ? '—' : DateFormat('MMM d, y HH:mm').format(t.toLocal());

  @override
  Widget build(BuildContext context) {
    final isClaimedByMe =
        ticket.assignedToUid != null && ticket.assignedToUid == currentUid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<TicketStatus>(
                      initialValue: ticket.status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: TicketStatus.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.label),
                              ))
                          .toList(),
                      onChanged: controller.busy.value
                          ? null
                          : (s) {
                              if (s != null && s != ticket.status) {
                                controller.changeStatus(s);
                              }
                            },
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => DropdownButtonFormField<TicketPriority>(
                      initialValue: ticket.priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: TicketPriority.values
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ))
                          .toList(),
                      onChanged: controller.busy.value
                          ? null
                          : (p) {
                              if (p != null && p != ticket.priority) {
                                controller.changePriority(p);
                              }
                            },
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(() => OutlinedButton.icon(
                      onPressed: controller.busy.value
                          ? null
                          : (isClaimedByMe
                              ? controller.unclaim
                              : () => controller.claim(
                                  currentUid ?? '', currentName)),
                      icon: Icon(
                          isClaimedByMe
                              ? Icons.person_remove
                              : Icons.person_add_alt,
                          size: 16),
                      label: Text(isClaimedByMe ? 'Unclaim' : 'Claim'),
                    )),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Details', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          _kv('Ticket #', ticket.ticketNumber),
          _kv('Customer', ticket.orgName),
          _kv('Org ID', ticket.orgId),
          _kv('Reporter', ticket.reportedByEmail),
          _kv('Assignee', ticket.assignedToName),
          _kv('Created', _fmt(ticket.createdAt)),
          _kv('Updated', _fmt(ticket.updatedAt)),
          _kv('First response', _fmt(ticket.firstResponseAt)),
          _kv('Resolved', _fmt(ticket.resolvedAt)),
          _kv('Source', ticket.sourceChannel),
          if (ticket.orgId != null && ticket.orgId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Get.toNamed('/customers/${ticket.orgId}'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open customer'),
            ),
          ],
        ],
      ),
    );
  }
}
