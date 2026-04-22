import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable record of a staff action in Atlas.
class AuditLog {
  final String id;
  final DateTime timestamp;
  final String staffUid;
  final String staffEmail;
  final String staffRole;
  final String action;
  final String targetType;
  final String targetId;
  final String? targetDisplay;
  final String? reason;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? changes;

  const AuditLog({
    required this.id,
    required this.timestamp,
    required this.staffUid,
    required this.staffEmail,
    required this.staffRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.targetDisplay,
    this.reason,
    this.ipAddress,
    this.userAgent,
    this.changes,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuditLog(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      staffUid: (data['staffUid'] ?? '') as String,
      staffEmail: (data['staffEmail'] ?? '') as String,
      staffRole: (data['staffRole'] ?? '') as String,
      action: (data['action'] ?? '') as String,
      targetType: (data['targetType'] ?? '') as String,
      targetId: (data['targetId'] ?? '') as String,
      targetDisplay: data['targetDisplay'] as String?,
      reason: data['reason'] as String?,
      ipAddress: data['ipAddress'] as String?,
      userAgent: data['userAgent'] as String?,
      changes: data['changes'] as Map<String, dynamic>?,
    );
  }
}

/// Standard action constants used across the codebase.
class AuditAction {
  AuditAction._();
  static const viewedCustomer = 'VIEWED_CUSTOMER';
  static const viewedPii = 'VIEWED_PII';
  static const impersonatedUser = 'IMPERSONATED_USER';
  static const impersonationWrite = 'IMPERSONATION_WRITE';
  static const editedOrg = 'EDITED_ORG';
  static const editedSubscription = 'EDITED_SUBSCRIPTION';
  static const disabledCustomer = 'DISABLED_CUSTOMER';
  static const resetCustomerPassword = 'RESET_CUSTOMER_PASSWORD';
  static const revokedSessions = 'REVOKED_CUSTOMER_SESSIONS';
  static const createdTicket = 'CREATED_TICKET';
  static const resolvedTicket = 'RESOLVED_TICKET';
  static const changedStaffRole = 'CHANGED_STAFF_ROLE';
  static const addedStaff = 'ADDED_STAFF';
  static const removedStaff = 'REMOVED_STAFF';
  static const exportedData = 'EXPORTED_DATA';
  static const loginSuccess = 'LOGIN_SUCCESS';
  static const loginDenied = 'LOGIN_DENIED';
}
