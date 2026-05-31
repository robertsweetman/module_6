<#
.SYNOPSIS
    Seeds the ADO Monitoring Dashboard with realistic fake pipeline events.

.DESCRIPTION
    Discovers the Function App URL and ingest API key from Azure automatically,
    then POSTs a representative set of pipeline runs across multiple services,
    environments, branches, and statuses to produce a compelling screenshot.

.PARAMETER ResourceGroup
    Resource group containing the Function App. Defaults to the standard dev name.

.PARAMETER SubscriptionId
    Target subscription. Defaults to the dashboard subscription.

.EXAMPLE
    .\seed-demo-data.ps1
    .\seed-demo-data.ps1 -ResourceGroup rg-ado-dashboard-dev
#>

param(
    [string]$ResourceGroup   = "rg-ado-dashboard-dev",
    [string]$SubscriptionId  = "d576283e-72e4-4cfd-8310-4f182b07dd00"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── 1. Discover Function App URL and API key from Azure ───────────────────────

Write-Host "Setting subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId | Out-Null

Write-Host "Discovering Function App in $ResourceGroup..." -ForegroundColor Cyan
$funcAppName = az functionapp list `
    --resource-group $ResourceGroup `
    --query "[0].name" `
    --output tsv

if (-not $funcAppName) {
    Write-Error "No Function App found in resource group '$ResourceGroup'. Has infra been deployed?"
}

$hostname = az webapp show `
    --resource-group $ResourceGroup `
    --name $funcAppName `
    --query "defaultHostName" `
    --output tsv

$BaseUrl = "https://$hostname"
Write-Host "  Function App : $funcAppName" -ForegroundColor Green
Write-Host "  Base URL     : $BaseUrl" -ForegroundColor Green

# Fetch API key from Key Vault
$kvName = az keyvault list `
    --resource-group $ResourceGroup `
    --query "[0].name" `
    --output tsv

$ApiKey = az keyvault secret show `
    --vault-name $kvName `
    --name "dashboard-ingest-api-key" `
    --query "value" `
    --output tsv

Write-Host "  Key Vault    : $kvName (key retrieved)" -ForegroundColor Green

# ── 2. Demo data definition ───────────────────────────────────────────────────

# Realistic org pipelines mapped to services and typical durations (seconds)
$Pipelines = @(
    @{ Name="PowerApps CI/CD";       Service="PowerApps";         Repo="powerapps-platform";      AvgDuration=180  }
    @{ Name="Oracle Upgrade";         Service="Oracle ERP";        Repo="oracle-migration";         AvgDuration=1440 }
    @{ Name="Data Platform Ingest";   Service="Data Platform";     Repo="data-platform";            AvgDuration=420  }
    @{ Name="Data Platform Publish";  Service="Data Platform";     Repo="data-platform";            AvgDuration=300  }
    @{ Name="Device Onboarding API";  Service="Device Onboarding"; Repo="device-onboarding";        AvgDuration=240  }
    @{ Name="Device Onboarding UI";   Service="Device Onboarding"; Repo="device-onboarding";        AvgDuration=190  }
    @{ Name="AI Backend Train";       Service="AI Backend";        Repo="ai-backend";               AvgDuration=2100 }
    @{ Name="AI Backend Serve";       Service="AI Backend";        Repo="ai-backend";               AvgDuration=310  }
    @{ Name="ADO Dashboard Infra";    Service="ADO Dashboard";     Repo="ado-monitoring-dashboard"; AvgDuration=140  }
    @{ Name="ADO Dashboard Deploy";   Service="ADO Dashboard";     Repo="ado-monitoring-dashboard"; AvgDuration=90   }
)

$Environments = @("dev", "dev", "dev", "test", "test", "prod")   # weighted: more dev runs

$Branches = @(
    "refs/heads/main",
    "refs/heads/main",
    "refs/heads/main",
    "refs/heads/develop",
    "refs/heads/feature/DASH-42-improve-filters",
    "refs/heads/feature/PLAT-17-new-ingest",
    "refs/heads/hotfix/ORA-99-prod-fix"
)

$Statuses = @(
    @{ Status="Succeeded"; Weight=72 }
    @{ Status="Failed";    Weight=18 }
    @{ Status="Canceled";  Weight=10 }
)

$Users = @(
    "alex.smith@contoso.com"
    "priya.patel@contoso.com"
    "james.o-brien@contoso.com"
    "dana.lee@contoso.com"
    "sam.wilson@contoso.com"
)

$FailureReasons = @(
    "Unit test assertion failed — expected 200 got 500"
    "Terraform plan rejected: resource quota exceeded"
    "Docker build failed: missing base image"
    "Integration test timeout after 600s"
    "SonarQube quality gate failed: coverage below 80%"
    ""   # most failures don't have a detailed reason populated
    ""
)

$FailedStages = @("test", "build", "deploy", "validate", "")

$WorkItems = @(
    @("DASH-42", "DASH-43")
    @("PLAT-17")
    @("ORA-99")
    @("DEV-201", "DEV-202", "DEV-203")
    @()
    @()   # most runs don't link work items
    @()
)

function Get-WeightedStatus {
    $roll = Get-Random -Minimum 1 -Maximum 101
    $cumulative = 0
    foreach ($s in $Statuses) {
        $cumulative += $s.Weight
        if ($roll -le $cumulative) { return $s.Status }
    }
    return "Succeeded"
}

function New-FakeCommitId {
    -join ((1..40) | ForEach-Object { "0123456789abcdef"[(Get-Random -Maximum 16)] })
}

function New-Event {
    param($Pipeline, $BuildId, $DaysAgo)

    $status      = Get-WeightedStatus
    $env         = $Environments | Get-Random
    $branch      = $Branches | Get-Random
    $triggeredBy = $Users | Get-Random
    $jitter      = Get-Random -Minimum -300 -Maximum 300
    $duration    = [Math]::Max(30, $Pipeline.AvgDuration + $jitter)

    $finishTime  = (Get-Date).ToUniversalTime().AddDays(-$DaysAgo).AddSeconds(-(Get-Random -Maximum 86400))
    $startTime   = $finishTime.AddSeconds(-$duration)
    # Commit happened between 1 minute and 6 hours before the pipeline started
    $commitTime  = $startTime.AddSeconds(-(Get-Random -Minimum 60 -Maximum 21600))

    $isRollback    = ($status -eq "Succeeded") -and ((Get-Random -Maximum 10) -eq 0)   # ~10% of successes
    $failureReason = if ($status -eq "Failed") { $FailureReasons | Get-Random } else { "" }
    $failedStage   = if ($status -eq "Failed" -and $failureReason) { $FailedStages | Get-Random } else { "" }

    # Test results — only pipelines that actually run tests
    $hasTests    = $Pipeline.Name -notmatch "Oracle|Infra"
    $testsPassed = if ($hasTests) { Get-Random -Minimum 42 -Maximum 320 } else { 0 }
    $testsFailed = if ($hasTests -and $status -eq "Failed") { Get-Random -Minimum 1 -Maximum 8 } else { 0 }

    # Version: semver-ish based on build id
    $major = 1 + [Math]::Floor($BuildId / 200)
    $minor = $BuildId % 20
    $patch = Get-Random -Maximum 10
    $releaseVersion = "v$major.$minor.$patch"

    $prId = if ($branch -match "feature|hotfix") { "PR-" + (Get-Random -Minimum 100 -Maximum 999) } else { "" }

    return @{
        pipelineName    = $Pipeline.Name
        buildId         = $BuildId
        buildNumber     = "$((Get-Date).Year).$([Math]::Floor($BuildId / 10)).$(($BuildId % 10) + 1)"
        status          = $status
        branch          = $branch
        triggeredBy     = $triggeredBy
        projectName     = "Platform Engineering"
        repositoryName  = $Pipeline.Repo
        environment     = $env
        startTime       = $startTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        finishTime      = $finishTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        durationSeconds = $duration
        serviceName     = $Pipeline.Service
        releaseVersion  = $releaseVersion
        commitId        = (New-FakeCommitId)
        commitTimestamp = $commitTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
        pullRequestId   = $prId
        isRollback      = $isRollback
        failureReason   = $failureReason
        failedStage     = $failedStage
        workItemIds     = ($WorkItems | Get-Random)
        testsPassed     = $testsPassed
        testsFailed     = $testsFailed
    }
}

# ── 3. Generate and POST events ───────────────────────────────────────────────

# ~60 events spread across 14 days to fill the dashboard attractively
$Events = @()
$buildId = 5000

foreach ($daysAgo in 0..13) {
    # 2-6 runs per day across random pipelines
    $runsToday = Get-Random -Minimum 2 -Maximum 7
    for ($i = 0; $i -lt $runsToday; $i++) {
        $pipeline = $Pipelines | Get-Random
        $Events += New-Event -Pipeline $pipeline -BuildId $buildId -DaysAgo $daysAgo
        $buildId++
    }
}

# Guarantee at least one of each pipeline in the set for screenshot completeness
foreach ($pipeline in $Pipelines) {
    $Events += New-Event -Pipeline $pipeline -BuildId $buildId -DaysAgo (Get-Random -Minimum 0 -Maximum 3)
    $buildId++
}

Write-Host ""
Write-Host "Sending $($Events.Count) demo events to $BaseUrl/events ..." -ForegroundColor Cyan

$ok = 0; $fail = 0

foreach ($evt in $Events) {
    $body = $evt | ConvertTo-Json -Depth 5
    try {
        $response = Invoke-RestMethod `
            -Uri "$BaseUrl/events" `
            -Method POST `
            -Headers @{ "x-api-key" = $ApiKey; "Content-Type" = "application/json" } `
            -Body $body `
            -TimeoutSec 15
        $ok++
        Write-Host "  ✓ $($evt.pipelineName) [$($evt.status)] ($($evt.environment))" -ForegroundColor DarkGreen
    }
    catch {
        $fail++
        Write-Host "  ✗ $($evt.pipelineName) — $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Done.  Sent: $ok   Failed: $fail" -ForegroundColor Cyan
Write-Host "Open $BaseUrl to view the dashboard." -ForegroundColor Yellow
