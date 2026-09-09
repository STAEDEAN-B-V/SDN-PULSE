# Product Pulse — HubSpot Email Design

Portal: **2697631** (NA region) — Marketing Hub Professional
Audience for this doc: marketing admin configuring HubSpot, and Tim Hermans as sender/voice.
Related docs: `01-webinar-runbook.md` (Teams webinar creation), `03-hosting-and-monthly-ops.md` (landing page + monthly ops).

---

## 1. Purpose and scope boundary

HubSpot's job in Product Pulse is **discovery only**: get the right people to the landing page (`https://pulse.staedean.com` or equivalent) — once at season kickoff, then a short reminder 2 days before each pulse. Nothing else.

**HubSpot does:**
- Hold the "Product Pulse" subscription and the audience list.
- Send the season kickoff email (once).
- Send a T-2 reminder email before each pulse (2 days out), suppressed for contacts already registered for that pulse (Section 4.b, Section 6.4).
- Receive registrant, attendee and cancellation data synced back from the Teams webinar via the native Microsoft Teams Webinars integration (Section 6) — this is part of the design, not an optional add-on.
- Report on opens/clicks/landing-page sessions per send, and registration/attendance per pulse from real synced data (Section 7).

**HubSpot explicitly does not:**
- Send registration confirmations, calendar invites, reminders, or cancellation notices — **Teams owns all of that** once someone clicks "Register" and completes Teams webinar registration.
- Create or publish webinars in Teams. The Microsoft Teams Webinars integration (Section 6) is **one-way (Teams → HubSpot)** — webinars are still created manually by Tim in the Teams calendar (`01-webinar-runbook.md`); that decision is unchanged.
- Host or link recordings by email — recordings are published on the landing page's "Past pulses" section (YouTube unlisted), not emailed out.
- Run a nurture/drip sequence. Two emails per year (kickoff) plus one per month (reminder) — nothing more.

If a future request asks HubSpot to "remind registrants" or "send the recording," that is out of scope for this design and duplicates what Teams already does — push back to the landing page + Teams model first.

---

## 2. Consent and audience

### 2.1 Subscription type

Create a new email subscription type, since this audience overlaps with but is distinct from existing STAEDEAN nurture/product marketing.

Menu path: **Settings (gear icon) → Marketing → Email → Subscription Types tab → Create subscription type.**

| Field | Value |
|---|---|
| Subscription name | Product Pulse |
| Description | Product news webinar invites from STAEDEAN (season kickoff + a reminder 2 days before each pulse). Shown to contacts on their subscription preferences page. |
| Language | English |
| Method of communication | Email |

Every Product Pulse send must be sent under this subscription type (set on the email's Settings tab), not under a general marketing/nurture type, so unsubscribes here don't touch other STAEDEAN mail and vice versa.

### 2.2 Custom contact property

Create a custom contact property to capture opt-in from the landing page form and any manual adds, independent of the subscription-type unsubscribe state (useful for reporting and for including contacts who subscribed before the property existed).

| Property | Type | Notes |
|---|---|---|
| `product_pulse_opt_in` | Single checkbox (boolean) | Set to true by the landing page's embedded HubSpot form ("Never miss a pulse") on submit. Not shown on contact record forms elsewhere. |

### 2.3 Audience segment ("Product Pulse audience")

HubSpot's list feature is now called **Segments** (formerly Lists) — menu path **CRM → Segments** (click **More** first if it isn't in the main sidebar) → **Create segment** → **Active segment**. The doc below still uses "active list" as the plain-English term familiar to marketing; "active segment" is the same thing in the current UI.

Recommended filter logic for the primary send list:

| Filter group | Condition |
|---|---|
| Lifecycle stage | is any of: Customer (add Opportunity/other prospect stages only if Tim confirms external prospects should be invited) |
| AND product/country (optional) | e.g. `Primary product` contains a value in scope, `Country` is any of the target markets — only if the audience needs narrowing beyond "all customers" |
| AND (subscribed OR opted-in) | `Product Pulse` subscription status is "Subscribed" **OR** `product_pulse_opt_in` is "Yes" — combine with an OR grouping so people who filled the landing-page form are included even before their first send sets subscription status |
| AND NOT | Email bounced status is "Hard bounced"; `Product Pulse` subscription status is "Unsubscribed" |

