# Atlas — Backend Logs Architecture

**Status:** Design. Not yet implemented.
**Scope:** How Atlas's "Customer Activity Timeline" (Phase 3b) should pull
customer-side activity from the main PAGENTZDEV-dev backend, and how staff-side
audit events should be archived long-term.
**Written:** 2026-04-21

---

## 1. Why this exists

Atlas currently renders a per-customer Activity tab that merges two streams:

1. **Staff actions** targeting a given org — pulled from Firestore
   `staff_audit_logs` where `targetId == orgId`. Already implemented.
2. **Customer-side activity** — what the customer's own users did (created an
   incident, changed an escalation policy, snoozed an alert, etc.). Currently
   a placeholder card labeled "pending backend integration."

This doc defines what "backend integration" means, in enough detail that a
backend engineer (or Hemal) can build it without having to re-derive the
architecture.

The "no shortcuts, production-grade for large deployment" directive applies.

---

## 2. Current state of customer-side activity

Activity happens today across at least four modules in the main customer app:

| Module | Storage | Purpose |
|---|---|---|
| **Activity Logs** | Azure Postgres | Generic event log for user actions |
| **Pagers** | Azure Postgres | On-call pages, acks, escalations |
| **AMS** (Alert Management) | Azure Postgres | Alert lifecycle, suppressions, silences |
| **IPAM** (IP Address Mgmt) | Azure Postgres | IP allocation changes, subnet edits |

Each module writes its own shape of row to its own table. There is currently
no unified query path that lets us answer "what happened in org XYZ between
T1 and T2, across all modules, in chronological order."

This is the gap Atlas needs closed.

---

## 3. Architecture (three layers)

The production-grade design separates three concerns that have been conflated
in early startups:

```
┌───────────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — OPERATIONAL (customer-facing reads, low-latency, always hot)  │
│                                                                           │
│    Azure Postgres (existing)                                              │
│      activity_logs, pagers_events, ams_events, ipam_events                │
│      (4 tables or materialized views as appropriate)                      │
│    + normalized SQL view `v_activity_events` (see §4)                     │
│    + internal API:  GET /internal/orgs/:orgId/activity?from=&to=&modules= │
│                                                                           │
│    Used by: Atlas (CustomerActivityTimeline), customer app itself,        │
│             oncall responders                                             │
│    Retention: 90 days hot (fast reads), 2 years warm (partitioned)        │
└───────────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ Postgres logical replication / CDC
                                   ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  LAYER 2 — ANALYTICS + FORENSICS (cold, cheap, queryable at scale)       │
│                                                                           │
│    Azure Log Analytics Workspace                                          │
│      custom table: Atlas_ActivityCL (one row per event, normalized)       │
│    + Staff audit events mirrored here too (CF trigger on                  │
│      staff_audit_logs writes → Log Analytics)                             │
│                                                                           │
│    Used by: Security investigations, SOC2 compliance audits, annual       │
│             forensic reviews, rare ad-hoc cross-customer queries          │
│    Retention: 7 years (Log Analytics default — configurable)              │
└───────────────────────────────────────────────────────────────────────────┘

                            — independent —

┌───────────────────────────────────────────────────────────────────────────┐
│  LAYER 3 — STAFF AUDIT (hot, immutable, source of truth)                 │
│                                                                           │
│    Firestore staff_audit_logs  (collection; rules block update/delete)    │
│      Written by Atlas + Cloud Functions                                   │
│                                                                           │
│    Used by: Atlas audit log screen, customer-facing "who accessed me"     │
│             reports, SOC2 access-log attestation                          │
│    Retention: forever (Firestore storage is cheap; 500k rows ≈ $0.09/mo)  │
└───────────────────────────────────────────────────────────────────────────┘
```

### Why split like this?

Each layer has different non-negotiable properties:

- **Layer 1 (Postgres)** must be **fast** (p99 < 200 ms for the org-scoped
  queries) and **correct** for operational use cases. It cannot be down when
  the customer app needs it. Retention is operational: "what did I do last
  week."
- **Layer 2 (Log Analytics)** must be **durable**, **scannable at scale**,
  and **cheap per row**. It's OK if it's a few minutes behind. This is where
  security investigations live. "Did anyone access this org's data between
  January and March last year?"
- **Layer 3 (Firestore)** must be **immutable**, **append-only**, and
  **correlatable with live auth state**. This is the staff-action record.
  It's the canonical answer to "which staff member did what." Firestore
  security rules enforce the immutability in a way Postgres cannot (a
  Postgres superuser can always rewrite rows).

