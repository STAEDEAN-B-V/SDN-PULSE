# Product Pulse - webinar runbook

Audience: Tim Hermans (host). No Teams admin or scripting knowledge assumed. A short IT appendix is at the end for Henry / IT.

## Purpose and the one rule

Product Pulse is a monthly product-news session. Microsoft Teams webinars **cannot recur** - there is no "repeat monthly" option like a normal meeting. That means:

> **One webinar per month. Each one is a separate Teams webinar with its own registration link.**

There is no way around this in Teams today. The upside: each pulse gets its own registration page, its own attendee list, and its own attendance report, which is actually what we want for tracking.

This runbook gives you three ways to create the 12 monthly webinars:

- **Path A** - manual, in the Teams calendar. Use this if you are creating one or two webinars, or if you want full control over wording each time.
- **Path B** - a script you run yourself (you sign in), which creates several webinars in one go from a list of dates and topics.
- **Path C** - a script Henry runs on your behalf. Read the note under Path C first - this path is more limited than it sounds.

Whichever path you use, the result is the same: a Teams webinar in **draft**, then **published**, with a registration link that goes on the Product Pulse landing page.

## Prerequisites

Before creating any webinar, confirm these are in place:

1. **Teams Enterprise webinar features.** Since 1 April 2026, the webinar features that used to require Teams Premium (custom registration emails, waitlist, manual approval, attendance reports, branding) are included in Teams Enterprise. No separate Premium purchase is needed - just confirm the tenant has these features turned on. If your "New meeting" menu shows a "Webinar" option, you have them.
2. **Tenant "anonymous join" enabled.** External (non-STAEDEAN) people need to be able to register and join. IT must confirm the tenant meeting policy allows anonymous/external join. If this is off, external registrants will not be able to complete registration or join.
3. **You are the organizer.** For Product Pulse, Tim Hermans is the organizer of every webinar. Being a Global Administrator or IT does **not** make someone the organizer - see the note under Path C.
4. **Marketing as co-organizer.** Add a marketing team member as co-organizer on each webinar so they can help manage registration, branding and chat without needing to be the account that created the webinar.

## Standard settings

Use the same settings every month so Product Pulse looks and behaves consistently.

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

Note: capacity, waitlist, manual-approval and the registration field list are set in the Teams registration-page UI (Path A) or the Teams calendar item after creation (Path B/C) - Microsoft Graph does not currently expose a documented way to set these at creation time (see the IT appendix).

## Path A - manual creation (Teams calendar)

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

### Where to paste the link

Open `site/sessions.json` in the Product Pulse repo and paste the URL into the matching session's `registrationUrl` field:

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

Commit and push the change (or use the fallback deploy script in doc 03) so the landing page picks it up automatically.

## Path B - scripted creation, delegated (you sign in)

Use `scripts/New-ProductPulseWebinars.ps1` in **Delegated** mode when you want to create several months at once from a list, but still want the webinars created "as you" (which they must be, since you are the organizer).

1. Fill in the sessions you want created in `site/sessions.json` (title, teaser, date/time, `registrationUrl` left as `null`).
2. Ask Henry (or IT) for the one-time app registration details: `-TenantId` and `-ClientId`. This app only needs the delegated `VirtualEvent.ReadWrite` permission - no admin consent should be required for a delegated, non-admin scope, but check with IT if your tenant restricts user consent.
3. Run, for example from a folder with PowerShell open:

   ```powershell
   .\scripts\New-ProductPulseWebinars.ps1 `
     -SessionsPath ..\site\sessions.json `
     -Mode Delegated `
     -OrganizerUpn tim.hermans@staedean.com `
     -TenantId <tenant-id> `
     -ClientId <app-client-id> `
     -WhatIf
   ```

4. The script opens a sign-in prompt (device code or browser). Sign in as yourself.
5. Review the `-WhatIf` output (which webinars would be created), then re-run without `-WhatIf` to actually create them.
6. The script writes each new registration URL back into `sessions.json`.
7. Open each created webinar once in the Teams calendar to check/adjust capacity, waitlist, manual approval, registration fields and branding (see "Standard settings" above) - the script cannot set these; they are Teams-only settings today.
8. Commit `sessions.json` and push (or run the fallback deploy).

## Path C - IT-run (app-only), and why it does not fully replace Path B

Henry (IT) can run the script on your behalf so you do not have to sign in every time. **Read this carefully: Global Admin rights alone do not make Tim the organizer, and - more importantly - Microsoft Graph does not currently support creating a webinar using pure app-only (application) permissions at all.** The `POST /solutions/virtualEvents/webinars` and `.../publish` endpoints are documented as "Application: Not supported" - only a signed-in user (delegated) can create or publish a webinar. Application permissions for virtual events exist, but only for **reading** webinars and attendance data that a user already created (`VirtualEvent.Read.All`), not for creating them.

In practice this means:

