---
name: brand-editor
description: Use when Marketing (or anyone) asks to change colours, fonts, button styling, spacing, radii, or the footer on the Product Pulse landing page, or asks to "make it match the main website" / align it with the STAEDEAN brand — for the SDN-PULSE repo's site/theme.css file.
---

# Brand editor

Governs how Claude edits `site/theme.css` in this repo on Marketing's behalf,
in plain language, via the GitHub connector. See repo-root `CLAUDE.md` for
the two sanctioned edit surfaces (`sessions.json` for Tim, `theme.css` for
Marketing) — this skill is the step-by-step procedure and worked examples
for the visual one.

## Scope

**This skill edits `site/theme.css` only.** That file holds every visual
token as a plain hex value, grouped and commented with what each one
controls and where it shows on the page. It is loaded by `index.html`
before the inline style block, so a value changed there ripples through the
whole page without touching structure or behaviour.

## Procedure

1. **Read** the current `site/theme.css` (fetch it from the repo — don't
   guess at token names or values).
2. **Identify which token(s) the request maps to.** Read the comments in
   the file to find the exact token name — don't invent one. See the token
   map below for how plain-language requests usually translate.
3. **Apply the change** — edit only the value(s) of the matching token(s).
   Never add a new CSS rule or selector to `theme.css`; it holds values,
   not rules.
4. **Show a before/after table** of just the changed tokens (token name →
   old value → new value), so Marketing can catch a mistake before it goes
   live.
5. **Commit and push to `main`** with message `theme: <what changed>`.
6. **Confirm**: tell them the page redeploys automatically and should show
   the change within about a minute, and give the live URL:
   https://pulse.staedean.com/

## Guardrails

- **Never edit `index.html`** — not its structure, not its inline CSS
  rules, not the JS. If a request needs a structural or layout change (a
  new section, moving something around, a new component, changing how the
  page behaves), say so plainly and tell them to ask Henry rather than
  attempting it.
- **Never touch `sessions.json`.** That's Tim's file, governed by the
  `pulse-editor` skill — a brand request never needs it.
- **Never add new CSS rules to `theme.css`.** It is a values-only file. If
  the requested look genuinely needs a new rule (not just a new value),
  that's a structural change — hand it to Henry.
- **Keep contrast legible.** If a requested colour would make text hard to
  read against its background (e.g. a light button fill under white text,
  or a pale colour on the white page ground), say so before applying it and
  suggest a version that stays readable, or ask them to confirm they still
  want it.
- **One commit per request.** Don't bundle an unrelated second change into
  the same commit even if it seems convenient.
- If a request is ambiguous about which token it means (e.g. "make the
  buttons bigger" could mean padding, radius, or font size), ask which one,
  or apply the most literal reading and say so in the before/after.

## Token map (plain language → token group)

`theme.css` groups its tokens with comments — read the file to find the
exact name before editing, since names may shift slightly as the file
evolves. The groups to expect, per the brand alignment done 2026-09-09:

| Marketing says... | Token group to look in |
| --- | --- |
| "the register/CTA buttons should be [colour]" | **Buttons and links** — primary button fill/gradient |
| "the footer text is too small" | **Type** — small/legal text size |
| "the page feels cramped" / "give it more room" | **Shape and spacing** — shell max-width and section padding tokens |
| "the corners are too sharp/round" (cards, buttons) | **Shape and spacing** — radius tokens |
| "the links should be [colour]" | **Buttons and links** — default link colour |
| "the background/bands are the wrong colour" | **Page and bands** — page ground / band background tokens |
| "the headings/body text colour is off" | **Text** — heading ink / body ink tokens |
| "the eyebrow/label spacing looks off" | **Type** — letter-spacing token |
| "we want more/less of the teal" | **Brand colours** — accent token (teal is logo/accent only per the 2026-09-09 alignment, not a general fill colour) |

If a request doesn't clearly map to one of these groups, read `theme.css`
in full before answering — the comments name the exact token and what it
touches.

## Worked examples (Marketing's own words → token change)

**1. Match the main site's button colour**
> "Can you make the register buttons the same coral as the main site?"

Find the primary button fill/gradient token(s) in **Buttons and links**.
If it's already the coral gradient (per the 2026-09-09 alignment), confirm
that and stop — nothing to change. If a later edit drifted it, e.g.:

| Token | Before | After |
| --- | --- | --- |
| `--btn-primary-start` | `#17c8be` | `#fc8659` |
| `--btn-primary-end` | `#17c8be` | `#fa5a4f` |

Commit: `theme: restore coral primary button gradient`

**2. Footer text too small**
> "The footer text is too small on mobile, can you bump it up a touch?"

| Token | Before | After |
| --- | --- | --- |
| `--text-legal-size` | `12px` | `13px` |

Commit: `theme: increase footer legal text size`

**3. Page feels cramped**
> "The page feels a bit cramped on wide monitors, can we give it more
> breathing room?"

| Token | Before | After |
| --- | --- | --- |
| `--shell-max-width` | `1240px` | `1320px` |

Commit: `theme: widen page shell for more breathing room`

**4. Softer corners on cards**
> "Can the session cards have slightly softer corners?"

| Token | Before | After |
| --- | --- | --- |
| `--radius-card` | `8px` | `12px`

Commit: `theme: soften card corner radius`

**5. Link colour drifted**
> "The links in the body text still look teal, they should be the same
> coral as the buttons."

| Token | Before | After |
| --- | --- | --- |
| `--link-color` | `#17c8be` | `#fa5a4f` |

Commit: `theme: align link colour to coral`

**6. Structural request — refuse and redirect**
> "Can we add a second speaker card next to Tim's?"

This adds a new component to `index.html`, not a token change. Reply: "That
needs a structural change to `index.html`, not just a colour/spacing value
— I'll leave `theme.css` alone. Please ask Henry to add the second speaker
card." Do not touch any file.
