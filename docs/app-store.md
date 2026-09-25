# EGT Play Store Listing Guide

**Status:** preparation only. No Play Console account exists, no release
keystore exists, no signed build has been produced, and nothing has been
submitted. Every "TODO" below names what unblocks it.

Grounded in: `apps/mobile/android/app/build.gradle` (application ID),
`android/app/src/main/AndroidManifest.xml` (permissions),
`lib/src/core/company/company_info.dart` (verified company facts),
`docs/site-audit.md` (real site copy). **No invented claims** — founding year,
email, stats and certifications follow the audit's restrictions.

---

## 1. Package & signing

| Item | Value | Status |
|---|---|---|
| Application ID | `com.eaglegoodstrading.egt` | In `android/app/build.gradle` (`namespace` + `applicationId`) |
| Dev flavor | `com.eaglegoodstrading.egt.dev` (`applicationIdSuffix ".dev"`) | Configured |
| Staging flavor | `com.eaglegoodstrading.egt.staging` (`applicationIdSuffix ".staging"`) | Configured |
| Release keystore | — | **TODO — needs-from-Sukh: generate and store securely; never commit** |
| Play Console account | — | **TODO — needs-from-Sukh** |
| App Links (`assetlinks.json`) | — | **TODO** — host on the production domain (see manifest comment) |

## 2. Store listing copy (draft — from real site copy only)

**App name:** EGT — Eagle Goods Trading Co.

**Short description (≤80 chars):**
> B2B sourcing & export from Punjab — request quotes, track RFQs.

**Full description (draft):**

> Made in Punjab. Ready for the World.
>
> Eagle Goods Trading Co. (EGT) is a B2B sourcing and export company operating
> from India with global reach. This app lets international buyers browse our
> export catalogue, submit quotation requests (RFQs), track them through to
> delivery, and message our trade desk — all in one place.
>
> • 16 export products across cleaning & hygiene, automotive care, industrial
>   supplies, and agri commodities — with specifications, order volumes and
>   express-sample availability
> • Request-a-quote flow with private-label / custom-packaging options
> • Live RFQ pipeline: from submitted to quoted, shipped and delivered
> • Secure document exchange (quotations, certificates, shipping documents)
> • Earn with EGT partner program for youth partners
>
> Quality products, global standard — commercial sourcing, OEM manufacturing
> and containerized export, managed end to end from India. If the product you
> need is not listed, we source it.
>
> Registered Business: GST Registered · IEC (DGFT) Registered ·
> MSME (Udyam) Registered · GeM Registered.
>
> Contact: +91 9876609948 · Village Gill, District Ferozepur, Punjab 142060, India ·
> Mon–Fri 9 AM–6 PM IST, Sat 10 AM–4 PM IST.

⚠️ Copy constraints (from the audit — do not "improve" these without Sukh):
- **No founding year** in the listing until the "EST. 2024" (logo) vs
  "Export Specialists since 2016" (contact page) conflict is resolved.
- **No email address** — none is published on the live site (Play requires a
  contact email: needs-from-Sukh).
- Registration pills use the word "Registered" only — **never numbers**.
- No ISO/FSSAI/APEDA/Global G.A.P. claims, no named export countries, no
  testimonials, no statistics beyond the site's four tiles.

**Category:** Business. **Content rating:** Everyone. **Contains ads:** No.
**In-app purchases:** None.

## 3. Graphic assets

| Asset | Spec | Status |
|---|---|---|
| App icon | 512×512 PNG | **TODO** — placeholder icons in repo; design from the real EGT logo (`apps/mobile/assets/brand/egt-logo.png`); do not redraw the logo |
| Feature graphic | 1024×500 | **TODO** |
| Phone screenshots | ≥2 (up to 8), 16:9 or 9:16 | **TODO** — capture on real device after first installable build |
| 7-inch / 10-inch tablet screenshots | optional but recommended | **TODO** |
| Promo video | optional | not planned for v1 |

## 4. Data safety (Play Data safety section) — draft answers

Derived from actual data flows in the backend (not from marketing copy):

| Question | Answer |
|---|---|
| Data collected | **Account data** (name, email, phone, password hash — never plaintext), **RFQ & order data** (requirements, budgets, delivery addresses, documents), **support messages**, **device push tokens** |
| Data shared with third parties | **No** third-party sharing in v1 (push is log-only; no analytics SDK wired) |
| Data encrypted in transit | **Yes** — HTTPS only (`usesCleartextTraffic="false"`); pending TLS provisioning on the server side |
| Data encrypted at rest (server) | Passwords argon2id; tokens SHA-256 hashed. Managed disk encryption — **TODO-needs-infra** |
| User can request data deletion | Via support ticket / contact; **no self-serve delete-account flow in v1** — disclose this |
| Children | Not targeted at children; B2B app |

Revisit these answers before submission if FCM, analytics, or crash reporting
get wired (they change the "data shared/collected" answers).

## 5. Permissions justification

From `android/app/src/main/AndroidManifest.xml`:

| Permission | Used by | Justification for Play |
|---|---|---|
| `INTERNET` | API calls | Core function — the app is a client of the EGT API |
| `ACCESS_NETWORK_STATE` | offline banner (`connectivity_plus`) | Show offline state; queue-friendly UX |
| `POST_NOTIFICATIONS` | FCM (`firebase_messaging`) | RFQ status changes, quote/shipment updates, partner messages (Android 13+ runtime permission) |
| `CAMERA` | `image_picker` | Attach photos to RFQs / private-label requests |
| `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` | `image_picker`/`file_picker` | Attach existing photos/videos as RFQ documents |
| `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | legacy fallback | Only on Android ≤12; scoped-media permissions used on 13+ |
| `USE_BIOMETRIC` | `local_auth` | Optional biometric app unlock (no data leaves the device) |

**Remove-if-unused rule:** if a permission's feature is cut before release
(e.g. FCM not wired → drop `POST_NOTIFICATIONS`; biometric dropped → drop
`USE_BIOMETRIC`), remove it from the manifest and update this table.

No location, contacts, SMS, or call-log permissions are requested — keep it
that way.

## 6. Release checklist (all TODO until infra/accounts exist)

- [ ] Play Console account created (needs-from-Sukh)
- [ ] Release keystore generated, backed up offline, **never in git** (needs-from-Sukh)
- [ ] `flutter build appbundle --flavor prod --obfuscate` succeeds on a Flutter-capable machine (no Flutter SDK on the build machine today — see `docs/mobile-build.md`)
- [ ] Internal testing track uploaded; installed on real devices; smoke-tested (login, catalogue, RFQ submit, push)
- [ ] Data-safety answers re-verified against the shipped build
- [ ] Permissions re-verified (remove-if-unused applied)
- [ ] Store listing copy + graphics finalised; content rating questionnaire done
- [ ] Privacy policy URL live (the website's `privacy-policy.php` returns HTTP 500 today — must be fixed or hosted elsewhere before submission)
- [ ] Contact email decided and published (Play requires it)
- [ ] Rollout: internal → closed → production

## 7. iOS — future notes

- Architecture is cross-platform-ready: `apps/mobile/ios/` exists
  (Flutter/Runner scaffold), FCM dependencies are declared cross-platform,
  and token storage uses Keychain via `flutter_secure_storage`.
- **No iOS submission work has started:** no Apple Developer account, no
  signing certificates/provisioning profiles, no APNs key, no TestFlight build,
  no App Store review preparation.
- When iOS begins: add APNs key to the push provider swap, configure
  `ios/Runner` signing, and repeat the data-safety/privacy work for App Store
  Connect (Apple's nutrition labels differ from Play's).
