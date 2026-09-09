# Product Pulse - webinar runbook

Audience: Tim Hermans (host). No Teams admin or scripting knowledge assumed.

## Purpose and the one rule

Product Pulse is a monthly product-news session. Microsoft Teams webinars **cannot recur** - there is no "repeat monthly" option like a normal meeting. That means:

> **One webinar per pulse. Each one is a separate Teams webinar with its own registration link.**

There is no way around this in Teams today. The upside: each pulse gets its own registration page, its own attendee list, and its own attendance report, which is actually what we want for tracking.

**All 8 webinars for the season are created in one sitting, at season start** - not one per month. Doing them all at once means people can browse the landing page and register for several upcoming pulses in advance, rather than waiting for each month's webinar to appear. Webinars are created manually by Tim in the Teams calendar - there is no scripted or automated creation. This runbook documents that one procedure end to end: create all 8 webinars in Teams, publish each, paste the 8 registration links into the landing page in one batch, then run each pulse and publish its recording afterward.

## Why there is no script

Microsoft Graph's webinar create and publish endpoints (`POST /solutions/virtualEvents/webinars` and `.../publish`) are documented as "Application: Not supported" - only a signed-in user (delegated) can create or publish a Teams webinar, so no unattended, app-only automation was possible without Tim signing in anyway. With 8 webinars a season, creating them by hand in Teams is simpler than building and maintaining a delegated-sign-in script for that small a workload. This was the decision taken on 2026-09-09.

## Prerequisites

Before creating any webinar, confirm these are in place:

1. **Teams Enterprise webinar features.** Since 1 April 2026, the webinar features that used to require Teams Premium (custom registration emails, waitlist, manual approval, attendance reports, branding) are included in Teams Enterprise. No separate Premium purchase is needed - just confirm the tenant has these features turned on. If your "New meeting" menu shows a "Webinar" option, you have them.
2. **Tenant "anonymous join" enabled.** External (non-STAEDEAN) people need to be able to register and join. IT must confirm the tenant meeting policy allows anonymous/external join. If this is off, external registrants will not be able to complete registration or join.
3. **You are the organizer.** For Product Pulse, Tim Hermans is the organizer of every webinar.
4. **Marketing as co-organizer.** Add a marketing team member as co-organizer on each webinar so they can help manage registration, branding and chat without needing to be the account that created the webinar.

## Standard settings

Use the same settings for every one of the 8 webinars so Product Pulse looks and behaves consistently.

| Setting | Value |
| --- | --- |
| Naming convention | `Product Pulse - <Month YYYY> - <topic>` (e.g. `Product Pulse - October 2026 - Finance module roadmap`) |
| Duration | 45 minutes |
| Day/time | Fixed monthly slot, e.g. 2nd Tuesday of the month, **14:00 Europe/Amsterdam** |
| Access level | Public (anyone with the link can register, including people outside STAEDEAN) |
| Registration fields | Name, work email, company - required. "Which STAEDEAN products do you use?" - optional |
| Capacity | 1000 |
| Approval | No manual approval (registrants are confirmed immediately) |
| Branding | STAEDEAN logo, Miami Teal accent colour `#17c8be` |
| Co-organizer | One marketing team member |
| Teams reminder email | Default timing (currently 1 hour before start); adjust in the webinar's registration/communications settings if a different lead time is wanted |

Note: capacity, waitlist, manual-approval and the registration field list are set in the Teams registration-page UI - Microsoft Graph does not currently expose a documented way to set these at creation time, which is one more reason manual creation is no harder than a scripted one.

## Creating a webinar (Teams calendar)

