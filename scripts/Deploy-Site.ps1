<#
.SYNOPSIS
    Manual helper for the Product Pulse landing page under GitHub Pages hosting.

.DESCRIPTION
    Primary deploy path: push to main. Once the GitHub repo has Pages configured
    with Source = "GitHub Actions" (see .github/workflows/deploy-pages.yml and
    docs/03-hosting-and-monthly-ops.md), any commit that touches site/** on the
    main branch is picked up automatically by the workflow. There is normally
    nothing for this script to do.

    This script exists for two fallback situations where that automatic path is
    not available:

    Commit    Validates sessions.json, then runs git add/commit/push for the
              site folder against the current repo's main branch. Use this when
              you have a normal git checkout of the repo but just want a single
              command for "validate, commit, push" instead of typing three.
              This still goes through the GitHub Actions workflow above - it is
              a convenience wrapper around a plain commit, not a separate
              deploy mechanism.

    GhPages   Publishes the contents of site/ directly to a gh-pages branch,
              for the rare case where Pages must be configured with the legacy
              "Deploy from a branch" source instead of "GitHub Actions" (for
              example, an org policy that disables Actions-based Pages
              deployments). This mode uses `git subtree split` plus a
              temporary worktree rather than `git subtree push`, because
              subtree push re-walks the whole project history on every run,
              which gets slow as the repo grows; a throwaway worktree checked
              out from an orphan-style history for just the site/ subtree is
              fast and always starts clean. If you go this route, also flip
              the GitHub Pages source in Settings > Pages to "Deploy from a
              branch" pointing at gh-pages / (root).

.PARAMETER Mode
    Commit or GhPages.

.PARAMETER CommitMessage
    Commit mode. Message for the commit. Default: "Update Product Pulse site".

.PARAMETER Remote
    Name of the git remote to push to. Default: origin.

.PARAMETER Branch
    Commit mode. Branch to commit and push to. Default: main.

.PARAMETER SitePath
    Folder to deploy/commit. Default: the site folder next to this script.

.PARAMETER WhatIf
    Show what would happen without making any git changes or pushing.

.EXAMPLE
    .\Deploy-Site.ps1 -Mode Commit -WhatIf

.EXAMPLE
    .\Deploy-Site.ps1 -Mode Commit -CommitMessage "Add December pulse recording"

.EXAMPLE
    .\Deploy-Site.ps1 -Mode GhPages -WhatIf

.NOTES
    ASCII only, Windows PowerShell 5.1 compatible.
    Requirements: git on PATH, and a working clone of the repo with a remote
    (default name "origin") that points at the GitHub repo.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Commit', 'GhPages')]
    [string] $Mode,

    [Parameter()]
    [string] $CommitMessage = 'Update Product Pulse site',

    [Parameter()]
    [string] $Remote = 'origin',

    [Parameter()]
    [string] $Branch = 'main',

    [Parameter()]
    [string] $SitePath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string] $Message)
    Write-Host ("[Product Pulse] " + $Message)
}

function Test-Command {
    param([string] $Name)
    $cmd = Get-Command -Name $Name -ErrorAction SilentlyContinue
    return ($null -ne $cmd)
}

# ---------------------------------------------------------------------------
# Resolve and validate the site folder / repo root
# ---------------------------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

if ([string]::IsNullOrWhiteSpace($SitePath)) {
    $SitePath = Join-Path $repoRoot 'site'
}

if (-not (Test-Path -LiteralPath $SitePath)) {
    throw ("Site folder not found: " + $SitePath)
}
$SitePath = (Resolve-Path -LiteralPath $SitePath).ProviderPath

$required = @('index.html', 'sessions.json')
foreach ($file in $required) {
    $full = Join-Path $SitePath $file
    if (-not (Test-Path -LiteralPath $full)) {
        throw ("Required file missing from the site folder: " + $file)
    }
}

if (-not (Test-Command -Name 'git')) {
    throw "git was not found on PATH. Install Git for Windows and try again."
}

Write-Step ("Site folder : " + $SitePath)
Write-Step ("Mode        : " + $Mode)

# Validate sessions.json so a broken schedule never reaches production.
try {
    $jsonRaw = Get-Content -LiteralPath (Join-Path $SitePath 'sessions.json') -Raw -Encoding UTF8
    $null = ConvertFrom-Json -InputObject $jsonRaw
    Write-Step "sessions.json parses as valid JSON."
}
catch {
    throw ("sessions.json is not valid JSON: " + $_.Exception.Message)
}

# ---------------------------------------------------------------------------
# Mode: Commit  (normal path: push to main, GitHub Actions deploys it)
# ---------------------------------------------------------------------------

if ($Mode -eq 'Commit') {

    Write-Step "Reminder: pushing to main with changes under site/** triggers"
    Write-Step ".github/workflows/deploy-pages.yml automatically. This mode is"
    Write-Step "just a convenience wrapper around git add/commit/push."

    Push-Location -LiteralPath $repoRoot
    try {
        $status = & git status --porcelain -- site
        if ([string]::IsNullOrWhiteSpace($status)) {
            Write-Step "No changes under site/ to commit."
            return
        }

        Write-Step "Changed files under site/:"
        $status -split "`n" | ForEach-Object { Write-Host ("  " + $_) }

        $target = ($Remote + '/' + $Branch)
        if ($PSCmdlet.ShouldProcess($target, ('git add, commit, push for ' + $SitePath))) {
            & git add -- site
            if ($LASTEXITCODE -ne 0) { throw ("git add failed with exit code " + $LASTEXITCODE) }

            & git commit -m $CommitMessage
            if ($LASTEXITCODE -ne 0) { throw ("git commit failed with exit code " + $LASTEXITCODE) }

            & git push $Remote $Branch
            if ($LASTEXITCODE -ne 0) { throw ("git push failed with exit code " + $LASTEXITCODE) }

            Write-Step "Pushed. Check the Actions tab in GitHub for the deploy-pages workflow run."
        }
        else {
            Write-Step "WhatIf: nothing was committed or pushed."
        }
    }
    finally {
        Pop-Location
    }

    return
}

# ---------------------------------------------------------------------------
# Mode: GhPages  (fallback: publish site/ to a gh-pages branch directly)
# ---------------------------------------------------------------------------

if ($Mode -eq 'GhPages') {

    Push-Location -LiteralPath $repoRoot
    try {
        $relSite = 'site'
        $tempBranch = 'gh-pages-split-temp'
        $worktreePath = Join-Path ([System.IO.Path]::GetTempPath()) ('product-pulse-ghpages-' + [System.Guid]::NewGuid().ToString('N'))

        Write-Step ("This will publish the '" + $relSite + "' subtree to the 'gh-pages' branch,")
        Write-Step "using git subtree split into a temporary worktree, not subtree push."

        $target = ($Remote + '/gh-pages')
        if ($PSCmdlet.ShouldProcess($target, ('Publish ' + $SitePath + ' to gh-pages'))) {

            Write-Step "Splitting site/ history into a temporary branch..."
            & git subtree split --prefix=$relSite -b $tempBranch
            if ($LASTEXITCODE -ne 0) { throw ("git subtree split failed with exit code " + $LASTEXITCODE) }

            Write-Step ("Checking out that history into a temporary worktree: " + $worktreePath)
            & git worktree add $worktreePath $tempBranch
            if ($LASTEXITCODE -ne 0) { throw ("git worktree add failed with exit code " + $LASTEXITCODE) }

            try {
                Push-Location -LiteralPath $worktreePath
                try {
                    Write-Step ("Force-pushing " + $tempBranch + " to " + $Remote + "/gh-pages ...")
                    & git push $Remote ($tempBranch + ':gh-pages') --force
                    if ($LASTEXITCODE -ne 0) { throw ("git push to gh-pages failed with exit code " + $LASTEXITCODE) }
                }
                finally {
                    Pop-Location
                }
            }
            finally {
                Write-Step "Cleaning up the temporary worktree and branch..."
                & git worktree remove $worktreePath --force
                & git branch -D $tempBranch
            }

            Write-Step "Published. If Pages Source is 'Deploy from a branch', point it at gh-pages / (root)."
        }
        else {
            Write-Step "WhatIf: nothing was split, pushed, or cleaned up."
        }
    }
    finally {
        Pop-Location
    }

    return
}