- **True app-only creation of webinars is not possible today.** Path C cannot be "Henry runs a background job with a client secret and it creates webinars as Tim" for the *creation* step.
- What Henry *can* do without Tim being present at every run: have Tim complete an interactive (or device-code) sign-in **once**, using an app registration with delegated `VirtualEvent.ReadWrite`. The Microsoft Graph PowerShell SDK can then reuse that cached, refreshed token for subsequent non-interactive runs, as long as the token is refreshed regularly (do not let it sit unused for months). This is still a **delegated** flow under the hood, just one where Tim's involvement is a one-time sign-in rather than a sign-in every run.
- Application permissions and the Teams application access policy (`VirtualEvent.Read.All`, `New-CsApplicationAccessPolicy`, `Grant-CsApplicationAccessPolicy`) are genuinely useful for a **different, future** purpose: an app-only job that reads attendance reports or registrant lists for webinars Tim already created, without needing Tim to sign in. That is a read-only automation, not a creation automation.

One-time IT setup, for the parts that *are* supported:

1. **App registration** in Entra ID (Henry): a single-page or public client app registration for the Product Pulse script, with delegated permission `VirtualEvent.ReadWrite` (used for creation, Path B, one-time or periodic Tim sign-in) and, if the read-only automation above is wanted later, application permission `VirtualEvent.Read.All` with admin consent.
2. **Admin consent** for the application permission (`VirtualEvent.Read.All`) if used - delegated `VirtualEvent.ReadWrite` for a non-admin scope typically does not need admin consent, but confirm against tenant consent policy.
3. **Teams application access policy**, only relevant to the application-permission (read-only) scenario:
   ```powershell
   Connect-MicrosoftTeams
   New-CsApplicationAccessPolicy -Identity ProductPulseReadPolicy -AppIds "<app-client-id>" -Description "Product Pulse - read webinars/attendance created by Tim"
   Grant-CsApplicationAccessPolicy -PolicyName ProductPulseReadPolicy -Identity <tim-object-id>
   ```
   Allow up to 30 minutes for the policy to take effect. This does **not** enable app-only creation - see above.
4. **Client secret or certificate**, stored in Keeper: if a confidential client is used for the delegated flow's token cache refresh, or for the future read-only app-only job, generate a client secret (or, preferred, a certificate) and store it in the team's Keeper vault. Never store it in the repo or in `sessions.json`.

Bottom line for Tim: expect to sign in once when Henry sets this up, and treat Path B (you sign in, Henry just hands you the script and IDs) as the realistic "scripted" path for creating webinars. Path C's app-only piece is for reading data later, not for creating webinars now.

## After creating a webinar: paste the link and commit

Whichever path was used, once a webinar is published and you have its registration URL:

1. Open `site/sessions.json`.
2. Find the session entry for that month and set `registrationUrl`:

   ```json
   "registrationUrl": "https://events.teams.microsoft.com/event/88b245ac-b0b2-f1aa-e34a-c81c27abdac2@f9448ec4-804b-46af-b810-62085248da33"
   ```

3. Commit the change on GitHub with a clear message, e.g. `Add registration link - October 2026 pulse`, and push (or commit directly on `main` via the GitHub web editor - see doc 03). The GitHub Actions workflow (see doc 03) redeploys the landing page automatically. Until this step is done, that row on the landing page shows "Registration opens soon" with a disabled button.

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
Confirm the webinar was created with `startDateTime`/`endDateTime` set to `Europe/Amsterdam` (or the Windows time zone "W. Europe Standard Time" if created via script). The registration page usually localises to the visitor's browser time zone automatically; a wrong zone at creation time will shift every visitor's displayed time incorrectly.

**Waitlist.**
Waitlist is off in the standard settings (capacity 1000 should not be reached). If a particular pulse is expected to be unusually popular, turn on the waitlist for that one webinar in its registration settings before publishing.

**Cancelling or rescheduling a pulse.**
Use the webinar's **Cancel** action in the Teams calendar (this notifies all registrants automatically). Do not simply delete the calendar item. For a reschedule, cancel the original webinar and create a new one with a new registration link (Teams webinars cannot be moved to a new date without a new registration URL) - update `sessions.json` accordingly, set the old session's `status` to `cancelled`, and add the new session as a new entry.

## Sources

- Microsoft Learn, "Create virtualEventWebinar" (permissions, request/response shape): https://learn.microsoft.com/en-us/graph/api/virtualeventsroot-post-webinars?view=graph-rest-1.0
- Microsoft Learn, "virtualEventWebinar resource type": https://learn.microsoft.com/en-us/graph/api/resources/virtualeventwebinar?view=graph-rest-1.0
- Microsoft Learn, "virtualEventWebinar: publish": https://learn.microsoft.com/en-us/graph/api/virtualeventwebinar-publish?view=graph-rest-1.0
- Microsoft Learn, "virtualEventWebinarRegistrationConfiguration resource type": https://learn.microsoft.com/en-us/graph/api/resources/virtualeventwebinarregistrationconfiguration?view=graph-rest-1.0
- Microsoft Learn, "Get virtualEventWebinarRegistrationConfiguration": https://learn.microsoft.com/en-us/graph/api/virtualeventwebinarregistrationconfiguration-get?view=graph-rest-1.0
- Microsoft Learn, "virtualEventSettings resource type": https://learn.microsoft.com/en-us/graph/api/resources/virtualeventsettings?view=graph-rest-1.0
- Microsoft Learn, "Configure an application access policy using the cloud communications API": https://learn.microsoft.com/en-us/graph/cloud-communication-online-meeting-application-access-policy