1. Open the Teams calendar (Tim's own calendar, not a shared one - Tim must be signed in as himself).
2. Click **New meeting > Webinar**. [screenshot: New meeting dropdown showing "Webinar"]
3. **Basic details tab:**
   - Title: use the naming convention above, e.g. `Product Pulse - October 2026 - Finance module roadmap`.
   - Date/time: the fixed monthly slot, 45 minutes.
   - Time zone: Europe/Amsterdam (Central European Time).
   - Description: 2-3 sentences on what this month's pulse covers. [screenshot: webinar details form]
4. **Presenters tab:** add Tim as presenter/organizer (default), add the marketing co-organizer.
5. **Registration tab:**
   - Access level: **Public**.
   - Registration fields: keep name, email, company as required; add "Which STAEDEAN products do you use?" as an optional custom question.
   - Capacity: 1000.
   - Manual approval: off.
   - Waitlist: off (capacity of 1000 should not be reached; revisit if it ever is). [screenshot: registration settings panel]
6. **Branding tab:** upload the STAEDEAN logo, set the theme/accent colour to Miami Teal `#17c8be` if the branding options allow a custom colour; otherwise use the closest Teams theme and rely on the logo for brand recognition. [screenshot: branding panel]
7. **Email settings:** confirm the registration confirmation email and reminder timing (default 1 hour before). Adjust only if a different lead time is agreed. [screenshot: email/communications tab]
8. Click **Save** - the webinar is created in **draft**.
9. Click **Publish** (or the equivalent "make available for registration" action) so the registration page goes live. Until it is published, the registration link will not work for external visitors. [screenshot: publish confirmation]
10. Open the webinar again and go to the **Registration** tab - there is a **Copy registration link** (or "Get registration link") action. Copy that URL.

The website is the follow-the-webinar side of this: whatever date/time Tim actually sets in Teams for a given month is what must appear in `site/sessions.json` for that month's session - the page and the webinar must never disagree. If a date changes in Teams after the page was already updated, update `sessions.json` again to match.

### Where to paste the links

Once all 8 webinars are created and published, open `site/sessions.json` in the Product Pulse repo and paste each URL into its matching session's `registrationUrl` field, in a single batch edit for the season:

```json
{
  "id": "2026-10",
  "date": "2026-10-13T14:00:00+02:00",
  "title": "Finance module roadmap",
  "teaser": "What's shipping next in Finance, and why it matters.",
  "speakers": ["Tim Hermans"],
  "registrationUrl": "https://events.teams.microsoft.com/event/<webinar-id>@<tenant-id>",
  "recordingUrl": null,
  "status": "upcoming"
}
```

The easiest way to make this edit is to ask Claude in plain language (see `docs/04-editing-for-tim.md`) - Claude validates the JSON and commits/pushes for you. The fallback is a direct edit in the GitHub web editor, or the deploy helper in doc 03.

## Day-of checklist

- [ ] Join 10 minutes early; confirm audio/video and screen share work.
- [ ] Start recording as soon as the session opens (Teams: More actions > Record and transcribe > Start recording).
- [ ] Confirm presenter roles: Tim presents, marketing co-organizer manages chat and Q&A queue.
- [ ] Open the Q&A panel; monitor and promote good questions for live answering.
- [ ] Moderate chat - remove spam/off-topic links, keep discussion on the pulse topic.
- [ ] At the end, stop recording, thank attendees, mention the recording will be on the landing page.

## After the pulse

1. **Find the recording.** It lands in the organizer's (Tim's) OneDrive, in the **Recordings** folder, a few minutes to a few hours after the session ends.
2. **Download the MP4.**
3. **Upload to YouTube (unlisted).** Suggested template:
   - Title: `Product Pulse - <Month YYYY> - <topic>`
   - Description:
     ```
     STAEDEAN Product Pulse for <Month YYYY>: <one-line topic summary>.

     Watch upcoming pulses and register at https://pulse.staedean.com

     Speaker: Tim Hermans, STAEDEAN
     ```
   - Visibility: **Unlisted**.
4. **Paste the YouTube URL into `sessions.json`** for that session's `recordingUrl`, and set `status` to `past`. Commit and push.
5. **Download the attendance report** from the webinar (Teams calendar item > webinar > attendance report / "Download attendance list") and file it wherever Product Pulse reporting is tracked.
6. **Note on retention:** recordings in the organizer's OneDrive are subject to tenant recording-retention policy (commonly a default expiry after some weeks/months, tenant-configurable). Upload to YouTube promptly after each pulse so the recording is not lost if the OneDrive copy is cleaned up by policy.

## Troubleshooting

**External users cannot register.**
Check that the webinar's access level is set to Public, and confirm with IT that the tenant meeting policy allows anonymous/external join (see Prerequisites). If access is set to "People in my org," external users will never be able to register regardless of the link.

**Registration link shows the wrong time zone.**
Confirm the webinar was created with the date/time set to Europe/Amsterdam. The registration page usually localises to the visitor's browser time zone automatically; a wrong zone at creation time will shift every visitor's displayed time incorrectly.

**Waitlist.**
Waitlist is off in the standard settings (capacity 1000 should not be reached). If a particular pulse is expected to be unusually popular, turn on the waitlist for that one webinar in its registration settings before publishing.

**Cancelling or rescheduling a pulse.**
Use the webinar's **Cancel** action in the Teams calendar (this notifies all registrants automatically). Do not simply delete the calendar item. For a reschedule, cancel the original webinar and create a new one with a new registration link (Teams webinars cannot be moved to a new date without a new registration URL) - update `sessions.json` accordingly, set the old session's `status` to `cancelled`, and add the new session as a new entry.

## Sources

- Microsoft Learn, "Create virtualEventWebinar" (permissions, request/response shape): https://learn.microsoft.com/en-us/graph/api/virtualeventsroot-post-webinars?view=graph-rest-1.0
- Microsoft Learn, "virtualEventWebinar: publish": https://learn.microsoft.com/en-us/graph/api/virtualeventwebinar-publish?view=graph-rest-1.0