Mixing these (e.g. putting staff audit into Postgres) trades off against
all three properties at once. Keeping them separate gives you each
guarantee intact.

---

## 4. Layer 1 — Normalized Postgres view

The four module tables today almost certainly have different column shapes.
Unify them into a single SQL view (or materialized view if volume demands it).

### Schema

```sql
CREATE OR REPLACE VIEW v_activity_events AS
SELECT
  'activity_logs'::text            AS module,
  al.id::text                      AS event_id,
  al.org_id                        AS org_id,
  al.user_id                       AS actor_uid,
  COALESCE(al.actor_type, 'customer')::text AS actor_type,
  al.action                        AS action,
  al.target_type                   AS target_type,
  al.target_id                     AS target_id,
  al.created_at                    AS ts,
  al.payload                       AS payload        -- jsonb
FROM activity_logs al

UNION ALL

SELECT
  'pagers'                         AS module,
  pe.id::text                      AS event_id,
  pe.org_id                        AS org_id,
  pe.user_id                       AS actor_uid,
  COALESCE(pe.actor_type, 'customer')::text AS actor_type,
  pe.event_type                    AS action,
  'page'::text                     AS target_type,
  pe.page_id::text                 AS target_id,
  pe.ts                            AS ts,
  to_jsonb(pe)                     AS payload
FROM pagers_events pe

UNION ALL

SELECT
  'ams'                            AS module,
  ae.id::text                      AS event_id,
  ae.org_id                        AS org_id,
  ae.user_id                       AS actor_uid,
  COALESCE(ae.actor_type, 'customer')::text AS actor_type,
  ae.event_type                    AS action,
  ae.target_type                   AS target_type,
  ae.target_id                     AS target_id,
  ae.created_at                    AS ts,
  ae.details                       AS payload
FROM ams_events ae

UNION ALL

SELECT
  'ipam'                           AS module,
  ie.id::text                      AS event_id,
  ie.org_id                        AS org_id,
  ie.user_id                       AS actor_uid,
  COALESCE(ie.actor_type, 'customer')::text AS actor_type,
  ie.change_type                   AS action,
  'subnet_or_ip'::text             AS target_type,
  ie.resource_id                   AS target_id,
  ie.created_at                    AS ts,
  ie.diff                          AS payload
FROM ipam_events ie;
```

### Required indexes on each source table

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_<table>_org_ts
  ON <table> (org_id, created_at DESC);
```

Without this index, the view will table-scan each module at query time.

### `actor_type` values

The `actor_type` column is the **single most important field** in this design.
It answers: "who did this?"

| Value | Meaning |
|---|---|
| `customer` | Normal customer-app user action |
| `staff` | A Cloud Function performed this on behalf of staff (out-of-band action) |
| `staff_impersonating` | A staff user performed this while impersonating a customer (Phase 4) |
| `system` | Automated action by the system itself (e.g. auto-close after 24h) |

**Every module's write path must populate this field.** When Phase 4
impersonation lands, the customer app's write path must detect the
`atlas_impersonation` claim on the current auth token and tag `actor_type =
'staff_impersonating'` + `acting_staff_uid = <staff UID>` on every row it
writes.

Without this tagging, post-incident forensics cannot distinguish customer
actions from staff-impersonation actions — and the whole audit trail loses
its integrity.

### Materialized view upgrade path

If `v_activity_events` becomes slow at scale (likely at ~10k+ customers
with active usage), migrate to a materialized view refreshed every 5-10
minutes. Queries stay the same; only the refresh cadence is new.

---

## 5. Layer 1 — Internal API endpoint

Atlas reads Postgres via the **existing customer-app backend API**, not
directly. Add one new route:

```
GET /internal/orgs/:orgId/activity
  Query params:
    from        ISO8601 UTC, required
    to          ISO8601 UTC, required (max 90 days span)
    modules     comma-separated (default: all). e.g. "activity_logs,pagers"
    limit       default 200, max 1000
    cursor      opaque pagination token (event_id from last page)

  Response: 200 OK
  {
    "events": [
      {
        "module": "pagers",
        "eventId": "...",
        "actorUid": "...",
        "actorType": "customer",
        "action": "page_acknowledged",
        "targetType": "page",
        "targetId": "...",
        "ts": "2026-04-21T07:30:00Z",
        "payload": { ... }
      }
    ],
    "nextCursor": "..."
  }
