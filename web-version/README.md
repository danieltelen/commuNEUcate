# CommNEUcate Web

The standalone user site and admin portal use the same Supabase project as the Flutter app, so approved accounts and item statuses are shared across all three clients.

## User web

- Visit `/` to search and browse published items without an account.
- Google sign-ins are approved automatically after Google confirms the account. Email/password accounts still require administrator approval before submitting a report or using the mobile app.
- If an admin rejects a report, the feedback appears under **My Reports**, where the reporter can edit and resubmit it.
- **Download APK** downloads `app-release.apk` from the latest public GitHub Release. Each APK workflow run also stores a 30-day downloadable Actions artifact; that artifact requires a GitHub sign-in.

## Admin portal

Visit `/admin/` and sign in with an account whose `profiles.role` is `admin`. The dashboard shows report approvals, revalidations, users waiting for approval, and approved users. Admins can publish or reject reports with feedback and approve or deny user access. These changes are shared with the Flutter app.

The first administrator must be promoted once in Supabase SQL Editor after running `../supabase/setup.sql`:

```sql
update public.profiles
set role = 'admin', account_status = 'approved'
where email = 'admin@neu.edu.ph';
```

Run the setup SQL against the Supabase project configured in `lib/main.dart`. It creates the shared tables, row-level security policies, report-review fields, private report-answer storage, profile trigger, and image buckets. The web clients do not contain a service-role key.

For an existing project, run `../supabase/auto_approve_google_signups.sql` once in the Supabase SQL Editor. It updates the signup trigger and approves existing pending Google accounts; denied accounts and email/password accounts are unchanged.

## Run locally

From the repository root:

```sh
npx serve web-version -l 5173
```

## Deploy to Vercel

The repository includes `.github/workflows/vercel-deploy.yml`. It checks the web JavaScript on pull requests and deploys production when changes land on `main`.

1. Create or import a Vercel project. Set **Root Directory** to `web-version` and choose the **Other** framework preset.
2. Add these GitHub repository secrets under **Settings → Secrets and variables → Actions**:
   - `VERCEL_TOKEN`: a Vercel access token.
   - `VERCEL_ORG_ID`: the Vercel organization or account ID.
   - `VERCEL_PROJECT_ID`: the web project's ID.
3. Add your production domain to Supabase Auth's redirect URL allow list for Google sign-in.
4. Merge a change under `web-version/` into `main`, or run **Web Deploy** from the GitHub Actions tab.

## Build and publish the Android APK

The **Android APK** workflow builds the Flutter app and stores `app-release.apk` as a downloadable Actions artifact on every run. To publish the public download used by the web button:

- Push a version tag such as `v1.0.1`, or
- Run **Android APK** from the GitHub Actions tab and enter a version such as `v1.0.1` in `release_tag`.

The workflow creates or updates that GitHub Release with `app-release.apk` and its SHA-256 checksum. The web button then downloads the APK from the latest release. For a build without a public release, leave `release_tag` blank and download the artifact from that workflow run instead.

The APK workflow needs no extra GitHub secrets; it uses GitHub's built-in token to publish releases. New APKs include the current Flutter source and use the same Supabase project as both web portals.

Both web entry points use the same dark, purple, and teal visual system as CommNEUcate mobile.
