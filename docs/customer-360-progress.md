# Customer 360 — Implementation Progress

Tracks the build of the Customer 360 read-only support view per
`docs/pagentz-atlas-customer-360-design-spec.html` (in the customer-app
repo). **AMS (Tab 4) and IPAM (Tab 5) are out of scope** for this build.

Last updated: 2026-04-28 (Channels, Webhooks, Notification Health, Support internal-notes view, Members security flag, header polish all landed — only spec gap remaining is per-channel delivery webhooks which need backend logging)

## Status legend

- ✅ Done — landed and analyzes clean
- 🟡 Partial — exists but missing spec requirements
- ❌ Pending — not yet started
- ⛔ Skipped — out of scope per user direction

---

## Phase 0 — Stream B foundations (customer app)

These are prerequisite for any Atlas redirect button to work. Without
Stream B, snapshot+redirect tabs (Schedules / Policies / Teams) would
land users on a broken UI.

| # | Task | Status | Files |
|---|------|--------|-------|
| 0.1 | `atlasCreateStaff` sets `isStaff` custom **token claim** (not just Firestore field). Wired into `atlasUpdateStaffRole` and `atlasSetStaffDisabled` so claim stays in sync on role change / disable. | ✅ | `PAGENTZDEV-ramadev/cloud-functions/functions/atlas.js` |
| 0.2 | URL param parsing for `?orgId=X&staffMode=true` on customer-app boot. New `StaffModeService` (GetX) verifies `isStaff` token claim, overrides `FSDBService.activeOrgId`, exposes reactive `staffViewMode`. | ✅ | `PAGENTZDEV-ramadev/lib/core/services/staff_mode_service.dart` + `lib/utils/app_binding.dart` |
| 0.3 | `StaffViewBanner` sticky orange→red banner. Mounted above `OfflineBanner` in `main_app.dart`. Has "Exit staff view" button (signs out). | ✅ | `PAGENTZDEV-ramadev/lib/widget/staff_view_banner.dart` + `lib/main_app.dart` |
| 0.4 | Global write-button gate. `PermissionGuardService` extended with `isStaffView` getter — every existing `canWrite*` / `canEdit*` getter short-circuits to false in staff view. **Zero callsites touched** (~100 existing usages auto-gate). `canRead*` returns true for staff so they can read everything; `canAccessSettings` and `canManageMembers` also allow staff (read-only). | ✅ | `PAGENTZDEV-ramadev/lib/core/services/permission_guard_service.dart` |
| 0.5 | Firestore rules — `&& !isStaff()` added to every customer-data write rule (organizations, members, groups, settings, AllTeams, inbound_emails, Oncall_Schedules, escalation_policies, notifications). Defense in depth: even if a UI button slips through, the data layer rejects. | ✅ | `PAGENTZDEV-ramadev/firestore.rules` |
| 0.6 | Customer-side `staff_audit_logs` writer. `StaffAuditObserver` NavigatorObserver writes `STAFF_VIEWED_PAGE` on every route push/replace. De-duped against last-logged route. Inert when staff view is off. | ✅ | `PAGENTZDEV-ramadev/lib/core/services/staff_audit_observer.dart` + `lib/core/services/staff_mode_service.dart` (logPageView) + `lib/main_app.dart` (navigatorObservers) |
| 0.7 | `flutter analyze` sanity check on all 6 changed customer-app files. | ✅ | All 5 warnings reported are pre-existing, unrelated to this work. |

### Deployment notes for Phase 0

Before any Atlas redirect goes live in production, the following must be
deployed in this order:

1. Deploy `cloud-functions/functions/atlas.js` (sets the `isStaff` token
   claim on existing staff users — claims appear on next ID-token refresh).
2. Deploy updated `firestore.rules` (blocks staff writes at the data layer).
3. Deploy customer-app web build (`pagentz.web.app`) with the new
   `StaffModeService`, banner, write-gate, and audit observer.

For existing staff users whose claim was set before 0.1: they need to
sign out + back in, or the claim will only land on the next 1-hour token
rotation.

---

