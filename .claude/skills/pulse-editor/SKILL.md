---
name: pulse-editor
description: Use when Tim (or Marketing) asks to change, add, move, or cancel a Product Pulse session, update a topic/title/teaser, add a registration link, add a recording link, or list upcoming pulses — for the SDN-PULSE repo's site/sessions.json file.
---

# Pulse editor

Governs how Claude edits `site/sessions.json` in this repo on Tim's behalf,
in plain language, via the GitHub connector. See repo-root `CLAUDE.md` for
the full schema and validation commands — this skill is the step-by-step
procedure and worked examples.

## Procedure

1. **Read** the current `site/sessions.json` (fetch the file from the repo,
   don't guess at its contents).
2. **Apply the change** requested — the smallest edit that satisfies the
   request. Keep every other field on the session untouched.
   - `title` ≤ 70 characters, `teaser` ≤ 80 characters.
   - `registrationUrl` must start with `https://events.teams.microsoft.com/`
     or be `null`.
   - `recordingUrl` must be a `youtube.com` or `youtu.be` URL, or `null`.
   - New session `id` follows `pp-YYYY-MM`.
   - New session `date`: 14:00 Europe/Amsterdam, `+01:00` in winter /
     `+02:00` in summer, 2nd Tuesday by convention unless Tim says otherwise.
3. **Validate** the resulting JSON before committing:
   `python -c "import json;json.load(open('site/sessions.json'))"` (or the
   Node equivalent from `CLAUDE.md`).
4. **Show Tim a one-line before/after** of exactly what changed (field →
   old value → new value), so he can catch a mistake before it goes live.
5. **Commit and push to `main`** with message `sessions: <what changed>`.
6. **Confirm**: tell Tim the page redeploys automatically and should show
   the change within about a minute, and give the live URL:
   https://pulse.staedean.com/

## Guardrails

- **Never invent a URL.** If Tim says "add the registration link" without
  pasting one, ask him for it — don't fabricate a Teams or YouTube URL.
- **Ask if a date is ambiguous.** "Move it to March" without a day is not
  enough — confirm the exact date (and note the 2nd-Tuesday convention if
  relevant) before writing it.
- **Confirm before deleting a session.** Removing an entry from the array is
  the one destructive operation here — ask "just to confirm, delete pp-...
  entirely?" and wait for a yes. Cancelling (setting `status: "cancelled"`)
  does not need this confirmation, since nothing is destroyed.
- **Never edit any other file** (`index.html`, workflows, docs, scripts) in
  response to a sessions-editing request. If Tim's ask clearly needs a
  different file, say so and ask him to confirm explicitly first.
- If JSON validation fails after your edit, fix it before committing —
  never push invalid JSON.

## Worked examples (Tim's words → JSON change)

**1. Rename a topic**
> "Change the November pulse topic to be about the new Copilot features
> instead."

```diff
- "title": "Security and Compliance Studio: segregation of duties without the spreadsheet",
+ "title": "Copilot in D365: what's live today",
- "teaser": "How to review roles, resolve SoD conflicts and produce an audit trail inside D365, with the latest release changes.",
+ "teaser": "An honest look at what Copilot does with our data today, and what's next.",
```
Commit: `sessions: rename November pulse topic to Copilot`

**2. Move a date**
> "Push the January pulse back one week, to the 19th."

```diff
- "date": "2027-01-12T14:00:00+01:00",
+ "date": "2027-01-19T14:00:00+01:00",
```
Commit: `sessions: move January pulse to the 19th`

**3. Add a registration link**
> "The December webinar is live, here's the link:
> https://events.teams.microsoft.com/event/abcd1234/registration"

```diff
- "registrationUrl": null,
+ "registrationUrl": "https://events.teams.microsoft.com/event/abcd1234/registration",
```
(`status` stays `"upcoming"`.) Commit: `sessions: add registration link for December pulse`

**4. Add a recording link after the pulse**
> "November's done, recording is here:
> https://www.youtube.com/watch?v=xyz789. Mark it past."

```diff
- "recordingUrl": null,
- "status": "upcoming"
+ "recordingUrl": "https://www.youtube.com/watch?v=xyz789",
+ "status": "past"
```
Commit: `sessions: add recording and mark November pulse past`

**5. Cancel a pulse**
> "Cancel the February one, we're skipping it this year."

```diff
- "status": "upcoming"
+ "status": "cancelled"
```
(Ask whether Tim wants the row removed entirely instead — default to
`cancelled` unless he explicitly says to delete it.) Commit:
`sessions: cancel February pulse`

**6. Add next season's sessions**
> "Add the 12 pulses for the 2027-2028 season, same slot as usual, topics
> from the list I sent you."

Append 12 new objects to the `sessions` array, `id` `pp-2027-07` …
`pp-2028-06` (or whatever range fits the season), 2nd Tuesday 14:00
Europe/Amsterdam each month with the correct `+01:00`/`+02:00` offset,
`registrationUrl: null`, `recordingUrl: null`, `status: "upcoming"`, titles
and teasers from Tim's list (teaser ≤ 80 chars, title ≤ 70 chars — trim with
him if a topic runs long). Commit:
`sessions: add 2027-2028 season (12 pulses)`
