<#
.SYNOPSIS
    Creates Teams webinars for Product Pulse sessions listed in sessions.json and writes the
    resulting registration URL back into that file.

.DESCRIPTION
    Reads site/sessions.json. For each session where registrationUrl is null (not yet created)
    and the date is in the future, this script:
      1. Creates a draft virtualEventWebinar via POST /solutions/virtualEvents/webinars (Graph v1.0).
      2. Publishes it via POST /solutions/virtualEvents/webinars/{id}/publish.
      3. Reads the registration page URL via GET /solutions/virtualEvents/webinars/{id}/registrationConfiguration.
      4. Writes that URL back into the matching session's registrationUrl field in sessions.json.

    IMPORTANT - VERIFIED LIMITATION (see docs/01-webinar-runbook.md, Path C):
    Microsoft Graph documents creating and publishing a virtualEventWebinar as DELEGATED ONLY.
    The official permissions tables for both endpoints list "Application: Not supported."
    There is currently no application permission that allows a pure app-only (client
    secret/certificate, no signed-in user) call to CREATE or PUBLISH a webinar. The only
    application permission for virtual events is VirtualEvent.Read.All, which is read-only
    (webinars/attendance already created by a user) and requires a Teams application access
    policy (New-CsApplicationAccessPolicy / Grant-CsApplicationAccessPolicy).

    Because of this, -Mode AppOnly in this script does NOT attempt to create webinars. It
    connects app-only (useful for future read-only automation, e.g. pulling attendance reports)
    and then stops with a clear error before attempting a create/publish call that Microsoft
    Graph would reject. Use -Mode Delegated to actually create webinars; the organizer is
    whichever account completes the interactive/device-code sign-in, which must be
    -OrganizerUpn (normally tim.hermans@staedean.com). Global Admin rights on the caller's own
    account do NOT make that caller the organizer of a webinar created for someone else -
    delegated creation always runs as the signed-in user.

    Sources (fetched 2026-09-08):
      - https://learn.microsoft.com/en-us/graph/api/virtualeventsroot-post-webinars?view=graph-rest-1.0
      - https://learn.microsoft.com/en-us/graph/api/virtualeventwebinar-publish?view=graph-rest-1.0
      - https://learn.microsoft.com/en-us/graph/api/virtualeventwebinarregistrationconfiguration-get?view=graph-rest-1.0
      - https://learn.microsoft.com/en-us/graph/api/resources/virtualeventsettings?view=graph-rest-1.0
      - https://learn.microsoft.com/en-us/graph/cloud-communication-online-meeting-application-access-policy

    UNVERIFIED / NOT DOCUMENTED (flagged inline where used):
      - Whether "publish" is strictly required before registrationConfiguration.registrationWebUrl
        is populated. The docs do not say explicitly; this script calls Publish defensively
        because a new webinar's status is "draft" and only the organizer can publish.
      - Whether capacity, isWaitlistEnabled, isManualApprovalEnabled, registration question
        fields (name/email/company/custom questions) or branding can be set via Graph at
        creation time. The documented request body for POST /webinars only accepts:
        displayName, description, startDateTime, endDateTime, audience, coOrganizers,
        isRegistrationRequired, settings.isAttendeeEmailNotificationEnabled. Capacity/waitlist/
        approval appear only as READ-ONLY properties on the registrationConfiguration GET
        response, with no documented PATCH/update method found. Treat these as "must be set
        manually in the Teams UI after creation" until proven otherwise.
      - Exact coOrganizers identity shape requires both "id" (object id) and "tenantId" of the
        co-organizer; this script accepts a UPN and resolves it via Microsoft.Graph.Users if
        -CoOrganizerUpn is supplied, but that resolution step is a convenience, not something
        confirmed against the webinar-creation doc itself (the doc example uses a raw id/tenantId
        pair, not a UPN).

.PARAMETER SessionsPath
    Path to sessions.json (default: ..\site\sessions.json relative to this script).

.PARAMETER Mode
    'Delegated' (Tim or another organizer signs in; can create/publish webinars) or
    'AppOnly' (client secret/certificate; read-only per the limitation above - will not create
    webinars and exits with an explanatory error before attempting to).

.PARAMETER OrganizerUpn
    UPN of the intended organizer, e.g. tim.hermans@staedean.com. In Delegated mode this is used
    to verify the signed-in account matches; it does not itself set the organizer (Graph has no
    settable "organizer" field on create - the organizer is always the signed-in delegated user).

.PARAMETER TenantId
    Entra ID tenant ID (GUID) or verified domain.

.PARAMETER ClientId
    App registration (client) ID used for Connect-MgGraph.

.PARAMETER ClientSecret
    SecureString client secret, for AppOnly mode with a confidential client. Mutually exclusive
    with -CertificateThumbprint.

