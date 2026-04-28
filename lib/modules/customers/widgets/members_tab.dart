import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/customer_service.dart';
import '../../../theme/atlas_colors.dart';
import '../../../theme/atlas_text.dart';

/// Enhanced Members tab — surfaces what's available client-side: status
/// (active vs pending invite), role, last-active timestamp from the user
/// doc, and invited-at for pending members.
///
/// Note: MFA enrollment, account-locked state, and failed-login counts
/// live in Firebase Auth and are not exposed on the client. A surface for
/// those would need a Cloud Function.
class MembersTab extends StatelessWidget {
  final String orgId;
  const MembersTab({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CustomerService.instance.watchOrgMembers(orgId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final members = snap.data ?? const [];
        if (members.isEmpty) {
          return _empty();
        }
        // Sort: active first, then pending; within each by name.
        members.sort((a, b) {
          final aActive = (a['status'] ?? 'active') != 'pending';
          final bActive = (b['status'] ?? 'active') != 'pending';
          if (aActive != bActive) return aActive ? -1 : 1;
          return ((a['displayName'] ?? a['email'] ?? '') as String)
              .compareTo((b['displayName'] ?? b['email'] ?? '') as String);
        });
        final lockedMembers = members.where((m) {
          final disabled = m['disabled'] == true || m['locked'] == true;
          final failed = m['failedLoginAttempts'];
          final hasFailed = failed is num && failed >= 3;
          return disabled || hasFailed;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lockedMembers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SecurityFlagBanner(lockedMembers: lockedMembers),
              ),
            Container(
              decoration: BoxDecoration(
                color: AtlasColors.cardBg,
                border: Border.all(color: AtlasColors.cardBorder),
                borderRadius: BorderRadius.circular(AtlasRadius.lg),
              ),
              child: Column(
                children: [
                  const _HeaderRow(),
                  ...members.map((m) => _Row(member: m)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AtlasColors.cardBg,
        border: Border.all(color: AtlasColors.cardBorder),
        borderRadius: BorderRadius.circular(AtlasRadius.lg),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined, size: 28, color: AtlasColors.textMuted),
          SizedBox(height: 8),
          Text('No members in this organization.', style: AtlasText.smallMuted),
        ],
      ),
    );
  }
}

class _SecurityFlagBanner extends StatelessWidget {
  final List<Map<String, dynamic>> lockedMembers;
  const _SecurityFlagBanner({required this.lockedMembers});

  @override
  Widget build(BuildContext context) {
    final names = lockedMembers
        .map((m) => (m['displayName'] ?? m['email'] ?? 'unknown').toString())
        .take(3)
        .join(', ');
    final more = lockedMembers.length > 3 ? ' +${lockedMembers.length - 3} more' : '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(AtlasRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security flag: ${lockedMembers.length} locked or repeatedly-failing account${lockedMembers.length == 1 ? "" : "s"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$names$more · Read-only — do NOT unlock from Atlas. Suggest the customer use forgot-password.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: AtlasColors.tableHeaderBg,
        border: Border(bottom: BorderSide(color: AtlasColors.tableBorder)),
      ),
      child: Row(
        children: const [
          Expanded(flex: 4, child: _HCell('Member')),
          SizedBox(width: 90, child: _HCell('Role')),
          SizedBox(width: 90, child: _HCell('Status')),
          SizedBox(width: 130, child: _HCell('Last active')),
          SizedBox(width: 110, child: _HCell('Joined / invited')),
        ],
      ),
    );
  }
}

class _HCell extends StatelessWidget {
  final String label;
  const _HCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AtlasColors.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Map<String, dynamic> member;
  const _Row({required this.member});

