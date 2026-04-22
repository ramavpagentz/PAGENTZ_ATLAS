// ──────────────────────────────────────────────────────────────────────────
// CUSTOMER-SIDE: Contact Support form
//
// COPY this into the main PagentZ Flutter app (e.g.
// /lib/module/setting/contact_support_screen.dart) and add a route + a
// menu item ("Contact Support" or "Help") in the customer's sidebar.
//
// What it does:
//   - Customer fills in subject + description + priority
//   - Writes a doc to `support_tickets` with their org context
//   - Atlas staff sees it instantly in the queue
//   - Customer gets a confirmation
//
// Dependencies: firebase_auth, cloud_firestore, get (already in main app)
// ──────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ContactSupportScreen extends StatefulWidget {
  /// Pass the active org's id and name (from your existing org-state controller).
  final String orgId;
  final String orgName;

  const ContactSupportScreen({
    super.key,
    required this.orgId,
    required this.orgName,
  });

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String _priority = 'normal';
  bool _submitting = false;
  bool _submitted = false;
  String? _ticketNumber;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  String _generateTicketNumber() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'T-${now.substring(now.length - 5)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final ticketNumber = _generateTicketNumber();
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'ticketNumber': ticketNumber,
        'status': 'new',
        'priority': _priority,
        'subject': _subject.text.trim(),
        'description': _description.text.trim(),
        'orgId': widget.orgId,
        'orgName': widget.orgName,
        'reportedByUid': user?.uid,
        'reportedByEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'sourceChannel': 'in_app',
        'tags': <String>[],
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
        _ticketNumber = ticketNumber;
      });
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _submitted ? _Success(ticketNumber: _ticketNumber!) : _form(theme),
          ),
        ),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How can we help?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Describe your issue and our support team will reply within 24 hours.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _subject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              hintText: 'Short summary of the issue',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low — general question')),
              DropdownMenuItem(value: 'normal', child: Text('Normal — issue but workable')),
              DropdownMenuItem(value: 'high', child: Text('High — feature broken for me')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgent — production down / data loss')),
            ],
            onChanged: (v) => setState(() => _priority = v ?? 'normal'),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _description,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What happened? What did you expect? Steps to reproduce?',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                (v == null || v.trim().length < 10) ? 'Please provide at least 10 characters' : null,
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(_submitting ? 'Sending…' : 'Submit ticket'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  final String ticketNumber;
  const _Success({required this.ticketNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 40),
          ),
          const SizedBox(height: 18),
          Text(
            'Ticket submitted',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Your reference number is $ticketNumber',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            'Our support team will respond by email shortly.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
          ),
        ],
      ),
    );
  }
}