```

### Authentication

Atlas sends the staff's Firebase ID token in the `Authorization: Bearer`
header. The endpoint verifies the token using Firebase Admin SDK, then
checks two things:

1. Token's `firebase.tenant` claim == `Atlas-Staff-2o08x`
2. Firestore `users/{uid}` has `isStaff == true` and `disabled != true`

If either fails → 403.

### Rate limit

Default 60 req/min per staff user. Prevents a compromised staff account from
scraping all customer activity at pace.

### Audit

This endpoint's access **must not** be logged to Postgres. Log it to
Firestore `staff_audit_logs` with `action: 'READ_CUSTOMER_ACTIVITY'`,
`targetType: 'org'`, `targetId: <orgId>`. This way the "who read what" trail
lives in the immutable store, not the same store the staff user could
theoretically suppress.

---

## 6. Layer 2 — Azure Log Analytics mirror

Two streams feed Layer 2:

### 6a. Customer activity → Log Analytics via Postgres CDC

**Pattern:** Debezium on Azure → Azure Event Hubs → Log Analytics workspace
custom-table `Atlas_ActivityCL`.

Debezium reads Postgres logical replication slots. Any insert into
`activity_logs`, `pagers_events`, `ams_events`, `ipam_events` flows through
Event Hubs → Log Analytics within ~1 minute.

Alternative (simpler if CDC feels too heavyweight): application-layer
dual-write. Each module writes to Postgres (synchronous) + pushes a copy
to Event Hubs (fire-and-forget). Acceptable if dropped events in the
analytics layer are tolerable (they usually are — this is forensic, not
operational).

### 6b. Staff audit → Log Analytics via Cloud Function trigger

Firestore `onDocumentCreated('staff_audit_logs/{logId}')` Cloud Function
mirrors each write to `Atlas_ActivityCL`:

```js
exports.mirrorAuditToLogAnalytics = onDocumentCreated(
  'staff_audit_logs/{logId}',
  async (event) => {
    const entry = event.data.data();
    await postToLogAnalytics({
      source: 'atlas_staff_audit',
      ts: entry.timestamp.toDate(),
      actorUid: entry.staffUid,
      actorType: 'staff',
      action: entry.action,
      targetType: entry.targetType,
      targetId: entry.targetId,
      payload: { reason: entry.reason, extra: entry.extra },
    });
  }
);
```

### Log Analytics schema (`Atlas_ActivityCL` custom table)

Flat columnar, queryable via KQL:

```
TimeGenerated   datetime     (auto from the platform)
Source          string       ('atlas_staff_audit' | 'postgres_cdc')
Module          string       ('activity_logs' | 'pagers' | 'ams' | 'ipam' | 'staff_audit_logs')
OrgId           string
ActorUid        string
ActorType       string       ('customer' | 'staff' | 'staff_impersonating' | 'system')
ActingStaffUid  string       (non-null when ActorType == 'staff_impersonating')
Action          string
TargetType      string
TargetId        string
EventId         string
PayloadJson     dynamic      (full jsonb payload for drill-down)
```

### Retention

Log Analytics default 30 days + archive tier up to 7 years. For staff audit
entries: tag with `archive_priority: 'high'` so they're kept the full 7
years regardless of workspace default.

### Example investigation queries (KQL)

```kql
// All staff actions on org XYZ in the last 90 days
Atlas_ActivityCL
| where OrgId == "XYZ"
  and ActorType in ("staff", "staff_impersonating")
  and TimeGenerated > ago(90d)
| order by TimeGenerated desc

// Any staff accessed customer data unusually many times in last 24h
Atlas_ActivityCL
| where ActorType == "staff"
  and TimeGenerated > ago(24h)
  and Action in ("VIEWED_CUSTOMER_DETAIL", "VIEWED_PII", "IMPERSONATED_USER")