Set this as an **active** (not static) segment so new customers and new landing-page sign-ups flow in automatically each month without manual list maintenance.

### 2.4 Internal/staff list

Keep a **separate static or active list** ("Product Pulse — internal") for STAEDEAN staff who want the invite (sales, CS, partners team). Reasons to separate:
- Internal opens/clicks would otherwise skew external engagement metrics.
- Internal staff may want every pulse regardless of the product/country filters applied to customers.

### 2.5 GDPR notes

- The "Product Pulse" subscription type is what makes the monthly send GDPR/ePrivacy-compliant for EU contacts — always send under it, never under "no subscription type" or a catch-all marketing type.
- The landing-page form must state plainly what the contact is opting into (see Workstream 1 copy: "one invite per month, nothing else") — this doubles as the consent language.
- Unsubscribes via the subscription type must be respected immediately; do not re-add unsubscribed contacts via list logic (the "AND NOT unsubscribed" filter above already ensures a subscription-type unsubscribe removes someone from future sends automatically).
- Data privacy / legal basis settings, if enabled on the portal, may require a "Purpose of subscription" field on the subscription type — set this in line with STAEDEAN's existing subscription types for consistency.

---

## 3. Campaign

### 3.1 Create the campaign

Menu path: **Marketing → Campaigns → Create campaign.**

| Setting | Value |
|---|---|
| Campaign name | Product Pulse 2026 |
| Owner | Tim Hermans (or the marketing admin managing sends) |
| Assets attached | Season kickoff email, all 8 monthly invite emails, the landing page (as an external asset — see below) |

### 3.2 Attaching the external landing page

The landing page is hosted on GitHub Pages (served from the GitHub repo), not HubSpot CMS, so add it as an **external website page** asset (Marketing Hub Professional feature):

1. Install the HubSpot tracking code on the landing page first (already planned in Workstream 1 — snippet before `</body>`, portal 2697631, NA).
2. Open the campaign → **Add assets** → **External website pages** (left sidebar of the asset picker) → paste the landing page URL.
3. Once attached, visits to the external page from contacts are attributed to the campaign as influenced traffic, alongside email opens/clicks.

### 3.3 UTM convention

Apply this convention consistently on every link from a HubSpot email to the landing page:

```
utm_source=hubspot
utm_medium=email
utm_campaign=product-pulse-2026
utm_content=<month>          e.g. sep-2026, oct-2026 (kickoff email uses utm_content=kickoff)
```

Build these with **Tracking & Analytics → Tracking URLs → Create tracking URL** (left sidebar under Reports/Analytics tools) so HubSpot's own reporting ties clicks back to source/medium/campaign automatically, rather than hand-typing UTM strings into the email body links.

Note: the landing page's own "Register" buttons use a separate, simpler UTM set for on-page tracking (`utm_source=landing&utm_medium=web&utm_campaign=product-pulse-2026`, per the Workstream 1 spec) — that is unrelated to the email UTM set above and does not need to match it, since they measure different traffic origins.

### 3.4 Tracking settings for the external domain

Because the landing page lives on a separate domain (`pulse.staedean.com`) from HubSpot's own hosted pages, register it so tracked visits and campaign attribution work:

Menu path: **Settings → Tracking & Analytics → Tracking Code → Advanced Tracking tab → add the external domain/subdomain.**

Do this once, during setup (Section 8), before the first send goes out.

---

## 4. Emails

Both emails are written in Tim Hermans's voice: calm, informative, product-news — not a sales pitch. English only (external, multi-country audience). One CTA only: the landing page link. No secondary links, no "read more" clutter.

### 4.a Season kickoff (sent once per season/year)

**Goal:** Tell the whole audience the 2026 season exists, show all upcoming dates at a glance, get them to bookmark/register on the landing page.

**Subject line options:**
- "Product Pulse is back — here's the 2026 lineup"
- "Your monthly product update, on the calendar"
- "12 Product Pulse sessions, one page to track them"

**Preheader:** "30 minutes of STAEDEAN product news, every month. See what's coming and register."

**Copy outline:**
1. Opening line from Tim, first person: what Product Pulse is and why he's doing it monthly now (product news, roadmap, live Q&A).
2. One short paragraph: format — 30 minutes, online via Teams, recording available afterwards on the landing page.
3. Mention that dates for the rest of 2026 are already published, so they can plan ahead.
4. Single CTA button: **"See upcoming pulses"** → landing page (UTM `utm_content=kickoff`).
5. Short sign-off from Tim (name, title, no photo needed if already in the template header).