## Phase 1 — Atlas Pagers tab

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1.1 | Pagers tab page frame + sub-tab strip. New `PagersTab` widget hosting 7 sub-tabs in a pill-style strip (Linear/Vercel aesthetic, consistent with existing Atlas design tokens). | ✅ | `PAGENTZ_ATLAS/lib/modules/customers/widgets/pagers_tab.dart`. Wired into `customer_detail_screen.dart` between Members and Activity. |
| 1.2 | Pagers / Incidents sub-tab (full) + Incident detail drill-down. Live `inbound_emails` reads scoped by `orgId`, sortable table with priority / status / MTTA / MTTR pills, drill-down to a separate route showing header + KV detail grid + responder notes timeline. | ✅ | New: `customer_incident_model.dart`, `customer_incident_service.dart`, `pagers_incidents_subtab.dart`, `customer_incident_detail_screen.dart`. New route `AtlasRoutes.customerIncidentDetail` registered in `main_app.dart`. |
| 1.3 | Pagers / Notification Health sub-tab — **degraded build delivered**. 4 gauges (Incidents 24h, Ack rate 24h, SMS sent 24h, SMS sent 7d) + 24-hour incident-creation histogram. Reads `inbound_emails` + `sms_incident_map`. Per-channel SMS/Voice/Email delivery success rates from the spec are NOT delivered — Postmark + Vonage do not webhook delivery results back; would require a `notification_deliveries` collection on the customer-app side. Caveat banner explains this. | 🟡 | New `pagers_notification_health_subtab.dart`. |
| 1.4 | Pagers / Channels sub-tab — **delivered**. Aggregates 3 channel kinds in one view: team email inboxes (from `AllTeams.inboxAddress` + `aliases[]`), phone numbers (from `escalation_policies.levels[].targets[].phone`, deduped, with country code), per-person emails (from same target list). 3-tile summary row + 3 sectioned tables. | ✅ | New `pagers_channels_subtab.dart` + `getChannelsForOrg` method on `CustomerPagersService` returning `CustomerChannelsBundle`. |
| 1.5 | Pagers / Webhooks sub-tab — **delivered with caveat**. 3 summary tiles (total / active-in-24h / lifetime events), per-webhook table with name, provider · team, last received, event count, freshness pill (Active < 24h, Stale < 7d, Idle, Disabled). Per-delivery history is NOT delivered — no `webhook_deliveries` collection in schema; caveat banner explains. | 🟡 | New `pagers_webhooks_subtab.dart`. Reuses `CustomerIntegrationService`. |
| 1.6 | Pagers / Schedules sub-tab (snapshot + redirect). Reads `Oncall_Schedules` filtered by team-id batches (chunked at 30 to respect Firestore `whereIn`). Compact list rows showing schedule name, team, date, time window, primary on-call. "Open Schedules in customer view" CTA. | ✅ | `pagers_schedules_subtab.dart` + shared `customer_pagers_models.dart` + `customer_pagers_service.dart`. |
| 1.7 | Pagers / Policies sub-tab (snapshot + redirect). Reads `escalation_policies` (chunk-by-30 by team), table with policy name + team + level count + active status. Redirect CTA. | ✅ | `pagers_policies_subtab.dart`. |
| 1.8 | Pagers / Teams sub-tab (snapshot + redirect). Reads `AllTeams` filtered by `orgId`, responsive 1/2/3-column card grid showing team name + member count + inbox + aliases. Redirect CTA. | ✅ | `pagers_teams_subtab.dart`. |

---

## Phase 2 — Health, Members, Activity, Settings

