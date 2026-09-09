# SDN Pulse

STAEDEAN Product Pulse: a monthly product webinar series. This repo holds the landing page (GitHub Pages) that lists upcoming and past sessions, plus the runbooks for running the series.

**Live**: <https://pulse.staedean.com/> (custom domain `pulse.staedean.com` planned, not yet switched over - see `docs/03-hosting-and-monthly-ops.md`).

- `site/` is the published page; edit `site/sessions.json` monthly (Tim, see `docs/04-editing-for-tim.md`) and `site/theme.css` for visual/brand changes (Marketing, see `docs/05-brand-changes-for-marketing.md`).
- `docs/` runbooks for Tim (webinars, sessions.json editing), Marketing (HubSpot, brand changes) and IT (hosting).
- `overview/` one-page visual overview.
- `scripts/` PowerShell deploy helper (webinars are created manually by Tim in Teams).

Deployed by `.github/workflows/deploy-pages.yml` on push to `main`.
