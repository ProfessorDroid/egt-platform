# @egt/shared
Shared TypeScript types for the EGT mobile and admin apps.

- `openapi.yaml` — the API contract, generated from the backend Swagger document.
  Regenerate: `cd apps/backend && npm run openapi:export`
- `src/index.ts` — hand-written shared types.
- `src/generated/api.d.ts` — machine-generated types from the YAML.
  Regenerate: `npm install && npm run generate` (needs network for openapi-typescript)