**Footer requirements:** STAEDEAN company address (CAN-SPAM/GDPR requirement), unsubscribe link (auto-inserted by HubSpot for the Product Pulse subscription type), link to STAEDEAN privacy policy, physical mailing address if required by portal's default footer settings.

### 4.b T-2 reminder (sent 2 days before each pulse)

**Goal:** Remind the audience of the specific upcoming date/topic and drive a single click to register on the landing page. A short-horizon nudge, not a save-the-date for the whole year — just the next one.

**Note on who receives this:** the send list is the "Product Pulse audience" segment **AND NOT** already Registered for that pulse's Marketing Event (Section 6.4) — so a registrant receives only the Teams T-1h reminder, not a second one from HubSpot. The suppression segment is what prevents the overlap between the two systems. Fallback, if the Teams Webinars integration is ever unavailable: send to the whole audience segment and accept the overlap, or suppress manually from a Teams registrant export.

**Subject line options:**
- "2 days to go: {topic}"
- "Product Pulse this {day of week}: {topic}"
- "{date} — this month's Product Pulse: {one-line topic}"

**Preheader:** "{Date} · 30 minutes · Live product news + Q&A with Tim Hermans."

**Copy outline:**
1. One-line topic teaser (what's new this month) — pulled from the same `sessions.json` teaser text used on the landing page, for consistency.
2. Date, time (CET, with a note that Teams shows local time on the registration page), duration (30 min).
3. One line reminding what they'll get: "what's new, why it matters, live Q&A" (same three pillars as the landing page).
4. Single CTA button: **"Register for this pulse"** → landing page's upcoming-pulse entry (UTM `utm_content=<month>`), not directly to the Teams registration URL — keeps the landing page as the single source of truth and lets HubSpot's tracking code capture the click-through session.
5. One line: "Can't make it? Recordings from past pulses are on the same page."

**Footer requirements:** same as kickoff — unsubscribe, privacy link, address.

### 4.c Template spec (STAEDEAN colours)

Build one drag-and-drop email template and clone it for each send (see Section 5 for why cloning beats a single dynamic template + workflow).

| Element | Spec |
|---|---|
| Header | Galaxy Black (#1f2342) band, STAEDEAN logo (reversed/light version), centered |
| Body background | Paper (#f5f5f5) |
| Body text | Dark neutral (Galaxy Black or near-black), system font stack (Aptos/Segoe UI fallback — email clients don't reliably support Gilroy/Manrope, so don't rely on a display font in email) |
| Accent / CTA button | Miami Teal (#17c8be) fill, white text, rounded corners, single button only |
| Links (text) | Sapphire (#00316c) |
| Divider / secondary accents | Sapphire (#00316c) thin rule, used sparingly (e.g. above footer) |
| Footer | Galaxy Black band or plain paper background with muted text; unsubscribe + address + privacy link |
| Layout | Single column, max 600px width (standard email-safe width), one hero line, one paragraph block, one CTA button, no multi-column grids, no background images |

Do not use Red (#fa5a4f) in these emails — reserved for accents elsewhere per the brand theme; a plain, calm two-colour (teal + sapphire) email keeps the "not salesy" tone.

---

## 5. Sending mechanics

### 5.1 Recommended: one scheduled send per pulse, cloned from one template

For the T-2 reminder, **clone the template/email 8 times (one per pulse) and schedule each individually**, rather than building a workflow keyed off a custom "next pulse date" property.

**Why this is simpler for a handful of sends per season:**
- No property to maintain (`next_pulse_date` or similar) that must stay in sync with `sessions.json` and the Teams webinar schedule — one more thing to get out of sync.
- No workflow logic (delay branches, re-enrollment guards) to build, test, and debug.
- Content changes every month anyway (topic teaser, date) — a static scheduled send is edited and reviewed like any other one-off campaign email, which matches how marketing already works with single sends.
- A workflow only pays for itself if the **audience** changes frequently (e.g. daily signups needing an automated "if opted in after date X, send email Y" trigger) — this list is a monthly active segment, not a rolling enrollment funnel.

**Click-path instructions (recommended path):**

1. **Marketing → Email → click into the existing template (or the previous month's email) → Actions → Clone.**
2. Rename per convention: `Product Pulse — Reminder — {Month} {Year}` (e.g. `Product Pulse — Reminder — Oct 2026`).
3. Update subject line, preheader, topic teaser paragraph, date/time, and the CTA button URL (landing page URL with that month's `utm_content`).
4. On the email's **Settings** tab: set **Subscription type** = Product Pulse; **From name** = Tim Hermans; **Reply-to** = Tim's address (see 5.2); confirm **Campaign** = Product Pulse 2026.
5. On the **Recipients** tab: send list = "Product Pulse audience" active segment (Section 2.3); exclude the internal staff list here if it's being sent separately, or include both if the internal list should get the same monthly cadence.
6. On the **Send/Schedule** step: choose **Schedule for later**, set the date 2 days before that month's pulse (T-2), and enable **Adjusted send time** (delivers within 5 minutes of the scheduled time, smooths deliverability — no exact-minute requirement here).
7. Review and schedule. Repeat for each pulse in the season (8 for the 2026-2027 season: Nov 2026 - Jun 2027) — do this in a single setup session at season kickoff so all of them are queued and only content needs occasional last-minute tweaks (e.g. if a topic teaser changes).

Do the same clone-and-schedule for the kickoff — it's a single one-off send using the kickoff template, no scheduling loop needed.

### 5.2 Alternative: workflow on a custom date property

Only pursue if the audience list is expected to change often enough that "everyone already on the December list should still get January's email automatically" becomes a real maintenance burden, or if send timing needs to react dynamically to a webinar date that could shift.

Outline:
1. Create a custom contact-level or company-level date property is not applicable here since the date is a *campaign* property, not a contact property — this needs a **workflow with a fixed enrollment trigger per month** (e.g. re-using one workflow with 8 manually scheduled "send email" actions gated by date, or 8 small workflows) rather than a single elegant automation. In practice this ends up nearly as manual as Section 5.1 while adding workflow debugging overhead — hence the recommendation above.
2. If pursued: one workflow per month, trigger = list membership in "Product Pulse audience" evaluated on a set date, action = send the month's cloned email, with a delay branch to avoid double-sends if list membership is re-evaluated.

Document this here for completeness; do not build it unless the recommended path in 5.1 proves insufficient after a season of use.

### 5.3 From name, reply-to, send-time, frequency

| Setting | Value |
|---|---|
| From name | Tim Hermans |
| From address | Tim's STAEDEAN mailbox (or a monitored marketing alias with Tim's name, if direct replies to his personal inbox aren't desired) |
| Reply-to | Same as From, or a monitored alias — must be a real, monitored inbox since this is a "calm, personal" send, not a no-reply |
| Send-time optimization | Use **Adjusted send time** (available on Professional) when scheduling each send — smooths delivery, avoids the "sent within the same minute as 1000s of other portals" deliverability dip. HubSpot's full **Send Time Optimization** (send-per-contact based on individual open history) may require Enterprise or list-size minimums — confirm availability in-portal before relying on it; if unavailable, a single fixed send time (e.g. Tuesday 10:00 CET) is a fine fallback. |
| Frequency cap | HubSpot's **email frequency safeguard** (Settings → Marketing → Email → Send Frequency) is an **Enterprise-only** feature — not available on Professional. Since Product Pulse is only 1 email/month plus 1/year, an automated cap adds little value here; the low, predictable cadence is itself the frequency control. No action needed unless the portal is later upgraded to Enterprise for other reasons. |

---

## 6. Microsoft Teams Webinars integration

This is part of the design, not an optional phase-2 add-on: it is what makes the T-2 reminder suppress already-registered contacts (Section 4.b) and what turns the KPI table in Section 7 from an estimate into real numbers.

### 6.1 What it is

HubSpot has a native **Microsoft Teams webinars** integration under Marketing Events. It is **one-way: Teams → HubSpot**. It does **not** create, publish or otherwise manage webinars in Teams — webinars are still created manually by Tim in the Teams calendar (`01-webinar-runbook.md`); that decision is unchanged. The integration only reads back what already happened on a webinar that already exists in Teams.

### 6.2 What syncs

Once a webinar is connected, its data syncs into the HubSpot **Marketing Events** object:
- Registrant, attendee and cancellation counts.
- Event name, date and time, organizer and description.
- Per-contact timeline events showing join time, leave time and attendance duration.
- Per-contact status — **Registered**, **Attended**, **Cancelled**, **No Show** — usable as segment/list filters, and marketing event data can also drive workflow enrollment.

**Thin-contact caveat:** a registrant not already in HubSpot is created as a new contact with **only First Name, Last Name and Email**. A previously deleted contact is not automatically recreated by a new registration.

**Tier requirement:** the connector itself is available on every HubSpot plan; the workflow-enrollment features that key off marketing event data need Professional or Enterprise. STAEDEAN is on Marketing Hub Professional, so both are covered.

### 6.3 One-time setup

Needs a HubSpot admin **and** a Microsoft admin, in this order:

1. Install the HubSpot app in Microsoft Teams **at admin level**, not user level.
2. Connect the integration on the HubSpot side (Marketing → Marketing Events settings, or the HubSpot App Marketplace listing for Microsoft Teams).
3. In PowerShell, connect to Microsoft Teams and grant an application access policy for HubSpot's app, scoped to the webinar organizer (Tim Hermans):

   ```powershell
   # Confirm Tim's exact userPrincipalName in Entra ID first.
   # The tenant pattern is Firstname.Lastname@staedean.com, but verify before running.
   Connect-MicrosoftTeams
   New-CsApplicationAccessPolicy -Identity "HubSpotTeamsWebinarsPolicy" -AppIds "0493df14-0cd5-4c89-b413-e0b9b90bbb17" -Description "HubSpot Teams Webinars integration"
   Grant-CsApplicationAccessPolicy -PolicyName "HubSpotTeamsWebinarsPolicy" -Identity "tim.hermans@staedean.com"
   ```

**Organizer-scoping caveat:** the access policy only covers webinars created by the organizer it is scoped to. If Tim stops being the organizer, or someone else creates a Product Pulse webinar, the policy has to be re-granted to the new organizer or that webinar's data will not sync — see the related note in `01-webinar-runbook.md`.

### 6.4 Using "Registered" as the T-2 suppression filter

1. Build a segment/list filter: **Marketing event registration** → "Registered for" → the specific pulse's Teams webinar event.
2. On the T-2 reminder's **Recipients** tab, send to "Product Pulse audience" **AND NOT** that filter (Section 4.b) — a registrant then gets only the Teams T-1h reminder, not a second send from HubSpot.
3. The same object's **Attended** filter is available after the pulse, feeding the attendance side of the KPI table (Section 7) without a separate export from Teams.

Sources: [Use HubSpot and Microsoft Teams webinars](https://knowledge.hubspot.com/integrations/use-hubspot-and-microsoft-teams-webinars), [Use marketing events](https://knowledge.hubspot.com/integrations/use-marketing-events).

---

## 7. Reporting

### 7.1 Campaign dashboard

Use the **Product Pulse 2026** campaign's built-in reporting (Marketing → Campaigns → Product Pulse 2026) for the standing view: sent/delivered, open rate, click rate, click-through to the external landing page (from the attached external asset), and influenced contacts/customers if revenue attribution matters later.

### 7.2 Monthly KPI table

Track per pulse (marketing fills this in monthly — pull email stats from the cloned send, landing sessions from the landing page's analytics/HubSpot tracking, and registered/attended/no-show counts plus attendance duration directly from the Marketing Event record, Section 6.2, rather than estimating):

| Month | Sent | Opened | Clicked | Landing sessions | Registered | Attended | No-show | Avg. attendance duration |
|---|---|---|---|---|---|---|---|---|
| Sep 2026 | | | | | | | | |
| Oct 2026 | | | | | | | | |
| ... | | | | | | | | |

Attendance also shows per contact on the contact record's timeline (join time, leave time, duration), so an individual attendee's engagement can be checked without pulling the whole table.

Open/click rates below STAEDEAN's usual benchmark, or a big gap between clicks and registrations, are the signal to revisit subject lines or the landing page's upcoming-pulse copy — not to add more emails.

---

## 8. Checklists

### 8.1 One-time setup (before first send)

- [ ] Create subscription type "Product Pulse" (Section 2.1).
- [ ] Create custom contact property `product_pulse_opt_in` (Section 2.2).
- [ ] Build active segment "Product Pulse audience" with lifecycle/subscription/exclusion filters (Section 2.3).
- [ ] Build separate internal/staff list (Section 2.4).
- [ ] Create campaign "Product Pulse 2026" (Section 3.1).
- [ ] Install HubSpot tracking code on the landing page; confirm it fires (check Tracking Code health in Settings).
- [ ] Add the landing page's domain under Tracking & Analytics → Tracking Code → Advanced Tracking (Section 3.4).
- [ ] Attach the landing page as an external website page asset on the campaign (Section 3.2).
- [ ] Build the STAEDEAN-colour email template (Section 4.c).
- [ ] Draft and schedule the season kickoff email (Section 4.a).
- [ ] Clone and schedule one T-2 reminder email per pulse (8 for the 2026-2027 season) (Section 5.1), each with correct date/topic/UTM.
- [ ] Confirm From/Reply-to mailbox for Tim is monitored (Section 5.3).
- [ ] Set up the monthly KPI tracking table (Section 7.2) wherever marketing keeps reporting (this doc, a shared sheet, or a HubSpot dashboard).
- [ ] Install the HubSpot app in Microsoft Teams at admin level (Section 6.3) — Marketing + IT.
- [ ] Connect the Microsoft Teams Webinars integration on the HubSpot side (Section 6.3) — Marketing + IT.
- [ ] In PowerShell, grant the Teams application access policy for HubSpot's app, scoped to Tim as organizer (Section 6.3) — IT.
- [ ] Build the "Registered for this pulse" suppression segment and wire it into the T-2 reminder's exclusion list (Section 6.4) — Marketing.

### 8.2 Monthly checklist (marketing, ongoing)

- [ ] T-2 days before the pulse: confirm that month's cloned reminder still has the correct topic teaser (sync with Tim/`sessions.json`) before it sends.
- [ ] Before that same T-2 send: confirm the suppression segment (Section 6.4) has picked up that pulse's registrants.
- [ ] Confirm the CTA link's UTM `utm_content` matches that month.
- [ ] After send: spot-check open/click numbers land in the normal range; flag anomalies.
- [ ] After the pulse: update the KPI table (Section 7.2) with landing sessions, registered/attended/no-show counts, and attendance duration.

---

## 9. Sources

- [Create subscriptions for buyers / subscription types overview](https://knowledge.hubspot.com/subscriptions/create-subscriptions)
- [How do subscription preferences and types work](https://knowledge.hubspot.com/contacts/how-do-subscription-preferences-and-types-work) — subscription type creation path and fields
- [Create active or static lists (Segments)](https://knowledge.hubspot.com/lists/create-active-or-static-lists) — confirms "Lists" is now "Segments," menu path CRM → Segments
- [Create campaigns](https://knowledge.hubspot.com/campaigns/create-campaigns)
- [Associate assets and content with a campaign](https://knowledge.hubspot.com/campaigns/associate-assets-and-content-with-a-campaign)
- [Associate external website pages with campaigns](https://knowledge.hubspot.com/campaigns/associate-external-pages-campaigns) — external page asset flow, Professional/Enterprise requirement
- [Create tracking URLs](https://knowledge.hubspot.com/settings/how-do-i-create-a-tracking-url)
- [Install the HubSpot tracking code](https://knowledge.hubspot.com/reports/install-the-hubspot-tracking-code)
- [Set up sources tracking](https://knowledge.hubspot.com/reports/set-up-sources-tracking) — Advanced Tracking / external domain registration
- [Create and send marketing emails](https://knowledge.hubspot.com/marketing-email/create-and-send-marketing-emails) — cloning, scheduling, adjusted send time, send speed
- [Set up an email frequency safeguard](https://knowledge.hubspot.com/marketing-email/set-up-an-email-frequency-safeguard) — confirms Enterprise-only
- [Use HubSpot and Microsoft Teams webinars](https://knowledge.hubspot.com/integrations/use-hubspot-and-microsoft-teams-webinars) — one-way sync, setup steps, access policy
- [Use marketing events](https://knowledge.hubspot.com/integrations/use-marketing-events) — Marketing Events object, segment filters, thin-contact creation behaviour

### Not confirmed in this pass (verify in-portal)

- Whether **Send Time Optimization** (per-contact adaptive timing, distinct from "Adjusted send time") is available on this Marketing Hub Professional portal or requires Enterprise/a minimum list size — confirm in-portal under the email scheduling step.