.PARAMETER CertificateThumbprint
    Certificate thumbprint, for AppOnly mode with certificate auth. Mutually exclusive with
    -ClientSecret.

.PARAMETER DurationMinutes
    Webinar length in minutes. Default 45, per the Product Pulse standard settings.

.PARAMETER DescriptionTemplate
    A template string for the webinar description body. Use {0} for the session teaser.
    Default: "{0}`n`nRegister to join live or to be notified when the recording is published on
    the Product Pulse landing page."

.PARAMETER TimeZoneId
    Windows time zone ID used for startDateTime/endDateTime. Default "W. Europe Standard Time"
    (covers Europe/Amsterdam, CET/CEST).

.EXAMPLE
    .\New-ProductPulseWebinars.ps1 -SessionsPath ..\site\sessions.json -Mode Delegated `
        -OrganizerUpn tim.hermans@staedean.com -TenantId <tenant-guid> -ClientId <app-guid> -WhatIf

.EXAMPLE
    $secret = Read-Host -AsSecureString "Client secret"
    .\New-ProductPulseWebinars.ps1 -Mode AppOnly -OrganizerUpn tim.hermans@staedean.com `
        -TenantId <tenant-guid> -ClientId <app-guid> -ClientSecret $secret
    # Exits with an explanatory error - AppOnly cannot create webinars today. See script header.

.NOTES
    ASCII-only. PowerShell 5.1 and 7 compatible. No ternary operator, no null-coalescing, no
    "&&"/"||" chains, per feedback_ps51_encoding.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $false)]
    [string] $SessionsPath = (Join-Path $PSScriptRoot '..\site\sessions.json'),

    [Parameter(Mandatory = $true)]
    [ValidateSet('Delegated', 'AppOnly')]
    [string] $Mode,

    [Parameter(Mandatory = $true)]
    [string] $OrganizerUpn,

    [Parameter(Mandatory = $true)]
    [string] $TenantId,

    [Parameter(Mandatory = $true)]
    [string] $ClientId,

    [Parameter(Mandatory = $false)]
    [System.Security.SecureString] $ClientSecret,

    [Parameter(Mandatory = $false)]
    [string] $CertificateThumbprint,

    [Parameter(Mandatory = $false)]
    [int] $DurationMinutes = 45,

    [Parameter(Mandatory = $false)]
    [string] $DescriptionTemplate = "{0}`n`nRegister to join live or to be notified when the recording is published on the Product Pulse landing page.",

    [Parameter(Mandatory = $false)]
    [string] $TimeZoneId = 'W. Europe Standard Time'
)

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if ($Mode -eq 'AppOnly') {
    if (-not $ClientSecret -and -not $CertificateThumbprint) {
        throw "AppOnly mode requires either -ClientSecret or -CertificateThumbprint."
    }
    if ($ClientSecret -and $CertificateThumbprint) {
        throw "Specify only one of -ClientSecret or -CertificateThumbprint, not both."
    }
}

if (-not (Test-Path -LiteralPath $SessionsPath)) {
    throw "Sessions file not found: $SessionsPath"
}

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    throw "Microsoft.Graph PowerShell SDK is not installed. Run: Install-Module Microsoft.Graph -Scope CurrentUser"
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# ---------------------------------------------------------------------------
# Connect
# ---------------------------------------------------------------------------

function Connect-ProductPulseGraph {
    param(
        [string] $Mode,
        [string] $TenantId,
        [string] $ClientId,
        [System.Security.SecureString] $ClientSecret,
        [string] $CertificateThumbprint
    )

    if ($Mode -eq 'Delegated') {
        Write-Host "Signing in (delegated). Complete the sign-in prompt as the intended organizer ($OrganizerUpn)." -ForegroundColor Cyan
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -Scopes 'VirtualEvent.ReadWrite' -NoWelcome
        $context = Get-MgContext
        $signedInUser = $context.Account
        if ($signedInUser -and ($signedInUser -ne $OrganizerUpn)) {
            Write-Warning "Signed-in account ($signedInUser) does not match -OrganizerUpn ($OrganizerUpn). Webinars will be created as $signedInUser, not $OrganizerUpn, because Graph has no settable organizer field on create - the organizer is always the signed-in delegated user."
        }
        return $context
    }
    else {
        Write-Host "Connecting app-only (client credentials)." -ForegroundColor Cyan
        if ($CertificateThumbprint) {
            Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome
        }
        else {
            $plainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
            )
            $secureCred = New-Object System.Management.Automation.PSCredential($ClientId, $ClientSecret)
            Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $secureCred -NoWelcome
            $plainSecret = $null
        }
        return Get-MgContext
    }
}

$graphContext = Connect-ProductPulseGraph -Mode $Mode -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -CertificateThumbprint $CertificateThumbprint