| summarize Views=count() by ActorUid, OrgId
| where Views > 20
```

---

## 7. Layer 3 — Firestore staff_audit_logs

Already implemented in Atlas. Design notes:

- Rules enforce append-only (`allow update, delete: if false`). The only way
  to remove an entry is via Admin SDK, which requires a Firebase IAM
  role — a paper trail separate from Firestore itself.
- **All** privileged staff actions write here. Phase 1-8 already do.
- The "internal activity read" endpoint from §5 also writes here (with
  `action: 'READ_CUSTOMER_ACTIVITY'`).
- Writes to this collection should be **atomic with the action they describe**
  whenever the action is a state change. Cloud Functions wrap this pattern
  (see `cloud-functions/functions/atlas.js`). Client-side direct writes are
  acceptable only for read-action audits (e.g. `VIEWED_CUSTOMER_DIRECTORY`)
  where failure to audit doesn't leave the system in an inconsistent state.

---

## 8. Merging at the UI layer (Atlas Customer Activity Timeline)

When Atlas renders a single customer's activity, it should:

1. Query Firestore `staff_audit_logs` where `targetId == orgId` (already
   works).
2. Query `GET /internal/orgs/:orgId/activity?from=-90d&to=now` (pending).
3. **Merge chronologically** in the Flutter widget:
   - Staff actions: timeline dot + `[STAFF]` badge
   - Customer actions: timeline dot + module icon (pager / AMS / IPAM / log)
   - `actor_type == 'staff_impersonating'`: **amber** badge, `[STAFF AS
     CUSTOMER]`, with the impersonating staff UID shown. This is the critical
     visual that makes post-incident forensics possible.

The UI widget already exists in skeleton
(`lib/modules/customers/widgets/customer_activity_timeline.dart`) — the
`_CustomerEventsPlaceholder` card is explicitly labeled "pending backend
integration" and waits for §5's endpoint.

---

## 9. Phased implementation plan

For the backend team (or Hemal):

### Phase B1 — Postgres normalization (~1 week)
1. Audit current four-module schemas. Identify the minimal superset of
   columns needed for `v_activity_events`.
2. Add missing columns where needed (`actor_type`, `target_type`, `target_id`)
   with backfill scripts for existing rows.
3. Create `v_activity_events` view. Test query performance with a recent
   90-day window on the largest customer.
4. Add `(org_id, created_at DESC)` indexes on each source table.

### Phase B2 — Internal API endpoint (~3-4 days)
1. Add `GET /internal/orgs/:orgId/activity` route to the customer-app
   backend (same service as the existing APIs).
2. Implement Firebase ID token verification with staff-tenant + isStaff
   checks.
3. Rate limit (per-staff 60 req/min).
4. Audit to Firestore `staff_audit_logs` on every call.

### Phase B3 — Atlas UI integration (~1 day, Flutter-side)
1. Replace `_CustomerEventsPlaceholder` with a real list fetched from the
   internal API.
2. Merge streams (Firestore staff audit + Postgres customer activity) in
   the timeline widget.
3. Style `actor_type == 'staff_impersonating'` rows with amber treatment.

### Phase B4 — Log Analytics mirror (~3-5 days)
1. Provision Azure Log Analytics workspace.
2. Set up Debezium → Event Hubs → Log Analytics pipeline (or
   application-layer dual-write, decide based on team preference).
3. Add the `mirrorAuditToLogAnalytics` Cloud Function trigger for
   staff_audit_logs.
4. Verify sample events land in `Atlas_ActivityCL` custom table.
5. Document canonical KQL queries for security team.

### Phase B5 — Retention policies + cleanup (~1 day)
1. Configure Postgres table partitioning by month, drop partitions older
   than 2 years.
2. Configure Log Analytics retention tiers (30d hot, archive to 7y for
   staff_audit rows).
3. Firestore `staff_audit_logs` — no retention policy; keep forever.

Total: ~3 weeks backend work, 1 day Atlas work (B3).

---

## 10. What NOT to do

Explicit anti-patterns:

- **Don't put staff audit into Postgres.** You lose immutability. A
  Postgres superuser or runaway migration can rewrite audit rows. Firestore
  rules with `allow update, delete: if false` enforce immutability in a way
  Postgres can't match.
- **Don't put customer activity into Firestore.** Wrong tool for high-volume
  time-series data. Firestore costs $0.06/100k reads; Postgres costs $0 to
  re-scan.
- **Don't make Atlas query Postgres directly.** Atlas doesn't own customer
  data schemas. Direct Postgres access from Atlas means every backend change
  breaks Atlas. The internal API is the contract.
- **Don't skip the `actor_type` field.** Without it, post-incident you
  cannot answer "did staff cause this?" which is the #1 question after any
  incident involving a customer.
- **Don't stream customer activity to Atlas via Firestore.** Firestore
  listeners are for small reactive UIs, not high-throughput activity feeds.
- **Don't index by staff email anywhere.** Emails change. Always key by UID.

---

## 11. Open questions (to resolve with backend team)

1. **CDC vs dual-write for Layer 2?** CDC is more robust but heavier. Dual-
   write is simpler but loses events on Event Hubs outages. Call given team's
   operational comfort.
2. **Exact schema of the four module tables today?** Doc needs update once
   actual schemas are audited. The `v_activity_events` example is
   prospective.
3. **Does the customer app have an existing internal API service?** If yes,
   add the `/internal/orgs/:orgId/activity` route there. If not, the first
   internal route may want a separate deployment.
4. **SOC2 retention requirement confirmation.** Industry default is 7 years
   for audit; customer-facing SaaS sometimes 5. Legal/compliance should
   ratify.
