# SDN Pulse repo — instructions for Claude

This repo publishes the STAEDEAN Product Pulse landing page via GitHub Pages
(source: GitHub Actions, `.github/workflows/deploy-pages.yml`). Live URL:
**https://pulse.staedean.com/**. Repo: `STAEDEAN-B-V/SDN-PULSE`
(public — do not put secrets or tokens in any file here).

## The one rule

**Only edit `site/sessions.json` unless the user (Tim, Henry, or Marketing)
explicitly asks for something else.** Never touch `site/index.html` or its
`Content-Security-Policy` meta tag as a side effect of a sessions edit — that
file's CSP is deliberately locked down and changing it needs its own review.

## `site/sessions.json` schema

Top level: `{ "meta": {...}, "sessions": [ {...}, ... ] }`.

| Field | Meaning | Allowed values / format | Example |
| --- | --- | --- | --- |
| `id` | Stable identifier for the session | `pp-YYYY-MM`, one per month | `"pp-2026-11"` |
| `date` | When the pulse runs | ISO 8601 with UTC offset, local time 14:00 Europe/Amsterdam. Use `+01:00` in winter (CET, roughly late Oct–late Mar) and `+02:00` in summer (CEST). Convention is the 2nd Tuesday of the month, but any date/time is allowed if that's what was asked for | `"2026-11-10T14:00:00+01:00"` |
| `title` | Session title shown on the card | **Naming convention: `Product Pulse <Month>`** (e.g. `Product Pulse November`). Plain text, max 70 characters | `"Product Pulse November"` |
| `teaser` | One-line description under the title. **This is where the topic goes**, since the title is always `Product Pulse <Month>` | Plain text, **max 80 characters** | `"What's new in STAEDEAN Rental for D365 F&SCM."` |
| `speakers` | Array of speaker objects | `{ "name": string, "role": string }`, at least one entry (usually Tim Hermans) | `[{ "name": "Tim Hermans", "role": "Industry Director, STAEDEAN" }]` |
| `registrationUrl` | Teams webinar registration link | Must start with `https://events.teams.microsoft.com/` — otherwise use `null` | `"https://events.teams.microsoft.com/event/.../registration"` or `null` |
| `recordingUrl` | Published recording link | Must be a `youtube.com` or `youtu.be` URL — otherwise use `null` | `"https://www.youtube.com/watch?v=abc123"` or `null` |
| `status` | Lifecycle state | `upcoming` \| `past` \| `cancelled` | `"upcoming"` |

Notes:
- `index.html` also derives its own Upcoming/Past split by comparing `date`
  against "now" — it does not trust `status` alone for that split. Still,
  keep `status` accurate: use `cancelled` for a pulse that will not happen,
  and flip `upcoming` → `past` once the recording is added.
- Rows with `registrationUrl: null` render a disabled "Registration opens
  soon" button — that's expected for dates further out.
- Don't delete history casually. If asked to remove a session, confirm first
  (see the `pulse-editor` skill).

## Validating before every commit

Always validate the JSON parses before committing:

```
python -c "import json;json.load(open('site/sessions.json'))"
```

or, if Python isn't available:

```
node -e "JSON.parse(require('fs').readFileSync('site/sessions.json','utf8'))"
```

Never commit `sessions.json` if either check fails.

## Commit convention

Commit directly to `main` (this repo intentionally skips PRs for routine
`sessions.json` edits — see `docs/03-hosting-and-monthly-ops.md` section
2.6). Commit message format:

```
sessions: <what changed>
```

Examples: `sessions: add registration link for December pulse`,
`sessions: move January pulse to the 19th`, `sessions: cancel February pulse`.

## After pushing

`.github/workflows/deploy-pages.yml` runs a JSON validation job, then
redeploys the site — typically live within about a minute of the push. The
live page is **https://pulse.staedean.com/**.

## Also in this repo (do not edit unless asked)

- `docs/` — runbooks for webinars, HubSpot email, hosting/ops, and Tim's
  editing guide (`docs/04-editing-for-tim.md`).
- `overview/product-pulse-overview.html` — one-page visual overview (RACI,
  file map).
- `scripts/` — PowerShell helper (deploy fallback). Webinars are created manually by Tim in Teams; there is no creation script.
- `.claude/skills/pulse-editor/` — the skill that governs how Claude makes
  routine `sessions.json` edits when Tim asks in plain language.