  @override
  Widget build(BuildContext context) {
    final email = (member['email'] ?? '') as String;
    final name = (member['displayName'] ?? member['fullName'] ?? email) as String;
    final role = (member['role'] ?? '').toString();
    final status = (member['status'] ?? 'active').toString();
    final isPending = status == 'pending';
    final isLocked = member['disabled'] == true || member['locked'] == true;
    final failed = member['failedLoginAttempts'];
    final failedCount = failed is num ? failed.toInt() : 0;

    final invitedAt = _toDate(member['invitedAt']);
    final acceptedAt = _toDate(member['acceptedAt']);
    final userId = (member['userId'] ?? member['id'] ?? '') as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AtlasColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isPending
                      ? AtlasColors.pillNeutral
                      : AtlasColors.accentSoft,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isPending
                          ? AtlasColors.textMuted
                          : AtlasColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPending ? '(invite pending)' : name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isPending
                              ? AtlasColors.textMuted
                              : AtlasColors.textPrimary,
                          fontStyle: isPending ? FontStyle.italic : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AtlasColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 90,
            child: _RolePill(role: role),
          ),
          SizedBox(
            width: 90,
            child: _StatusPill(
              isPending: isPending,
              isLocked: isLocked,
              hasFailedAttempts: failedCount >= 3,
            ),
          ),
          SizedBox(
            width: 130,
            child: isPending || userId.isEmpty
                ? const Text('—',
                    style: TextStyle(
                        fontSize: 12, color: AtlasColors.textMuted))
                : _LastActiveCell(userId: userId),
          ),
          SizedBox(
            width: 110,
            child: Text(
              isPending
                  ? (invitedAt != null
                      ? 'invited ${_relative(invitedAt)}'
                      : '—')
                  : (acceptedAt != null
                      ? DateFormat('MMM d, yyyy').format(acceptedAt)
                      : '—'),
              style: const TextStyle(
                fontSize: 12,
                color: AtlasColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  const _RolePill({required this.role});
  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) {
      return const Text('—',
          style: TextStyle(fontSize: 12, color: AtlasColors.textMuted));
    }
    final color = switch (role.toLowerCase()) {
      'owner' => AtlasColors.accent,
      'admin' || 'superadmin' => AtlasColors.info,
      'orgreadonly' => AtlasColors.textMuted,
      _ => AtlasColors.textSecondary,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AtlasRadius.round),
        ),
        child: Text(
          role.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isPending;
  final bool isLocked;
  final bool hasFailedAttempts;
  const _StatusPill({
    required this.isPending,
    required this.isLocked,
    required this.hasFailedAttempts,
  });
  @override
  Widget build(BuildContext context) {
    final (color, label) = isLocked
        ? (AtlasColors.danger, 'Locked')
        : hasFailedAttempts
            ? (AtlasColors.danger, 'At risk')
            : isPending
                ? (AtlasColors.warning, 'Invited')
                : (AtlasColors.success, 'Active');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AtlasRadius.round),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// One-shot Future read of `users/{uid}` to surface `lastActiveAt`.
/// Cached in a static Map keyed by uid so re-renders don't re-query.
class _LastActiveCell extends StatelessWidget {
  static final _cache = <String, DateTime?>{};
  static final _inflight = <String, Future<DateTime?>>{};

  final String userId;
  const _LastActiveCell({required this.userId});

  Future<DateTime?> _fetch() {
    if (_cache.containsKey(userId)) return Future.value(_cache[userId]);
    return _inflight.putIfAbsent(userId, () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final t = doc.data()?['lastActiveAt'];
        final when = t is Timestamp ? t.toDate() : null;
        _cache[userId] = when;
        _inflight.remove(userId);
        return when;
      } catch (_) {
        _inflight.remove(userId);
        return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: _fetch(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('…',
              style:
                  TextStyle(fontSize: 12, color: AtlasColors.textMuted));
        }
        final when = snap.data;
        return Text(
          when == null ? '—' : _relative(when),
          style: TextStyle(
            fontSize: 12,
            color: when != null && _isRecent(when)
                ? AtlasColors.success
                : AtlasColors.textSecondary,
          ),
        );
      },
    );
  }

  static bool _isRecent(DateTime when) =>
      DateTime.now().difference(when).inHours < 24;
}

DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

String _relative(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(when);
}
