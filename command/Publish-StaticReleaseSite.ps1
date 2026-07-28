[CmdletBinding()]
param(
    [ValidateSet('Validate', 'Build', 'WhoAmI', 'Deploy', 'BindDomain', 'Publish')]
    [string]$Action = 'Validate',
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$MainProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string]$OutputRoot = '',
    [string]$Branch = 'main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Get-SiteConfig {
    $path = Join-Path $RepoRoot 'site.config.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing site config: $path"
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Assert-SiteConfig {
    param([Parameter(Mandatory)]$Config)

    if ($Config.projectSlug -notmatch '^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$') {
        throw 'projectSlug must be a valid lowercase DNS label.'
    }

    $expectedDomain = "$($Config.projectSlug).nkbr.cc"
    if ($Config.customDomain -cne $expectedDomain) {
        throw "customDomain must be exactly $expectedDomain"
    }

    $expectedProject = "nkbr-$($Config.projectSlug)"
    if ($Config.pagesProject -cne $expectedProject) {
        throw "pagesProject must be exactly $expectedProject"
    }
}

function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$Capture
    )

    if ($Capture) {
        $global:LASTEXITCODE = 0
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Command failed ($exitCode): $FilePath $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
        }
        return $output
    }

    $global:LASTEXITCODE = 0
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $FilePath $($Arguments -join ' ')"
    }
}

function Get-NodeProgram {
    param(
        [ValidateSet('node', 'npx')]
        [string]$Name
    )

    $candidates = if ($Name -eq 'npx') { @('npx.cmd', 'npx') } else { @('node.exe', 'node') }
    foreach ($candidate in $candidates) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $fileName = if ($Name -eq 'npx') { 'npx.cmd' } else { 'node.exe' }
        $fallback = Join-Path $env:ProgramFiles "nodejs\$fileName"
        if (Test-Path -LiteralPath $fallback -PathType Leaf) {
            return $fallback
        }
    }

    throw "$Name was not found. Install Node.js 22 or newer."
}

function Get-NpxCommand {
    return Get-NodeProgram -Name npx
}

function Invoke-Wrangler {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$Capture
    )

    $npx = Get-NpxCommand
    $allArguments = @('--yes', 'wrangler@latest') + $Arguments
    return Invoke-NativeChecked -FilePath $npx -Arguments $allArguments -Capture:$Capture
}

function Invoke-Validation {
    $node = Get-NodeProgram -Name node
    Invoke-NativeChecked -FilePath $node -Arguments @((Join-Path $RepoRoot 'tools\validate-site.mjs'))
}

function Invoke-Build {
    param([Parameter(Mandatory)]$Config)

    Invoke-Validation | Out-Host
    $destination = if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
        Join-Path $MainProjectRoot ($Config.outputDirectory -replace '/', '\')
    } else {
        [IO.Path]::GetFullPath($OutputRoot)
    }

    $node = Get-NodeProgram -Name node
    Invoke-NativeChecked -FilePath $node -Arguments @(
        (Join-Path $RepoRoot 'tools\build-site.mjs'),
        $destination
    ) | Out-Host
    if (-not (Test-Path -LiteralPath (Join-Path $destination 'release.json') -PathType Leaf)) {
        throw 'Generated GameLauncher release manifest is missing.'
    }
    Write-Host "Static site built: $destination"
    return $destination
}

function Confirm-WranglerIdentity {
    Invoke-Wrangler -Arguments @('whoami')
}

function Ensure-PagesProject {
    param([Parameter(Mandatory)]$Config)

    $raw = Invoke-Wrangler -Arguments @('pages', 'project', 'list', '--json') -Capture
    $jsonText = $raw -join [Environment]::NewLine
    $parsed = if ([string]::IsNullOrWhiteSpace($jsonText)) { $null } else { $jsonText | ConvertFrom-Json }
    $projects = if ($null -eq $parsed) {
        @()
    } elseif ($parsed -is [System.Array]) {
        @($parsed)
    } elseif ($parsed.PSObject.Properties.Match('result').Count -gt 0) {
        @($parsed.result)
    } else {
        @($parsed)
    }

    $matchingProject = $projects | Where-Object {
        $projectName = if ($_.PSObject.Properties.Name -contains 'name') {
            [string]$_.name
        } elseif ($_.PSObject.Properties.Name -contains 'Project Name') {
            [string]$_.'Project Name'
        } else {
            ''
        }
        $projectName -eq $Config.pagesProject
    }
    if ($matchingProject) {
        Write-Host "Cloudflare Pages project already exists: $($Config.pagesProject)"
        return
    }

    Invoke-Wrangler -Arguments @(
        'pages', 'project', 'create', $Config.pagesProject,
        '--production-branch', $Config.productionBranch
    )
}

function Invoke-Deploy {
    param([Parameter(Mandatory)]$Config)

    Confirm-WranglerIdentity
    Ensure-PagesProject -Config $Config
    $built = Invoke-Build -Config $Config
    Invoke-Wrangler -Arguments @(
        'pages', 'deploy', $built,
        '--project-name', $Config.pagesProject,
        '--branch', $Branch,
        '--commit-dirty=true',
        '--commit-message', 'GameLauncher static release site'
    )
    Invoke-Wrangler -Arguments @(
        'deploy',
        '--config', (Join-Path $RepoRoot 'wrangler.worker.jsonc'),
        '--assets', $built,
        '--message', 'GameLauncher public release site'
    )
}

function Invoke-BindDomain {
    param([Parameter(Mandatory)]$Config)

    $token = [Environment]::GetEnvironmentVariable('CLOUDFLARE_API_TOKEN')
    $accountId = [Environment]::GetEnvironmentVariable('CLOUDFLARE_ACCOUNT_ID')
    if ([string]::IsNullOrWhiteSpace($token) -or [string]::IsNullOrWhiteSpace($accountId)) {
        throw 'BindDomain requires CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID environment variables.'
    }

    $project = [Uri]::EscapeDataString([string]$Config.pagesProject)
    $baseUri = "https://api.cloudflare.com/client/v4/accounts/$accountId/pages/projects/$project/domains"
    $headers = @{
        Authorization = "Bearer $token"
        'Content-Type' = 'application/json'
    }

    try {
        $existing = Invoke-RestMethod -Method Get -Uri $baseUri -Headers $headers
        if (@($existing.result) | Where-Object { $_.name -eq $Config.customDomain }) {
            Write-Host "Custom domain already bound: $($Config.customDomain)"
            return
        }

        $body = @{ name = [string]$Config.customDomain } | ConvertTo-Json -Compress
        $result = Invoke-RestMethod -Method Post -Uri $baseUri -Headers $headers -Body $body
        if (-not $result.success) {
            throw 'Cloudflare API returned success=false while binding the domain.'
        }
        Write-Host "Custom domain binding requested: $($Config.customDomain)"
    } catch {
        throw "Cloudflare custom-domain operation failed: $($_.Exception.Message)"
    }
}

$config = Get-SiteConfig
Assert-SiteConfig -Config $config

switch ($Action) {
    'Validate' { Invoke-Validation }
    'Build' { Invoke-Build -Config $config | Out-Null }
    'WhoAmI' { Confirm-WranglerIdentity }
    'Deploy' { Invoke-Deploy -Config $config }
    'BindDomain' { Invoke-BindDomain -Config $config }
    'Publish' {
        Invoke-Deploy -Config $config
        Invoke-BindDomain -Config $config
    }
}
