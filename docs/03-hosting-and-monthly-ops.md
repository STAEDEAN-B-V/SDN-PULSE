# Product Pulse - hosting and monthly operations

Audience: Henry (IT) for one-time setup; marketing / Tim for the monthly loop. No prior GitHub experience assumed beyond following the steps below.

## 1. Overview

| | |
| --- | --- |
| Repo | [`github.com/STAEDEAN-B-V/SDN-PULSE`](https://github.com/STAEDEAN-B-V/SDN-PULSE) (public, org **STAEDEAN-B-V**, default branch `main`) |
| Hosting | GitHub Pages, served directly from the GitHub repo (Pages source: **GitHub Actions**) - **DONE**, first deploy succeeded 2026-09-08 |
| Live URL (current) | **<https://staedean-b-v.github.io/SDN-PULSE/>** (project-page subpath) - kept for now per the 2026-09-08 decision below |
| Custom domain | `pulse.staedean.com` - **pending**, see section 2.4 |
| HTTPS | Included, free, auto-renewing managed certificate |
| Site content | `product-pulse/site/` - `index.html`, `sessions.json`, `assets/`, `CNAME`, `.nojekyll` |
| Deploy path | GitHub repo, `main` branch, via `.github/workflows/deploy-pages.yml` |
| Fallback | `scripts/Deploy-Site.ps1` - `-Mode Commit` (convenience wrapper around git add/commit/push) or `-Mode GhPages` (legacy branch-based Pages, only if Actions-based Pages is disallowed) |

**Why GitHub Pages:**

- Free managed HTTPS certificate for the custom domain, auto-renewed, no extra resource to provision.
- The whole programme (site, docs, scripts, this overview) already lives in one folder; hosting it from the same GitHub repo means one place to look, one place to grant access, and no separate cloud resource to keep track of.
- A push to `main` under `site/**` deploys automatically via GitHub Actions - no separate pipeline product, no deployment token to store.
- Good enough for this workload: one small static page, no API, low, predictable traffic (see section 9 for exact limits).

**What is different from the previous design**, for anyone who read an earlier version of this doc: there is no cloud hosting resource to provision, no separate CI/CD repo, and no deployment token to manage. The old routing/headers config file and pipeline definition have both been removed from `site/`. The security headers that file used to set are now carried as a `<meta http-equiv="Content-Security-Policy">` tag in `site/index.html` (see section 5) because GitHub Pages cannot set custom HTTP response headers. See section 4 for the previous, still-available approach if it is ever needed again.

## 2. One-time GitHub setup

### 2.1 Create the repo

Decide where the repo lives:

- **Org repo** (e.g. `github.com/STAEDEAN/product-pulse`) - preferred if STAEDEAN has (or is willing to create) a GitHub organization. Easier to manage access as people join/leave, and the repo survives any one person leaving.
- **Personal repo** under an individual's account - fine to get started, but ties ownership/admin rights to that person's GitHub account. Migrate to an org later if this becomes a longer-lived asset.

**Public vs. private, and the licensing catch**: GitHub Pages needs the underlying content to be reachable, which is straightforward on a **public** repo on any plan, including the free plan. Publishing a GitHub Pages site from a **private** repository is a paid-plan feature - it requires GitHub Pro (for a personal account) or GitHub Team/Enterprise Cloud (for an organization); a private repo on a free personal or free organization plan cannot publish a Pages site from it. If keeping the repo private matters (e.g. `sessions.json` or docs should not be publicly readable) and there is no Pro/Team/Enterprise plan available, either accept a public repo (the landing page is public-facing marketing content anyway) or fall back to the cloud-hosted alternative in section 4. Confirm current plan-by-plan availability against GitHub's official plan comparison page before deciding, since GitHub can adjust what each plan includes.

1. Create the repo (`product-pulse`, org or personal, public unless a paid plan makes private practical).
2. Push the local `product-pulse/` folder (this whole tree - `site/`, `scripts/`, `docs/`, `.github/`, `overview/`) to `main`. The deploy workflow only triggers on changes under `site/**`, so the surrounding folders are safe to include in the same repo.

### 2.2 Enable Pages with source "GitHub Actions"

1. In the repo: **Settings > Pages**.
2. Under **Build and deployment > Source**, choose **GitHub Actions** (not "Deploy from a branch").
3. Nothing else to configure here yet - the workflow in `.github/workflows/deploy-pages.yml` handles the rest once it runs.

### 2.3 First deploy

1. Push to `main` with a change under `site/**` (or just push the initial commit), or trigger it manually: repo **Actions** tab > **Deploy Product Pulse site to GitHub Pages** > **Run workflow** (this uses the `workflow_dispatch` trigger).
2. Watch the run: it has two jobs, `validate` (JSON sanity check) then `deploy` (needs `validate` to pass first).
3. On success, the `deploy` job's environment shows the live URL. **Done** - the live URL is <https://staedean-b-v.github.io/SDN-PULSE/> (first deploy succeeded 2026-09-08). Open it to confirm the page loads.

### 2.4 Custom domain and DNS - PENDING (deferred by decision)

**Decision, 2026-09-08**: keep the current `https://staedean-b-v.github.io/SDN-PULSE/` URL for the moment. Switch to `pulse.staedean.com` later, when there's time to do the DNS + GitHub Pages settings change below. Because the site currently lives under the `/SDN-PULSE/` subpath, every link in `site/index.html` is a **relative** path, not root-absolute - this was verified by grepping for `href="/` and `src="/` in `site/index.html` (no hits). Keeping links relative means the later domain switch needs **no HTML change**.

**Where DNS lives**: `staedean.com` is hosted at **EuroDNS** (nameservers `ns1`-`ns4.eurodns.com`). Henry has access to the EuroDNS control panel.

**DNS record needed for the switch** (not yet created):

| Field | Value |
| --- | --- |
| Type | CNAME |
| Host | `pulse` |
| Target | `staedean-b-v.github.io` (add the trailing dot, e.g. `staedean-b-v.github.io.`, if EuroDNS requires a fully-qualified target) |
| TTL | 3600 |

**Switch procedure, when ready:**

1. In EuroDNS, add the CNAME record above under the `staedean.com` zone.
2. Set the custom domain on the repo - either in the GitHub UI (**Settings > Pages > Custom domain**, enter `pulse.staedean.com`, save) or via the API: `gh api -X PUT repos/STAEDEAN-B-V/SDN-PULSE/pages -f cname=pulse.staedean.com`.
3. Wait for GitHub's DNS check to go from pending to verified (minutes to a few hours depending on propagation).
4. Once verified, GitHub provisions a free managed certificate automatically (up to ~24 hours, usually faster). Tick **Enforce HTTPS** once the checkbox becomes available.

**Important - what actually sets the domain**: with the **GitHub Actions** Pages source (which this repo uses), a `CNAME` file inside the published site is **not** what configures the custom domain - the repo's **Settings > Pages** custom-domain value (or the `pages` API field) is the source of truth. `site/CNAME`, if present, is documentation only at this point and can be deleted without affecting anything; do not rely on it to set or change the live domain.

**Optional hardening, deferred**: org-level domain verification for `staedean.com` (adding a TXT record such as `_github-pages-challenge-staedean-b-v` under `pulse.staedean.com`, done once per org in **GitHub org Settings > Pages**) was considered and deferred. It is not required for the CNAME custom-domain setup above to work; it mainly prevents domain takeover/squatting scenarios and can be added later as a hardening step.

### 2.5 Branch protection (suggested)

Since a push to `main` deploys straight to production with no separate approval gate, consider a light branch protection rule on `main`:

- Require the `validate` job (or the whole `Deploy Product Pulse site to GitHub Pages` workflow) to pass before a pull request can merge, if edits go through PRs.
- Optionally require at least one review on pull requests touching `site/**`.

This is a suggestion, not a hard requirement - see section 2.6 for who edits `sessions.json` and how, since that choice affects whether branch protection is worth the friction.

### 2.6 Who edits `sessions.json` monthly, and how

Two workable options:

1. **Direct edit on `main` via the GitHub web editor** - open `site/sessions.json` in the GitHub UI, click the pencil/edit icon, make the change, commit directly to `main`. Fastest, no PR review step, matches how casual the previous "commit and push" monthly step already was.
2. **Via a pull request** - same web editor, but commit to a new branch and open a PR, optionally requiring the `validate` job to pass and/or a review before merging to `main`.

**Recommendation**: option 1 (direct edit on `main`) for the routine monthly edits (pasting a `registrationUrl` or `recordingUrl`, flipping `status`) - the `validate` job in the deploy workflow already catches a broken JSON edit before it reaches the live site, which is the main safety net the old ADO pipeline provided too. Reserve PRs for anything less routine (adding a whole new season's 12 sessions at once, or any change to `index.html`).

## 3. Fallback - `scripts/Deploy-Site.ps1`

With Pages source set to "GitHub Actions" (section 2.2), a normal `git push` to `main` is all that is needed - the workflow does the rest automatically. `scripts/Deploy-Site.ps1 -Mode Commit` is only a convenience wrapper around `git add` / `git commit` / `git push` for people who would rather run one command; it does not replace or bypass the GitHub Actions deploy.

```powershell
# dry run first
.\scripts\Deploy-Site.ps1 -Mode Commit -WhatIf

# real commit + push
.\scripts\Deploy-Site.ps1 -Mode Commit -CommitMessage "Add December pulse recording"
```

`-Mode GhPages` is a second fallback for the unusual case where Pages must run on the legacy "Deploy from a branch" source instead of "GitHub Actions" (for example, an org policy that disables Actions-based Pages deployments). It publishes `site/` straight to a `gh-pages` branch using `git subtree split` into a temporary worktree (chosen over `git subtree push` because the split-plus-worktree approach stays fast as repo history grows, since it doesn't re-walk the whole project history on every run). Only use this mode if section 2.2's "GitHub Actions" source is genuinely unavailable; it needs the Pages source flipped to "Deploy from a branch" pointing at `gh-pages` / (root) to have any effect.

Both modes validate `sessions.json` as JSON before doing anything else, so a broken manual edit is caught locally, on top of the same check running again in the `validate` job of the GitHub Actions workflow.

## 4. Alternative: Azure Static Web App connected to the same GitHub repo

If Azure hosting is ever required by policy (e.g. STAEDEAN standardizes on Azure for all customer-facing web content, or GitHub Pages' private-repo licensing catch in section 2.1 becomes a blocker), the same `product-pulse/site/` folder can be redeployed with an **Azure Static Web App configured with deployment source "GitHub"** instead of "Other" - Azure then manages its own GitHub Actions workflow against this same repo, giving back the free managed custom-domain HTTPS and the `staticwebapp.config.json`-based headers/routing that this design intentionally dropped in favor of the simpler, single-repo GitHub Pages setup. This would mean re-adding a `staticwebapp.config.json` and removing the meta-tag CSP from `index.html`, but no other structural change to the repo.

## 5. Post-deploy checks

Run these after the first deploy and after any change that touches tracking/forms/CSP:

- [ ] HubSpot tracking code (portal **2697631**) is present in `index.html`, loaded before `</body>` as per the design spec.
- [ ] The live domain (`pulse.staedean.com` or whatever is finally chosen) is added under **HubSpot > Settings > Website > Domains & URLs > Tracking Code** so HubSpot treats it as a known/tracked domain, not an unrecognized one.
- [ ] The placeholder HubSpot form `formId` in `index.html` (the "Never miss a pulse" embedded form) is replaced with the real form ID from the HubSpot form built per `docs/02-email-design.md` (subscription type "Product Pulse").
- [ ] `site/CNAME` is documentation-only under the GitHub Actions Pages source (see section 2.4) - not required while hosted at the default `staedean-b-v.github.io` URL; only relevant once/if the `pulse.staedean.com` switch happens, and even then the repo's Settings > Pages value is what actually governs the domain, not this file.
- [ ] If HubSpot, YouTube, or any other third party ever needs a new script/host, the `Content-Security-Policy` **meta tag** in the `<head>` of `site/index.html` must be updated first (`script-src`, `frame-src`, `img-src`, or `connect-src` as appropriate) or the browser will silently block it. Current CSP already allows: `js.hs-scripts.com`, `js.hsforms.net`, `js.hs-analytics.net`, `js.hsadspixel.net`, `js.hscollectedforms.net`, `js.usemessages.com` (scripts), `forms.hsforms.com` / `api.hubapi.com` / `forms.hscollectedforms.net` (forms/API), `www.youtube.com` / `www.youtube-nocookie.com` (video frames), `app.hubspot.com` (frame-src). **Update, 2026-09-08**: the allowlist now also includes Google Ads and LinkedIn Insight hosts - `googletagmanager.com`, `google-analytics.com`, `doubleclick.net` (Google Ads) and `snap.licdn.com`, `px.ads.linkedin.com` (LinkedIn Insight) - because HubSpot's tracking script loads these tags as configured by Marketing in HubSpot; this is a pass-through of HubSpot's own configuration, not a hand-added third party. Note: this meta-tag CSP has no `frame-ancestors` directive (not supported outside an HTTP response header), so it does not protect against the page being framed by another site - a minor regression versus the old header-based config, acceptable for a public marketing page with no login or sensitive actions.

## 6. Monthly operating loop

Owner column follows the plan's operating model (Tim as organizer/host; marketing helps with comms; Henry/IT only for infra).

| Timing | Task | Owner |
| --- | --- | --- |
| T-30 days | Create/publish the month's Teams webinar (see `docs/01-webinar-runbook.md`); copy its registration URL into `sessions.json` (`registrationUrl`) via Claude (see `docs/04-editing-for-tim.md`), commit on GitHub | Tim |
| T-10 days | Send the HubSpot "next pulse" invite (see `docs/02-email-design.md`) | Marketing |
| T-1 hour | Teams sends its own reminder to registrants automatically | (automatic, Teams) |
| T-0 | Run the pulse | Tim |
| T+1 day | Download the recording, upload to YouTube unlisted, paste the URL into `sessions.json` (`recordingUrl`), set `status` to `past`, commit on GitHub | Tim or marketing |

**Editing `sessions.json`**: Tim now does this via Claude in plain language
(Claude reads the repo's `CLAUDE.md` and `.claude/skills/pulse-editor/`,
validates, and commits/pushes for him) — see `docs/04-editing-for-tim.md`
for the setup and example prompts. Marketing remains the backup path via
the GitHub web editor described in section 2.6 above, for whenever Tim or
the Claude/GitHub connector is unavailable.

**Deploy trigger reminder**: a commit to `site/**` on `main` auto-redeploys via `.github/workflows/deploy-pages.yml` - no extra step, whether the edit was made through the GitHub web editor, a PR merge, or a local `git push` (with or without `Deploy-Site.ps1 -Mode Commit`). This replaces the old push-to-the-previous-CI-repo step one-for-one; everything else in the monthly loop is unchanged.

### Exact JSON edit example (one session, both edits)

Before (webinar not yet created):

```json
{
  "id": "pp-2026-12",
  "date": "2026-12-08T14:00:00+01:00",
  "title": "Rental: contract billing and equipment availability in the December release",
  "teaser": "What is new in STAEDEAN Rental for D365 F&SCM: billing schedules, availability checks and the fixes customers asked for.",
  "speakers": [
    { "name": "Tim Hermans", "role": "Product Manager, STAEDEAN" }
  ],
  "registrationUrl": null,
  "recordingUrl": null,
  "status": "upcoming"
}
```

T-30, after the webinar is published (paste the registration URL, `status` stays `"upcoming"`):

```json
  "registrationUrl": "https://events.teams.microsoft.com/event/88b245ac-b0b2-f1aa-e34a-c81c27abdac2@f9448ec4-804b-46af-b810-62085248da33",
  "recordingUrl": null,
  "status": "upcoming"
```

T+1, after the pulse and the YouTube upload (paste the recording URL, flip `status` to `"past"`):

```json
  "registrationUrl": "https://events.teams.microsoft.com/event/88b245ac-b0b2-f1aa-e34a-c81c27abdac2@f9448ec4-804b-46af-b810-62085248da33",
  "recordingUrl": "https://www.youtube.com/watch?v=<video-id>",
  "status": "past"
```

Everything else in the object (`id`, `date`, `title`, `teaser`, `speakers`) stays as-is.

### Adding next year's 12 sessions

Copy the pattern of the existing `pp-2027-*` entries in `sessions.json`:

1. Pick an `id` following the `pp-YYYY-MM` convention (e.g. `pp-2028-01` ... `pp-2028-12`).
2. Set `date` to the fixed monthly slot in ISO 8601 with the Europe/Amsterdam offset - `+02:00` for CEST months (roughly late March-late October) and `+01:00` for CET months (roughly late October-late March), per the note already in the file's `meta.note`.
3. Fill `title`, `teaser`, `speakers` from Tim's topic list for the year.
4. Leave `registrationUrl` and `recordingUrl` as `null` and `status` as `"upcoming"` until each webinar exists (per the webinar runbook, all 12 dates can be published up front - rows without a `registrationUrl` show a disabled "Registration opens soon" button).
5. Append the 12 new objects to the `sessions` array; commit on GitHub (direct to `main` or via a PR, see section 2.6 - a PR is the better choice for this larger, once-a-year edit).

**No HTML edits are needed for any of this.** `index.html` fetches `sessions.json` at load time (with a cache-busting query string, so a fresh edit shows immediately without a hard refresh) and splits sessions into "Upcoming" and "Past" automatically by comparing each session's `date` against the current date/time - not by the `status` field alone. Adding, editing or reordering sessions in the JSON is the only change required; the page re-sorts and re-renders on every load.

## 7. Local preview

Two equivalent options:

```powershell
python -m http.server 8200 --directory site
```

then open `http://localhost:8200`. Or use the `product-pulse` entry already defined in `.claude/launch.json`, which the Browser pane's `preview_start` tool can launch by name (serves the same `site/` folder on the same fixed port).

## 8. Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Actions run fails at "Validate sessions.json is valid JSON" | `sessions.json` has a syntax error (trailing comma, missing quote) from a manual edit | Run the same check locally: `python -c "import json; json.load(open('site/sessions.json'))"`. Fix the JSON, re-commit; the `deploy` job never runs because it `needs: validate`. |
| Page loads but shows a fetch error / no sessions render | `sessions.json` returns 404 (deploy didn't include it, or the artifact upload path in the workflow is wrong) or is invalid JSON that the browser's `fetch` + `JSON.parse` rejects | Check the deployed URL directly: `https://<site>/sessions.json`. If 404, confirm the `deploy` job's `upload-pages-artifact` step uses `path: site` and that the file exists at `site/sessions.json` in the repo. If invalid, validate as above. |
| 404 on the custom domain (`pulse.staedean.com` shows GitHub's 404, or does not resolve at all) | DNS CNAME record missing/wrong, `site/CNAME` missing or not matching the domain in Settings > Pages, or the domain has not passed GitHub's DNS check yet | Confirm the CNAME DNS record points at `<org-or-user>.github.io`; confirm `site/CNAME` contains exactly the same hostname as Settings > Pages > Custom domain; check the DNS check status in Settings > Pages and wait for propagation if it is still pending. |
| HTTPS certificate pending / "Enforce HTTPS" checkbox greyed out | Normal immediately after adding or changing a custom domain - GitHub has to issue a new certificate, which can take from a few minutes up to ~24 hours | Wait and refresh Settings > Pages. If it is still pending after 24 hours, re-check the DNS CNAME record is correct and stable (a flapping/incorrect record restarts certificate issuance). |
| HubSpot tracking, form, or embed is silently blocked / console CSP errors | A HubSpot host isn't in the `Content-Security-Policy` **meta tag** in `site/index.html`, or a new third-party script was added without updating it | Open browser devtools console for the exact blocked directive/host, add it to the matching CSP directive in the meta tag (see section 5), commit, wait for the workflow to redeploy. |
| Actions run for the workflow never triggers after a commit | The commit didn't touch anything under `site/**`, or it was made to a branch other than `main` | Confirm the change is under `product-pulse/site/` (relative to the workflow's `paths: site/**`) and pushed to `main`, or use the **Run workflow** button (`workflow_dispatch`) in the Actions tab to trigger it manually regardless of what changed. |

## 9. Cost and limits (GitHub Pages)

| Limit | Value |
| --- | --- |
| Published site size | 1 GB |
| Bandwidth | soft limit of 100 GB / month |
| Build/deploy frequency | soft limit of 10 builds per hour - **does not apply** when building and publishing via a custom GitHub Actions workflow (which this design uses), per GitHub's own documentation |
| Deployment timeout | 10 minutes per deployment |
| Custom domains | 1 apex/subdomain per Pages site (plus `www` alias handling) |
| Private-repo Pages publishing | Requires GitHub Pro (personal) or GitHub Team/Enterprise Cloud (organization) - not available on a free-plan private repo (see section 2.1) |
| Cost | $0 on a public repo on the free plan - no paid tier needed for this workload unless the repo must be private |

Product Pulse is a handful of KB of HTML/JSON/images and modest traffic, so headroom is large in every dimension. Confirmed against GitHub's official documentation (`docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages`, the GitHub Pages limits page, and the GitHub plans comparison page) 2026-09-08; re-check those pages before relying on these numbers long-term, as GitHub can revise plan features and limits.
