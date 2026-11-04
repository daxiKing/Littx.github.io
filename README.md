# LITTX Website v2.0

A Next.js + TypeScript + Tailwind + Supabase starter based on the supplied LITTX lime/black design. This is a working foundation, not a claim that external merchant/Discord services are already configured or production-certified.

## Requirements
- Node.js 20.9+ (Node 22 LTS recommended)
- npm
- A Supabase project

## Run locally
1. Extract the ZIP and open this folder in VS Code.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and fill in the Supabase URL and anon key. Keep the service-role key server-only.
4. In Supabase SQL Editor, run `supabase/migrations/0001_initial.sql`, then `0002_storage.sql`.
5. In Supabase Authentication settings, configure your site URL (`http://localhost:3000`) and email confirmation redirect URLs.
6. Register your owner account through `/register`.
7. In Supabase SQL Editor, find its UUID in Authentication > Users and set it as `OWNER_USER_ID` in `.env.local`. Restart the dev server. Never allow public signup to set owner status.
8. Run `npm run dev` and open http://localhost:3000.

## Commands
- `npm run dev` — development server
- `npm run typecheck` — TypeScript check
- `npm run lint` — ESLint
- `npm run build` — production build
- `npm start` — production server

## Included functionality
- Responsive public landing/pricing/download pages retaining the lime-green visual style.
- Supabase email/password signup and login; email verification is controlled in Supabase Auth.
- User dashboard reading profile and entitlements.
- Atomic voucher redemption via a PostgreSQL `FOR UPDATE` RPC; one redemption per account per voucher; 30-day and forever entitlements.
- Owner-gated voucher generation API and admin overview. Every server admin operation must call `requireOwner()`.
- Private release bucket and authenticated API route that checks published state and entitlement before creating a 60-second signed URL.
- paysafecard checkout fails closed with a setup-required response. It does not collect PINs and does not pretend to take payment.

## Voucher generation API
`POST /api/admin/vouchers` with an authenticated owner session:
```json
{"count":5,"plan":"LITTX_PLUS","duration_days":30,"max_uses":1,"expires_at":null,"name":"Launch batch","description":"Optional note"}
```
Use `duration_days: 0` for forever vouchers. Codes are generated server-side.

## Uploading releases
Create a private bucket named by `RELEASES_BUCKET` (default `littx-releases`). Upload JARs using the Supabase dashboard or build an owner-only upload endpoint using the same `requireOwner()` guard. Insert release metadata into `public.releases` with the exact `storage_path`, `required_plan` (`FREE`, `LITTX_PLUS`, `LITTX_FIRE`) and `is_published=false`; publish only after verifying the artifact. Never expose public bucket URLs.

## Important remaining launch work
This project intentionally does not fake integrations. Before public production use, complete and test:
- paysafecard official merchant API adapter, webhook/callback signature verification, idempotency keys, reconciliation and provider-specific status polling. Use current docs and approved merchant credentials; do not accept or store PINs.
- Discord bot role assignment/removal worker with bot token, guild and role IDs; implement retries, expiry reconciliation and audit logs.
- Owner UI for user management, release upload/edit/delete, discounts, Discord settings, bans and audit log browsing. The owner overview and voucher-generation API are the initial admin foundation, not the entire requested admin console.
- Password reset UI, account settings, profile edit, terms/privacy content and real support contact.
- Rate limiting (use a shared store such as Upstash Redis or platform middleware; in-memory limits are not reliable on serverless deployments), CAPTCHA/abuse controls, security headers, monitoring, backups and restore drills.
- Additional RLS tests and automated integration tests for auth, voucher concurrency, expiration, role sync, and download authorization.

## paysafecard
The included `/api/payments/checkout` endpoint returns HTTP 503 until an official merchant adapter is implemented. Credentials alone do not make the flow active. Implement against the current paysafecard merchant documentation available to your approved merchant account. Confirm payment server-side before creating entitlements. Never request a paysafecard PIN on your site or in Discord.

## Discord
Use a bot you control, invite it with the minimum role-management permissions, and store the token only in server environment variables. Role sync should be driven by confirmed payment/voucher events and periodic expiry reconciliation, not client-side code.

## Deployment
Deploy to Vercel or another Node-compatible Next.js host. Add every `.env.example` variable in the host's server environment, configure Supabase Auth redirect URLs for the production domain, run migrations, verify the bucket is private, and set `OWNER_USER_ID`. Do not commit `.env.local`. Use HTTPS.

## Security notes
- The service-role key bypasses RLS; it is imported only by server modules and must never use a `NEXT_PUBLIC_` prefix.
- `OWNER_USER_ID` is compared server-side on each protected request. Hiding `/admin` is not authorization.
- Voucher redemption is atomic in PostgreSQL.
- File URLs are short-lived and created only after server-side access checks.
- A forever entitlement has `expires_at = NULL`; timed access is checked against the database clock.
- Review the SQL policies and adapt them to your final operational model before launch.
