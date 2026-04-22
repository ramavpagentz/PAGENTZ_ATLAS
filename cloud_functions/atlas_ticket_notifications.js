// ──────────────────────────────────────────────────────────────────────────
// ATLAS TICKET NOTIFICATIONS — Cloud Function
//
// Triggers on a new message in a support ticket. If the message is from
// staff and is NOT an internal note, sends an email to the ticket reporter
// (and any other org members assigned).
//
// Where to put this:
//   Add to main pagentz repo: cloud-functions/functions/atlas_ticket_notifications.js
//   Then in index.js:
//
//     const ticketNotifs = require('./atlas_ticket_notifications');
//     exports.atlasOnTicketMessage = ticketNotifs.atlasOnTicketMessage;
//
// Email setup:
//   This uses Firebase Extensions: Trigger Email (with SendGrid/SES).
//   Install: firebase ext:install firebase/firestore-send-email
//   Configure with your SMTP creds.
//   The extension reads from the `mail` collection — we just write to it.
// ──────────────────────────────────────────────────────────────────────────

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

exports.atlasOnTicketMessage = onDocumentCreated(
  'support_tickets/{ticketId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    // Only notify on staff replies that are visible to the customer
    if (message.authorType !== 'staff' || message.internalNote === true) {
      return;
    }

    const ticketId = event.params.ticketId;
    const db = admin.firestore();
    const ticketSnap = await db.collection('support_tickets').doc(ticketId).get();
    if (!ticketSnap.exists) return;

    const ticket = ticketSnap.data();
    const recipient = ticket.reportedByEmail;
    if (!recipient) return;

    const subject = `[${ticket.ticketNumber || 'Support'}] ${ticket.subject}`;
    const html = `
      <div style="font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 560px; margin: 0 auto; padding: 24px; color: #0F172A;">
        <h2 style="margin-top: 0; font-size: 20px;">${escapeHtml(ticket.subject)}</h2>
        <p style="color: #64748B; font-size: 13px; margin-bottom: 24px;">
          Ticket <strong>${escapeHtml(ticket.ticketNumber || ticketId)}</strong> ·
          From <strong>${escapeHtml(message.authorName || 'PagentZ Support')}</strong>
        </p>
        <div style="background: #F8FAFC; border-left: 3px solid #059669; padding: 16px 20px; border-radius: 6px; white-space: pre-wrap; line-height: 1.6;">
${escapeHtml(message.body || '')}
        </div>
        <p style="color: #94A3B8; font-size: 12px; margin-top: 28px;">
          Reply directly to this email or contact <a href="mailto:support@pagentz.com" style="color: #059669;">support@pagentz.com</a>.
        </p>
        <hr style="border: none; border-top: 1px solid #E2E8F0; margin: 24px 0;" />
        <p style="color: #94A3B8; font-size: 11px;">PagentZ Support · ${new Date().toUTCString()}</p>
      </div>
    `;

    // Use Firebase "Trigger Email" extension format (collection: mail)
    await db.collection('mail').add({
      to: recipient,
      message: {
        subject,
        html,
        text: stripHtml(html),
      },
      _meta: {
        type: 'ticket_reply',
        ticketId,
        ticketNumber: ticket.ticketNumber || null,
      },
    });

    // Update ticket: mark first response time if not yet set
    const updates = { updatedAt: admin.firestore.FieldValue.serverTimestamp() };
    if (!ticket.firstResponseAt) {
      updates.firstResponseAt = admin.firestore.FieldValue.serverTimestamp();
    }
    await db.collection('support_tickets').doc(ticketId).update(updates);
  },
);

function escapeHtml(s) {
  if (s == null) return '';
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function stripHtml(s) {
  return String(s).replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}