if ($Mode -eq 'AppOnly') {
    Write-Error @"
AppOnly mode cannot create or publish Teams webinars. Microsoft Graph documents
POST /solutions/virtualEvents/webinars and POST .../publish as delegated-only
(Application: Not supported). The only application permission for virtual events,
VirtualEvent.Read.All, is read-only and requires a Teams application access policy.

This connection succeeded and can be used for read-only work (e.g. a future script
that pulls attendance reports for webinars OrganizerUpn already created), but this
script's create/publish workflow requires -Mode Delegated with an interactive or
device-code sign-in by the organizer. See docs/01-webinar-runbook.md, Path C.
"@
    exit 1
}

# ---------------------------------------------------------------------------
# Load sessions
# ---------------------------------------------------------------------------

$sessionsRaw = Get-Content -LiteralPath $SessionsPath -Raw -Encoding UTF8
$sessions = $sessionsRaw | ConvertFrom-Json

if (-not $sessions) {
    throw "No sessions found in $SessionsPath"
}

$now = Get-Date
$targets = @()
foreach ($session in $sessions) {
    $hasNoRegistrationUrl = ($null -eq $session.registrationUrl) -or ($session.registrationUrl -eq '')
    $sessionDate = [datetime]$session.date
    if ($hasNoRegistrationUrl -and ($sessionDate -gt $now)) {
        $targets += $session
    }
}

if ($targets.Count -eq 0) {
    Write-Host "No sessions need a webinar created (all have a registrationUrl, or none are in the future)." -ForegroundColor Yellow
    return
}

Write-Host "Found $($targets.Count) session(s) to create." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Create + publish + read registration URL for each target session
# ---------------------------------------------------------------------------

$anyChanged = $false

foreach ($session in $targets) {

    $startDate = [datetime]$session.date
    $endDate = $startDate.AddMinutes($DurationMinutes)
    $description = [string]::Format($DescriptionTemplate, $session.teaser)

    $body = @{
        displayName = $session.title
        description = @{
            contentType = 'text'
            content     = $description
        }
        startDateTime = @{
            dateTime = $startDate.ToString('yyyy-MM-ddTHH:mm:ss')
            timeZone = $TimeZoneId
        }
        endDateTime = @{
            dateTime = $endDate.ToString('yyyy-MM-ddTHH:mm:ss')
            timeZone = $TimeZoneId
        }
        audience = 'everyone'
        isRegistrationRequired = $true
        settings = @{
            isAttendeeEmailNotificationEnabled = $true
        }
    }

    $bodyJson = $body | ConvertTo-Json -Depth 6

    $target = "webinar '$($session.title)' on $($startDate.ToString('yyyy-MM-dd HH:mm'))"

    if ($PSCmdlet.ShouldProcess($target, 'Create Teams webinar')) {

        try {
            Write-Host "Creating $target ..." -ForegroundColor Cyan
            $created = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/solutions/virtualEvents/webinars' -Body $bodyJson -ContentType 'application/json'
            $webinarId = $created.id

            Write-Host "Created webinar id $webinarId (status: $($created.status)). Publishing ..." -ForegroundColor Cyan
            Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/solutions/virtualEvents/webinars/$webinarId/publish" | Out-Null

            Write-Host "Reading registration URL ..." -ForegroundColor Cyan
            $regConfig = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/solutions/virtualEvents/webinars/$webinarId/registrationConfiguration"
            $registrationUrl = $regConfig.registrationWebUrl

            if (-not $registrationUrl) {
                Write-Warning "Webinar $webinarId was created and published, but no registrationWebUrl was returned. Check the webinar manually in the Teams calendar."
            }
            else {
                $session.registrationUrl = $registrationUrl
                $anyChanged = $true
                Write-Host "Registration URL: $registrationUrl" -ForegroundColor Green
                Write-Host "Reminder: capacity (1000), waitlist (off), manual approval (off), registration fields and branding are not set by this script (undocumented for Graph create) - set them manually in the Teams webinar's registration/branding tabs." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Error "Failed to create/publish webinar for session '$($session.id)': $($_.Exception.Message)"
        }
    }
}

# ---------------------------------------------------------------------------
# Write sessions.json back out
# ---------------------------------------------------------------------------

if ($anyChanged) {
    if ($PSCmdlet.ShouldProcess($SessionsPath, 'Write updated registration URLs')) {
        $updatedJson = $sessions | ConvertTo-Json -Depth 8
        Set-Content -LiteralPath $SessionsPath -Value $updatedJson -Encoding UTF8
        Write-Host "Updated $SessionsPath with new registration URLs." -ForegroundColor Green
    }
}
else {
    Write-Host "No sessions.json changes to write." -ForegroundColor Yellow
}

Disconnect-MgGraph | Out-Null
