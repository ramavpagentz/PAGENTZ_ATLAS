// ──────────────────────────────────────────────────────────────────────────
// PAGENTZ ATLAS — atlasImpersonate Cloud Function
//
// MEANT TO BE COPIED INTO the main pagentz repo's cloud-functions/functions
// directory. Add to index.js exports.
//
// What it does:
//   1. Verifies the caller is a staff user with role >= l2_support
//   2. Validates the target org/user exists
//   3. Writes an impersonation_sessions document
//   4. Writes a staff_audit_logs entry
//   5. Mints a Firebase custom token for the target user
//   6. Returns the token to the Atlas frontend
//
// The Atlas frontend opens pagentz.web.app?atlas_impersonation_token=XXX
// in a new tab. The customer app detects the token, signs in with it, and
// shows a red "VIEWING AS …" banner.
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

exports.atlasImpersonate = onCall(async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }

  const { targetOrgId, targetUid, reason, mode = 'read_only', durationMinutes = 60 } = data || {};
  if (!targetOrgId || !targetUid || !reason || reason.length < 10) {
    throw new HttpsError('invalid-argument', 'targetOrgId, targetUid, and a reason (10+ chars) are required.');
  }

  const db = admin.firestore();

  // ─── 1. Verify caller is staff ───
  const staffSnap = await db.collection('users').doc(auth.uid).get();
  if (!staffSnap.exists) {
    throw new HttpsError('permission-denied', 'No staff profile found.');
  }
  const staff = staffSnap.data();
  if (!staff.isAtlas || staff.disabled) {
    throw new HttpsError('permission-denied', 'Atlas access required.');
  }

  const callerLevel = ROLE_LEVEL[staff.staffRole] || 0;
  const requiredLevel = mode === 'read_write' ? ROLE_LEVEL.engineer : ROLE_LEVEL.l2_support;
  if (callerLevel < requiredLevel) {
    throw new HttpsError(
      'permission-denied',
      `Role ${staff.staffRole} cannot impersonate in mode ${mode}.`,
    );
  }

  // ─── 2. Verify target ───
  const orgSnap = await db.collection('organizations').doc(targetOrgId).get();
  if (!orgSnap.exists) {
    throw new HttpsError('not-found', 'Target organization not found.');
  }
  const targetSnap = await db.collection('users').doc(targetUid).get();
  if (!targetSnap.exists) {
    throw new HttpsError('not-found', 'Target user not found.');
  }
  const target = targetSnap.data();

  // ─── 3. Write impersonation session ───
  const startedAt = admin.firestore.FieldValue.serverTimestamp();
  const expiresAt = new Date(Date.now() + Math.min(durationMinutes, 60) * 60 * 1000);
  const sessionRef = await db.collection('impersonation_sessions').add({
    staffUid: auth.uid,
    staffEmail: staff.email,
    targetOrgId,
    targetUid,
    targetEmail: target.email || null,
    reason,
    mode,
    startedAt,
    expiresAt,
    endedAt: null,
    customTokenIssued: true,
  });

  // ─── 4. Write audit log ───
  await db.collection('staff_audit_logs').add({
    timestamp: startedAt,
    staffUid: auth.uid,
    staffEmail: staff.email,
    staffRole: staff.staffRole,
    action: 'IMPERSONATED_USER',
    targetType: 'user',
    targetId: targetUid,
    targetDisplay: target.email || targetUid,
    reason,
    extra: { sessionId: sessionRef.id, mode, orgId: targetOrgId },
  });

  // ─── 5. Mint custom token ───
  const customToken = await admin.auth().createCustomToken(targetUid, {
    impersonatedBy: auth.uid,
    impersonationSessionId: sessionRef.id,
    mode,
    expiresAt: expiresAt.getTime(),
  });

  return {
    token: customToken,
    sessionId: sessionRef.id,
    expiresAt: expiresAt.toISOString(),
  };
});
