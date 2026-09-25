# EGT Mobile (Flutter)

Eagle Goods Trading Co. — B2B sourcing & export app. Clean architecture:

- `lib/src/core/` — theme tokens, Dio networking (auth interceptor, single-flight
  token refresh, retry/backoff), secure storage, analytics, l10n, widgets, router
- `lib/src/domain/` — entities, repository contracts, use cases
- `lib/src/data/` — DTOs, remote data sources, repository implementations
- `lib/src/presentation/` — screens, widgets, Riverpod providers

**Status: scaffolded, NOT compiled** — Flutter SDK is not installed in this
environment. See `../../docs/mobile-build.md` for exact setup / run / release
commands.

Brand assets live in `assets/brand/` (copied from the live site, Phase 0 audit).
All copy/content rules come from `../../docs/site-audit.md`: real data only —
no invented products, testimonials, stats, countries, or certifications.