| # | Task | Status | Notes |
|---|------|--------|-------|
| 2.1 | Tab 9 Health & Diagnostics ⭐ — synthesized health score (0–100 with status label), 4-tile stat row (open / acked / resolved 30d / last alert), and recent errors list (last 24h, filtered to security category or error-ish event types). All client-side aggregation; no new backend. **Notification health gauges deferred — see 1.3.** | ✅ | New `health_tab.dart`. Inserted as tab #4 (right after Pagers) since spec says "support opens this FIRST." |
| 2.2 | Tab 2 Members — fully replaced inline `_MembersTab` with new `MembersTab` widget. Adds: status pill (Active / Invited / Locked / At-risk), role pill, last-active relative time pulled from `users/{uid}.lastActiveAt` (with caching to avoid N+1 reads), invited-at / joined-at timestamps, alphabetical sort with active members first. **Security flag banner** appears above the table when any member has `disabled: true` / `locked: true` / `failedLoginAttempts >= 3` — names the affected accounts and reminds staff that unlocking must happen customer-side. **MFA enrollment column not delivered** — Firebase Auth MFA state isn't on the member doc; would need a Cloud Function to surface it. | ✅ | New `members_tab.dart`. Old inline class removed. |
| 2.3 | Tab 7 Activity — replaced `ActivityTimelineWidget`-only render with new `ActivityTab` widget that adds: time-window filter (24h / 7d / 30d / all), category filter (auto-populated from data), module filter (auto-populated), CSV export via existing `web_download_web.dart` utility, tap-row → detail dialog with all fields + selectable IDs. Filtered count vs total shown in header. | ✅ | New `activity_tab.dart`. Old inline `_ActivityTab` removed. |
| 2.4 | Tab 8 Settings — split into TWO tabs: **"Settings"** (new, read-only, visible to all staff) renders every doc under `organizations/{orgId}/settings/*` with humanized titles, ordered (modules / severity_rules / integrations / pagers / alerts first), bool/Timestamp/List/Map renderers; **"Admin"** (existing, admin-only) keeps reset-password / force-sign-out / disable-org actions. | ✅ | New `settings_tab.dart`. Existing `_SettingsTab` kept and tab label renamed from "Settings" → "Admin". |

---

## Phase 3 — Integrations, Support, Billing, polish

| # | Task | Status | Notes |
|---|------|--------|-------|
| 3.1 | Tab 6 Integrations + reveal-with-reason flow. Reads `organizations/{orgId}/settings/integrations.webhooks[]` and renders each as a card with provider pill, health label (Healthy / Stale / Idle / Disabled / Never received based on `lastReceivedAt`), team, event count, and a masked API key with a generic `RevealableSecret` widget. The reveal flow requires a ≥10-char reason, audit-logs as `REVEALED_API_KEY` with the label as context, and auto-re-masks after 30s. | ✅ | New: `customer_integration_model.dart`, `customer_integration_service.dart`, `widgets/revealable_secret.dart`, `integrations_tab.dart`. |
| 3.2 | Tab 10 Support — **delivered**. Tab renamed from "Tickets" to "Support". New `SupportTab` widget combines: (a) the existing tickets list, (b) an Internal Notes timeline that streams `staff_audit_logs` filtered to `action=ADDED_INTERNAL_NOTE` + `targetId=orgId`, rendered as yellow note cards with author + timestamp. "Add note" button at top of section opens the existing dialog. **Teams/Zoom session recordings not delivered** — no recordings collection exists; placeholder for future once `support_sessions` is added. | ✅ | New `support_tab.dart`. Inline `_TicketsTab` and `_TicketRow` removed. |
| 3.3 | Tab 11 Subscription / Billing — `SubscriptionTab` reads the `subscription` map field on the org doc (live via stream), surfaces plan + status pills with cancel-at-period-end warning, seats / member count, period start / end, all Stripe ids (price / subscription / customer) with selectable monospace text. "Open in Stripe" CTA deep-links to `dashboard.stripe.com/customers/{id}` and audit-logs as `OPENED_STRIPE_DASHBOARD`. **No invoice list or MRR** — would require a Stripe-API Cloud Function. | ✅ | New `subscription_tab.dart`. Replaced inline `_SubscriptionTab` (which was just a 3-row read-only note). |
| 3.4 | Tab 1 Overview — `OverviewTab` adds: 3 stat tiles (members / open incidents / synthesized health score), auto-detected onboarding-progress card (5 steps: team / members / schedule / policy / first alert — checks via parallel queries on `AllTeams`, members subcollection, `Oncall_Schedules`, `escalation_policies`, `inbound_emails`), enhanced details card with last-activity field. | ✅ | New `overview_tab.dart`. Old inline `_OverviewTab` removed. |
| 3.5 | Org-detail frame polish — `OrgAlertBanner` widget streams `inbound_emails` and surfaces banners for: active P1 incident (critical, with title + age + ack state, tap → drill-down), active P2 incident (warning), unacked open incident over 10 minutes old (warning), or "all monitoring" info banner if any open incidents are acked. Renders nothing when healthy. Quick-action bar expanded with 2 new buttons: "Add internal note" (opens dialog → audit log) and "Start Teams call" (opens `teams.microsoft.com/l/call/0/0?users=email` in new tab + audit-logs as `STARTED_TEAMS_CALL`). | ✅ | New `org_alert_banner.dart`, `add_internal_note_dialog.dart`. `_HeaderCard` quick-action `Wrap` extended. |
| 3.6 | Customer rollup polish — **N/A by data model.** `CustomerOrg` docs have no `customerId` / `tenantId` linking multiple orgs to one customer entity. Each org is standalone. The spec's "Acme Corp → orgs list" page assumes a parent customer entity that doesn't exist in the schema. Either (a) skip — `customer_directory_screen.dart` already lists every org flat, which is functionally equivalent, or (b) add a `customerId` field to org docs and a `customers/{id}` collection (a backend change). | ⛔ | Deferred pending data-model decision. |

