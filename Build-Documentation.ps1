<#
.SYNOPSIS
    Builds the module documentation using platyPS.

.DESCRIPTION
    This script generates markdown documentation from comment-based help and creates
    external MAML help files for the PSFFmpeg module. This enables features like
    Update-Help and provides better help documentation for users.

.PARAMETER SkipInstall
    Skip installing platyPS if it's already installed.

.PARAMETER GenerateMarkdown
    Generate markdown documentation files in docs/en-US/cmdlets.

.PARAMETER GenerateMAML
    Generate MAML (XML) help files in PSFFmpeg/en-US.

.PARAMETER UpdateAboutTopics
    Update or regenerate about help topics.

.PARAMETER All
    Perform all documentation generation steps.

.EXAMPLE
    .\Build-Documentation.ps1 -All
    Builds all documentation files (markdown and MAML).

.EXAMPLE
    .\Build-Documentation.ps1 -GenerateMarkdown
    Only generates markdown documentation files.

.NOTES
    Requires: platyPS module (will be installed if missing)
    Author: PSFFmpeg Contributors
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$SkipInstall,

    [Parameter()]
    [switch]$GenerateMarkdown,

    [Parameter()]
    [switch]$GenerateMAML,

    [Parameter()]
    [switch]$UpdateAboutTopics,

    [Parameter()]
    [switch]$All
)

$ErrorActionPreference = 'Stop'

# Set default behavior
if (-not $GenerateMarkdown -and -not $GenerateMAML -and -not $UpdateAboutTopics) {
    $All = $true
}

if ($All) {
    $GenerateMarkdown = $true
    $GenerateMAML = $true
    $UpdateAboutTopics = $true
}

# Get script directory
$ScriptRoot = $PSScriptRoot
$ModulePath = Join-Path $ScriptRoot 'PSFFmpeg'
$DocsPath = Join-Path $ScriptRoot 'docs' 'en-US'
$CmdletsDocsPath = Join-Path $DocsPath 'cmdlets'
$AboutDocsPath = Join-Path $DocsPath 'about'
$MamlPath = Join-Path $ModulePath 'en-US'

Write-Host "=== PSFFmpeg Documentation Build ===" -ForegroundColor Cyan
Write-Host "Module Path: $ModulePath" -ForegroundColor Gray
Write-Host "Docs Path: $DocsPath" -ForegroundColor Gray
Write-Host "MAML Path: $MamlPath" -ForegroundColor Gray
Write-Host ""

# Install platyPS if needed
if (-not $SkipInstall) {
    Write-Host "Checking for platyPS module..." -ForegroundColor Yellow
    $platyPS = Get-Module -ListAvailable -Name platyPS | Select-Object -First 1

    if (-not $platyPS) {
        Write-Host "Installing platyPS module..." -ForegroundColor Yellow
        Install-Module -Name platyPS -Force -Scope CurrentUser -AllowClobber
        Write-Host "platyPS installed successfully" -ForegroundColor Green
    } else {
        Write-Host "platyPS version $($platyPS.Version) is already installed" -ForegroundColor Green
    }
}

# Import platyPS
Write-Host "Importing platyPS module..." -ForegroundColor Yellow
Import-Module platyPS -Force

# Import the PSFFmpeg module
Write-Host "Importing PSFFmpeg module..." -ForegroundColor Yellow
Import-Module $ModulePath -Force

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Yellow
@($DocsPath, $CmdletsDocsPath, $AboutDocsPath, $MamlPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
        Write-Host "  Created: $_" -ForegroundColor Gray
    }
}

# Generate markdown documentation
if ($GenerateMarkdown) {
    Write-Host ""
    Write-Host "=== Generating Markdown Documentation ===" -ForegroundColor Cyan

    # Get all exported commands
    $commands = Get-Command -Module PSFFmpeg

    Write-Host "Found $($commands.Count) commands to document" -ForegroundColor Yellow

    foreach ($command in $commands) {
        $markdownPath = Join-Path $CmdletsDocsPath "$($command.Name).md"

        Write-Host "  Generating: $($command.Name).md" -ForegroundColor Gray

        # Generate markdown from command help
        New-MarkdownHelp -Command $command.Name -OutputFolder $CmdletsDocsPath -Force | Out-Null
    }

    Write-Host "Markdown documentation generated successfully" -ForegroundColor Green
}

# Update about topics
if ($UpdateAboutTopics) {
    Write-Host ""
    Write-Host "=== Updating About Topics ===" -ForegroundColor Cyan

    # About topics are text files that should be manually maintained
    # We'll just verify they exist and report
    $aboutTopics = Get-ChildItem -Path $AboutDocsPath -Filter "*.md" -ErrorAction SilentlyContinue

    if ($aboutTopics) {
        Write-Host "Found $($aboutTopics.Count) about topic(s):" -ForegroundColor Yellow
        $aboutTopics | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No about topics found in $AboutDocsPath" -ForegroundColor Yellow
        Write-Host "About topics should be created manually as markdown files." -ForegroundColor Gray
    }
}

# Generate MAML help files
if ($GenerateMAML) {
    Write-Host ""
    Write-Host "=== Generating MAML Help Files ===" -ForegroundColor Cyan

    $mamlFile = Join-Path $MamlPath "PSFFmpeg-help.xml"

    Write-Host "Generating MAML from markdown documentation..." -ForegroundColor Yellow
    Write-Host "  Input: $CmdletsDocsPath" -ForegroundColor Gray
    Write-Host "  Output: $mamlFile" -ForegroundColor Gray

    # Generate MAML from markdown
    New-ExternalHelp -Path $CmdletsDocsPath -OutputPath $MamlPath -Force | Out-Null

    Write-Host "MAML help file generated successfully" -ForegroundColor Green

    # Generate about topics MAML if they exist
    $aboutTopics = Get-ChildItem -Path $AboutDocsPath -Filter "*.md" -ErrorAction SilentlyContinue
    if ($aboutTopics) {
        Write-Host ""
        Write-Host "Generating MAML for about topics..." -ForegroundColor Yellow
        New-ExternalHelp -Path $AboutDocsPath -OutputPath $MamlPath -Force | Out-Null
        Write-Host "About topics MAML generated successfully" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Documentation Build Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review generated markdown files in: $CmdletsDocsPath" -ForegroundColor Gray
Write-Host "  2. Edit markdown files to add examples or improve descriptions" -ForegroundColor Gray
Write-Host "  3. Run this script again to regenerate MAML from updated markdown" -ForegroundColor Gray
Write-Host "  4. Test help with: Get-Help <CommandName> -Full" -ForegroundColor Gray
Write-Host "  5. Commit markdown files to source control" -ForegroundColor Gray
Write-Host ""
