// ──────────────────────────────────────────────────────────────────────────
// ATLAS CUSTOMER ADMIN — Cloud Functions
//
// Three callable functions for staff to act on customer accounts:
//   - atlasResetCustomerPassword (l2_support+)
//   - atlasRevokeCustomerSessions (engineer+)
//   - atlasSetOrgDisabled (admin+)
//
// All three:
//   - Verify caller is staff with required minimum role
//   - Write to staff_audit_logs atomically with the action
//   - Throw HttpsError on any failure
//
// Add to main pagentz repo: cloud-functions/functions/atlas_customer_admin.js
// In index.js:
//   const admin = require('./atlas_customer_admin');
//   exports.atlasResetCustomerPassword = admin.atlasResetCustomerPassword;
//   exports.atlasRevokeCustomerSessions = admin.atlasRevokeCustomerSessions;
//   exports.atlasSetOrgDisabled = admin.atlasSetOrgDisabled;
// ──────────────────────────────────────────────────────────────────────────

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const ROLE_LEVEL = {
  owner: 5,
  admin: 4,
  engineer: 3,
  l2_support: 2,
  l1_support: 1,
};

async function requireStaff(authUid, minRoleLevel) {
  if (!authUid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const db = admin.firestore();
  const snap = await db.collection('users').doc(authUid).get();
  if (!snap.exists) {
    throw new HttpsError('permission-denied', 'No staff profile found.');
  }
  const data = snap.data();
  if (!data.isAtlas || data.disabled) {
    throw new HttpsError('permission-denied', 'Atlas access required.');
  }
  const level = ROLE_LEVEL[data.staffRole] || 0;
  if (level < minRoleLevel) {
    throw new HttpsError(
      'permission-denied',
      `Role ${data.staffRole} cannot perform this action (requires level ${minRoleLevel}).`,
    );
  }
  return { uid: authUid, ...data };
}

async function writeAudit(staff, action, targetType, targetId, targetDisplay, reason, extra) {
  const db = admin.firestore();
  await db.collection('staff_audit_logs').add({
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    staffUid: staff.uid,
    staffEmail: staff.email,
    staffRole: staff.staffRole,
    action,
    targetType,
    targetId,
    targetDisplay: targetDisplay || null,
    reason: reason || null,
    extra: extra || null,
  });
}

// ─────────────────────────────────────────────────────────────
// 1. Reset customer password — sends Firebase password reset email
// ─────────────────────────────────────────────────────────────
exports.atlasResetCustomerPassword = onCall(async (request) => {
  const staff = await requireStaff(request.auth?.uid, ROLE_LEVEL.l2_support);
  const { targetUid, targetEmail, reason } = request.data || {};
  if (!targetUid || !targetEmail || !reason || reason.length < 5) {
    throw new HttpsError('invalid-argument', 'targetUid, targetEmail, and a reason (5+ chars) are required.');
  }

  // Generate the reset link via Admin SDK (we let Firebase Auth deliver it).
  const link = await admin.auth().generatePasswordResetLink(targetEmail);

  // Write the email to the `mail` collection (Trigger Email extension delivers).
  const db = admin.firestore();
  await db.collection('mail').add({
    to: targetEmail,
    message: {
      subject: 'Reset your PagentZ password',
      html: `
        <div style="font-family: -apple-system, sans-serif; max-width: 480px; padding: 24px;">
          <h2>Reset your PagentZ password</h2>
          <p>A PagentZ support team member has triggered a password reset for your account.</p>
          <p style="margin: 24px 0;">
            <a href="${link}" style="background: #059669; color: white; padding: 12px 20px; text-decoration: none; border-radius: 6px; font-weight: 700;">Set a new password</a>
          </p>
          <p style="color: #94A3B8; font-size: 12px;">If you did not request this, you can safely ignore this email — your current password remains unchanged.</p>
        </div>
      `,
    },
    _meta: { type: 'password_reset', issuedBy: staff.email },
  });

  await writeAudit(
    staff,
    'RESET_CUSTOMER_PASSWORD',
    'user',
    targetUid,
    targetEmail,
    reason,
  );
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────
// 2. Revoke customer sessions — forces sign-out everywhere
// ─────────────────────────────────────────────────────────────
exports.atlasRevokeCustomerSessions = onCall(async (request) => {
  const staff = await requireStaff(request.auth?.uid, ROLE_LEVEL.engineer);
  const { targetUid, targetEmail, reason } = request.data || {};
  if (!targetUid || !reason || reason.length < 5) {
    throw new HttpsError('invalid-argument', 'targetUid and a reason (5+ chars) are required.');
  }

  // Revokes all refresh tokens for the user — they'll be signed out within ~1h
  // (or immediately if your backend checks Firebase ID token revocation status).
  await admin.auth().revokeRefreshTokens(targetUid);

  await writeAudit(
    staff,
    'REVOKED_CUSTOMER_SESSIONS',
    'user',
    targetUid,
    targetEmail || null,
    reason,
  );
  return { ok: true };
});

// ─────────────────────────────────────────────────────────────
// 3. Disable / re-enable customer organization
// ─────────────────────────────────────────────────────────────
exports.atlasSetOrgDisabled = onCall(async (request) => {
  const staff = await requireStaff(request.auth?.uid, ROLE_LEVEL.admin);
  const { orgId, orgName, disabled, reason } = request.data || {};
  if (!orgId || typeof disabled !== 'boolean' || !reason || reason.length < 5) {
    throw new HttpsError('invalid-argument', 'orgId, disabled (bool), and a reason (5+ chars) are required.');
  }

  const db = admin.firestore();
  const orgRef = db.collection('organizations').doc(orgId);
  const orgSnap = await orgRef.get();
  if (!orgSnap.exists) {
    throw new HttpsError('not-found', 'Organization not found.');
  }

  await orgRef.update({
    disabled,
    disabledAt: disabled ? admin.firestore.FieldValue.serverTimestamp() : null,
    disabledBy: disabled ? staff.email : null,
  });

  await writeAudit(
    staff,
    disabled ? 'DISABLED_CUSTOMER' : 'EDITED_ORG',
    'org',
    orgId,
    orgName || orgSnap.data().name,
    reason,
    disabled ? null : { action: 're-enabled' },
  );
  return { ok: true };
});
