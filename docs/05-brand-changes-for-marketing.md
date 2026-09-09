# Editing Product Pulse's look for Marketing — no GitHub skills needed

This is for Marketing. You do not need to know Git, CSS, or GitHub to
change how the Product Pulse landing page looks — you talk to Claude in
plain English, Claude edits the one file that's safe to change, and the
page updates itself within about a minute.

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
   if IT prefers that route. (This is the same connector Tim uses for his
   own edits — see `docs/04-editing-for-tim.md` — so if he's already set
   it up, you're doing the same thing.)

## What's safe to change yourself vs. what needs Henry

**Safe — any value in `site/theme.css`:**

- Colours (buttons, links, page background, bands, text)
- Fonts and text sizes
- Spacing, padding, and corner radius (cards, buttons)
- Footer text size

`theme.css` is a single file of named colour and spacing values, each
commented with what it controls. Claude reads it, changes only the value(s)
your request maps to, and shows you exactly what changed before it commits.
It cannot break the page's layout or logic by editing this file, because
the file only holds values — no structure, no behaviour.

**Needs Henry — anything that changes how the page is built:**

- New sections or components (a second speaker card, a new content block)
- Moving things around on the page (reordering sections, changing the
  layout grid)
- Anything touching how the page works (the JavaScript, the data it loads,
  the security policy, `sessions.json`)

If you ask for one of these, Claude will say so and point you to Henry
rather than attempting it.

## How to ask

Open Claude, make sure GitHub is connected (step 3 above), and just say
what you want changed in plain language. For example:

1. "Make the register buttons the same coral as the main site."
2. "The footer text is too small on mobile, can you bump it up a touch?"
3. "The page feels a bit cramped on wide monitors, give it more breathing
   room."
4. "Can the session cards have slightly softer corners?"
5. "The links in the body text still look teal — they should be coral, to
   match the buttons."
6. "Can we make the primary button a bit bigger?"

Claude reads the repo's `CLAUDE.md` and its `brand-editor` skill
automatically — you don't need to reference them.

## What happens next

- Claude shows you a short **before/after table** of exactly which
  colour/spacing values it's about to change, so you can catch anything
  wrong before it goes live.
- Claude **commits and pushes** the change to the `main` branch of the
  repo (no separate approval step for a token-value change — that's by
  design, same as Tim's `sessions.json` workflow).
- A **GitHub Actions** workflow runs automatically to validate and publish
  the site.
- Within about a minute, the live page reflects your change:
  **https://pulse.staedean.com/**

**If something looks wrong after a change**, open the repo's **Actions**
tab (github.com/STAEDEAN-B-V/SDN-PULSE → Actions) — a green check means the
deploy succeeded; a red X means it failed and the previous version is still
live. Tell Claude "the Actions run failed, can you check why and fix it."

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Change isn't visible yet | Browser cache, or the ~1 minute deploy hasn't finished | Wait a minute, then hard-refresh (Ctrl+Shift+R on Windows, Cmd+Shift+R on Mac) |
| Red X in the Actions tab | The CSS value broke validation, or an unrelated deploy issue | Tell Claude "the Actions run failed, can you check why and fix it" |
| Colour looks wrong on mobile | Some tokens (font sizes, spacing) can look different at a small screen even though the value is the same | Ask Claude to check how the token renders at a mobile width, or ask for a mobile-specific tweak if one exists |
| You want to undo a change | — | Ask Claude "please revert the last theme commit," or ask Henry to do it in GitHub directly |

## For IT (Henry)

**Add a Marketing GitHub account to the repo with write access:**

```
gh api -X PUT repos/STAEDEAN-B-V/SDN-PULSE/collaborators/<github-username> -f permission=push
```

(Replace `<github-username>` with the person's actual GitHub handle. If
they're already a member of the STAEDEAN-B-V org with a team that has push
access to this repo, this step may not be needed — check org team
membership first.)

## Brand source of truth

The brand book and **https://staedean.com** are the source of truth for
colours, type, and spacing on this page — `theme.css` should track them,
not the other way around. The Product Pulse page was aligned to
staedean.com's styling (coral CTAs, light-only, slim footer) on
**2026-09-09**. If staedean.com's own styling changes later, `theme.css`
should be updated to follow it, using this same Claude workflow or by
asking Henry for a larger re-alignment pass.