---

## Out of scope (per user direction)

| Spec section | Status |
|--------------|--------|
| Tab 4 — AMS summary + redirect | ⛔ Skipped |
| Tab 5 — IPAM summary + redirect | ⛔ Skipped |

---

## Open questions / remaining backend work

1. ~~**Customer-app URL for redirect buttons**~~ — resolved: uses `AppConfig.pagentzWebUrl` (default `https://pagentz.web.app`, overridable via `--dart-define`).
2. ~~**Incidents data source**~~ — resolved: `inbound_emails` top-level scoped by `orgId`.
3. **Per-channel notification delivery webhooks (still partial)** — to upgrade 1.3 from degraded to full spec, the customer-app side needs a `notification_deliveries` collection with one row per send (channel, recipient, status, error, sentAt, deliveredAt). Postmark + Vonage both support delivery webhooks; wiring those up unlocks the SMS / Voice / Email gauges and the per-channel last-100-deliveries chart from the spec.
4. **Webhook delivery history (1.5)** — to upgrade webhooks from "config + freshness" to "delivery success/failure history", add a `webhook_deliveries` collection (or subcollection on the integration doc) written from the inbound-webhook handler.
5. **Customer-app session recordings (3.2)** — Teams/Zoom session list from spec section 13 isn't deliverable until a `support_sessions` collection exists. Atlas already has the placeholder section.
6. **Past invoices (3.3)** — needs a Stripe-API Cloud Function (`stripeListInvoices` callable). The "Open in Stripe" deep-link covers the support workflow today.
7. **MFA enrollment / Firebase Auth state** — spec wants MFA column on Members. Requires a Cloud Function that calls `admin.auth().getUser(uid).multiFactor` since this state isn't mirrored to Firestore.
8. **Customer rollup page (3.6)** — `CustomerOrg` has no `customerId` linking multiple orgs. Either add the field + a `customers` collection, or accept that each org IS the customer entity (current model).
9. **Token-claim refresh for existing staff users** — after deploying Phase 0.1, existing staff need to sign out + back in to pick up the new `isStaff` claim (or wait < 1h for normal token rotation).

---

## File index — what changed in this build

### Customer app (`PAGENTZDEV-ramadev`)

- `cloud-functions/functions/atlas.js` — custom claim helper + 3 callsite wires
- `firestore.rules` — `!isStaff()` on customer-data writes
- `lib/core/services/staff_mode_service.dart` — **new**
- `lib/core/services/staff_audit_observer.dart` — **new**
- `lib/widget/staff_view_banner.dart` — **new**
- `lib/utils/app_binding.dart` — register `StaffModeService`
- `lib/main_app.dart` — mount banner + add navigator observer
- `lib/core/services/permission_guard_service.dart` — `isStaffView` gating

### Atlas (`PAGENTZ_ATLAS`)

