# Atlas — env separation rollout

Atlas mirrors the customer-app pattern: **staging** and **production**
each talk to their own Firebase project. We deliberately skip a "dev
Atlas" — staff QA happens on staging.

| Atlas env | Hosting site | Firebase project | Branch |
|---|---|---|---|
| Staging | `atlas-staging` (under `pagentz-staging`) | `pagentz-staging` | `staging` |
| Production | `atlas-prod` (under `pagentz-production`) | `pagentz-production` | `production` |

The old single-env Atlas at `atlas-13fd3.web.app` (target `atlas`)
stays for now as a fallback — push to that target manually if needed.

## What CI does

`atlas-web.yml` triggers on push to `staging` or `production`:
1. Resolves env → project → hosting target from the branch name.
2. Runs `flutter build web --dart-define=ENV=<env>`.
3. Cache-busts `main.dart.js` + the service worker.
4. Deploys with `firebase deploy --only hosting:<target> --project <project>`.

`workflow_dispatch` lets you re-run a deploy without re-pushing.

## Required GitHub secrets

Settings → Secrets and variables → Actions → New repository secret.

| Secret | How to get it |
|---|---|
| `FIREBASE_TOKEN` | Run `firebase login:ci` locally and paste the token. The CLI token has access to every Firebase project the logged-in account can reach, so a single token is enough for both staging + prod. |

(Once Rama unblocks `iam.disableServiceAccountKeyCreation` on staging +
prod GCP projects we can swap this for per-env service accounts via
`google-github-actions/auth@v2` — same as the customer-app's blocked
APK upload step.)

## One-time Firebase setup (manual, before first CI run)

These run from your laptop, **NOT** in CI. Done once per env, then
forgotten.

### 1. Firebase web-app registration — already done

Atlas shares the same web-app registrations the customer PagentZ app
already has in each Firebase project. The `apiKey` / `appId` /
`measurementId` values in `lib/firebase_options.dart` are copied straight
from the customer-app's `firebase_options_staging.dart` and
`firebase_options_prod.dart`. No new web-app registration needed.

### 2. Create the hosting sites

```bash
# Staging
firebase hosting:sites:create atlas-staging --project pagentz-staging

# Production
firebase hosting:sites:create atlas-prod --project pagentz-production
```

This gives you `https://atlas-staging.web.app` and
`https://atlas-prod.web.app`. (If those exact names are taken, pick
another and update `.firebaserc` + `firebase.json` to match.)

### 3. Wire the targets to the sites

```bash
firebase target:apply hosting atlas-staging atlas-staging \
  --project pagentz-staging

firebase target:apply hosting atlas-prod atlas-prod \
  --project pagentz-production
```

The first `atlas-staging` is the target name, the second is the site
name. The `.firebaserc` file already declares the mapping but
`target:apply` writes the local `.firebase/` cache CI needs.

### 4. Deploy the Atlas Cloud Functions to each env

Atlas has its own functions in `cloud_functions/` (e.g.
`atlasCreateStaff`, `atlasImpersonate`). Deploy once per env:

```bash
firebase deploy --only functions --project pagentz-staging
firebase deploy --only functions --project pagentz-production
```

### 5. Seed a staff user in each env's Firestore

In each project's Firestore Console, on `users/{rama-uid}` add:

```
isAtlas: true
staffRole: "owner"
mfaEnrolled: true
staffJoinedAt: <serverTimestamp>
```

Without this Atlas refuses to log Rama in.

### 6. (Optional) Custom domains

When ready, point `atlas.pagentz.com` → `atlas-prod` site and
`atlas-staging.pagentz.com` → `atlas-staging` site via the Firebase
Hosting custom-domain flow. Needs DNS records from Rama.

## How a release ships

1. Land changes on `atlas_v3` (or any feature branch) → PR → merge to
   `staging` → workflow auto-deploys to `atlas-staging.web.app`.
2. When staging passes review: merge `staging` → `production` →
   workflow auto-deploys to `atlas-prod.web.app`.

## Manually re-running a deploy

GitHub → Actions → "Atlas Web per env" → "Run workflow" → pick env from
the dropdown. Useful when only the dependencies of the build changed
(Firebase SDK update, etc.) without a code commit.
