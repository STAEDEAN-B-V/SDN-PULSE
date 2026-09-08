# Editing Product Pulse for Tim — no GitHub skills needed

This is for Tim (or whoever hosts Product Pulse). You do not need to know
Git, JSON, or GitHub to keep the landing page up to date — you talk to
Claude in plain English, Claude makes the change safely, and the page
updates itself within about a minute.

> **Not confirmed**: the exact current name and click-path for "connect
> GitHub to Claude" could not be verified against Anthropic's live support
> site while writing this doc (the specific help pages returned 404 /
> unrelated content). The steps below describe the feature generically —
> a connector/integration in Claude's settings that lets it read and write
> files in a GitHub repository you authorize. Confirm the exact menu wording
> in your own Claude account (Settings → Connectors, or ask Henry) before
> following step 2 for the first time.

## What you need (one-time)

1. **A Claude seat at STAEDEAN** — you should already have this.
2. **A GitHub account**, added to the STAEDEAN-B-V GitHub organization with
   **write** access to the `SDN-PULSE` repo. If you don't have a GitHub
   account or aren't a member yet, ask Henry (see "For IT" below).
3. **The GitHub connector enabled in Claude**, authorized for the
   `STAEDEAN-B-V/SDN-PULSE` repository specifically. This is a one-time
   setup — usually a "Connect GitHub" option somewhere in Claude's settings,
   which sends you to GitHub to sign in and approve access. If you can't
   find it, ask Henry — this can also be done through Claude Code instead,
   if IT prefers that route.

## How to start

Open Claude, make sure GitHub is connected (step 3 above), and just say
what you want changed. For example:

> "Open STAEDEAN-B-V/SDN-PULSE and change the topic of the December pulse
> to be about Copilot instead."

Claude reads the repo's `CLAUDE.md` and its `pulse-editor` skill
automatically — you don't need to reference them.

## Example prompts

1. "Change the topic of the November pulse to segregation of duties and
   compliance."
2. "Move the January pulse from the 12th to the 19th."
3. "Add the registration link for December —
   https://events.teams.microsoft.com/event/abcd1234/registration"
4. "The November recording is up on YouTube:
   https://www.youtube.com/watch?v=xyz789 — add it and mark that one past."
5. "Cancel the February pulse, we're skipping it this year."
6. "Add the 12 sessions for next season, same slot as usual — here are the
   topics: ..."

## What happens next

- Claude shows you a short **before/after** of exactly what it's about to
  change, so you can catch anything wrong before it goes live.
- Claude **commits and pushes** the change to the `main` branch of the
  repo (no separate approval step for routine edits — that's by design).
- The page **redeploys automatically** — a GitHub Actions workflow checks
  the file is valid, then republishes the site.
- Within about a minute, the live page reflects your change:
  **https://staedean-b-v.github.io/SDN-PULSE/**

## If Claude reports a validation error

If Claude says the file doesn't validate (broken JSON), it should stop and
fix it before committing — you shouldn't ever see broken JSON reach the
live site. If a red X still shows up on the repo's **Actions** tab after a
push:

1. Tell Claude "the Actions run failed, can you check why and fix it."
   Claude can read the failed run's log and correct the file.
2. If Claude can't resolve it, or you'd rather have a human look — ask
   Henry or Marketing (see Fallback below).

## Fallback

If the Claude/GitHub connector is unavailable, or you'd rather not use it
for a particular change:

- **Ask Henry** — he can make the edit directly, or help troubleshoot the
  connector.
- **Ask Marketing** — they can make the same edit through the GitHub web
  editor (open `site/sessions.json` in the repo, click the pencil icon,
  edit, commit) as a backup path. See `docs/03-hosting-and-monthly-ops.md`
  section 2.6.

---

## For IT (Henry)

**Add Tim's GitHub account to the repo with write access:**

```
gh api -X PUT repos/STAEDEAN-B-V/SDN-PULSE/collaborators/<tim-github-username> -f permission=push
```

(Replace `<tim-github-username>` with Tim's actual GitHub handle. If Tim is
already a member of the STAEDEAN-B-V org with a team that has push access
to this repo, this step may not be needed — check org team membership
first.)

**Suggested light branch protection** on `main` — block the two genuinely
destructive operations without adding an approval gate that would slow down
Tim's one-step flow (he still commits directly to `main`):

```
gh api -X PUT repos/STAEDEAN-B-V/SDN-PULSE/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  -f "required_status_checks=null" \
  -f "enforce_admins=false" \
  -f "required_pull_request_reviews=null" \
  -F "restrictions=null" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false"
```

This leaves direct commits to `main` fully allowed (no required PR, no
required review, no required status check) — it only prevents a force-push
from silently rewriting history and prevents the `main` branch itself from
being deleted. Verify the exact JSON body against the current GitHub REST
API docs for "Update branch protection" before running this, since the API
shape has changed across GitHub API versions.