- `lib/utils/routes.dart` — added `customerIncidentDetail` route
- `lib/utils/staff_redirect.dart` — **new** — builds `pagentz.web.app/?orgId=X&staffMode=true` URLs and audit-logs `OPENED_CUSTOMER_*` events
- `lib/main_app.dart` — registered new `customerIncidentDetail` page
- `lib/core/models/customer_incident_model.dart` — **new** — read-only `CustomerIncident` + `CustomerIncidentNote`
- `lib/core/models/customer_pagers_models.dart` — **new** — `CustomerTeam`, `CustomerSchedule`, `CustomerPolicy`
- `lib/core/services/customer_incident_service.dart` — **new** — `inbound_emails` reads + notes subcollection
- `lib/core/services/customer_pagers_service.dart` — **new** — `AllTeams`, `Oncall_Schedules`, `escalation_policies` reads (chunk-by-30 for `whereIn`)
- `lib/modules/customers/widgets/pagers_tab.dart` — **new** — 7 sub-tab pill strip; wires Incidents / Schedules / Policies / Teams to real implementations
- `lib/modules/customers/widgets/pagers_incidents_subtab.dart` — **new**
- `lib/modules/customers/widgets/pagers_schedules_subtab.dart` — **new**
- `lib/modules/customers/widgets/pagers_policies_subtab.dart` — **new**
- `lib/modules/customers/widgets/pagers_teams_subtab.dart` — **new**
- `lib/modules/customers/widgets/snapshot_redirect_card.dart` — **new** — shared CTA card used by all 3 snapshot tabs
- `lib/modules/customers/widgets/members_tab.dart` — **new** — Phase 2.2 replacement (status / role / last-active / invited-at)
- `lib/modules/customers/widgets/activity_tab.dart` — **new** — Phase 2.3 (filter chips + CSV export + detail dialog)
- `lib/modules/customers/widgets/settings_tab.dart` — **new** — Phase 2.4 read-only mirror of `organizations/{orgId}/settings/*`
- `lib/modules/customers/widgets/health_tab.dart` — **new** — Phase 2.1 synthesized health score + stats + recent errors
- `lib/core/models/customer_integration_model.dart` — **new** — Phase 3.1 read-only `CustomerIntegration` with computed `healthLabel`
- `lib/core/services/customer_integration_service.dart` — **new** — Phase 3.1 reads `organizations/{orgId}/settings/integrations.webhooks[]`
- `lib/widgets/revealable_secret.dart` — **new** — Phase 3.1 generic reveal-with-reason for API keys / webhook secrets (≥10-char reason, audits as `REVEALED_API_KEY`, auto-rehides at 30s)
- `lib/modules/customers/widgets/integrations_tab.dart` — **new** — Phase 3.1 integrations list + summary stats + reveal flow
- `lib/modules/customers/widgets/subscription_tab.dart` — **new** — Phase 3.3 plan card + subscription detail (Stripe ids selectable) + Stripe-portal deep link
- `lib/modules/customers/widgets/overview_tab.dart` — **new** — Phase 3.4 stat tiles + auto-detected onboarding card
- `lib/modules/customers/widgets/org_alert_banner.dart` — **new** — Phase 3.5 P1 / P2 / stale-unacked alert banner with deep-link
- `lib/modules/customers/widgets/add_internal_note_dialog.dart` — **new** — Phase 3.5 + 3.2 partial delivery (writes `ADDED_INTERNAL_NOTE` to staff_audit_logs)
- `lib/modules/customers/screens/customer_detail_screen.dart` — tabs expanded to 9–10 (Overview · Members · Pagers · Health ⭐ · Integrations · Activity · Support · Subscription · Settings · Admin), header card now shows plan pill (Free / Plus / Premium / Enterprise) + DISABLED pill if disabled + customer-since subtitle (e.g. "Information Technology · 8 members · Customer since Aug 12, 2025 (8 months)"), `OrgAlertBanner` mounted above header, quick-action bar extended with "Add internal note" and "Start Teams call", inline `_MembersTab` / `_ActivityTab` / `_OverviewTab` / `_SubscriptionTab` / `_TicketsTab` / `_TicketRow` all removed
- `lib/modules/customers/widgets/pagers_channels_subtab.dart` — **new** — Phase 1.4 aggregated channels view (inboxes / phones / person emails)
- `lib/modules/customers/widgets/pagers_webhooks_subtab.dart` — **new** — Phase 1.5 webhook configuration + freshness view
- `lib/modules/customers/widgets/pagers_notification_health_subtab.dart` — **new** — Phase 1.3 degraded notification-health view (incident counts + SMS map + 24h histogram)
- `lib/modules/customers/widgets/support_tab.dart` — **new** — Phase 3.2 Support tab combining tickets list + internal-notes timeline
- `lib/core/services/customer_pagers_service.dart` — added `getChannelsForOrg` returning `CustomerChannelsBundle` (+ `CustomerInboxChannel` / `CustomerPhoneChannel` / `CustomerPersonEmailChannel` types)
- `lib/modules/customers/screens/customer_incident_detail_screen.dart` — **new** — drill-down route with header + detail grid + notes
