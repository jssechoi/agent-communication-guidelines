<#
.SYNOPSIS
    Installs the agent-communication-guidelines tone standard for Claude Code,
    Gemini CLI and Codex.

.DESCRIPTION
    The standard is Korean. This script is ASCII-only because Windows PowerShell 5.1
    reads a BOM-less .ps1 as CP949; all Korean text lives in the UTF-8 snippet files
    under install\snippets\ and is read at run time.

    Every edit is wrapped in HTML comment markers and is replaced in place on a
    re-run, so the script is safe to run repeatedly. Existing files are backed up
    before the first change.

.PARAMETER Tools
    Which agents to wire up. Default is all three.

.PARAMETER DryRun
    Print the planned actions without touching anything.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install\install.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install\install.ps1 -Tools gemini,codex -DryRun
#>
[CmdletBinding()]
param(
    [string]$Tools = 'all',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot   = Split-Path -Parent $ScriptDir
$SnippetDir = Join-Path $ScriptDir 'snippets'
$RulesPath  = Join-Path $RepoRoot 'skills\agent-tone\SKILL.md'
$BeginTag   = '<!-- agent-communication-guidelines:begin -->'
$EndTag     = '<!-- agent-communication-guidelines:end -->'

if (-not (Test-Path -LiteralPath $RulesPath)) {
    throw "Run this from inside the cloned repository. Not found: $RulesPath"
}

# powershell -File collapses an array argument into a single string, so -Tools
# arrives as text and is split here rather than by a ValidateSet attribute.
$valid    = @('claude', 'gemini', 'codex')
$toolList = @($Tools -split '[,;\s]+' | Where-Object { $_ })
if ($toolList -contains 'all') { $toolList = $valid }
$bad = @($toolList | Where-Object { $valid -notcontains $_ })
if ($bad.Count -gt 0) {
    throw ("Unknown tool: {0}. Use 'all', or a comma-separated list of: {1}" -f ($bad -join ', '), ($valid -join ', '))
}

$script:Changed = 0
$script:Skipped = 0

function Read-Utf8File {
    param([string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8File {
    param([string]$Path, [string]$Text)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Get-MandateBlock {
    param([string]$HeadFile)
    $head = Read-Utf8File (Join-Path $SnippetDir $HeadFile)
    $core = Read-Utf8File (Join-Path $SnippetDir 'mandate-core.md')
    $head = $head.Replace('{{GUIDELINES_PATH}}', $RulesPath)
    $body = $head.TrimEnd() + "`n`n" + $core.TrimEnd()
    return $BeginTag + "`n" + $body + "`n" + $EndTag
}

function Convert-Eol {
    param([string]$Text, [string]$Eol)
    $lf = $Text -replace "`r`n", "`n"
    if ($Eol -eq "`r`n") { return $lf -replace "`n", "`r`n" }
    return $lf
}

# Appends the block, or replaces an existing marked block, preserving the
# target file's dominant line ending.
function Set-Mandate {
    param([string]$Path, [string]$HeadFile, [string]$Label)

    $block    = Get-MandateBlock $HeadFile
    $exists   = Test-Path -LiteralPath $Path
    $existing = ''
    if ($exists) { $existing = Read-Utf8File $Path }

    $eol = "`n"
    if ($existing -match "`r`n") { $eol = "`r`n" }
    $block = Convert-Eol $block $eol

    if ($existing -match [regex]::Escape($BeginTag)) {
        $pattern = [regex]::Escape($BeginTag) + '.*?' + [regex]::Escape($EndTag)
        $script:BlockText = $block
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $script:BlockText }
        $updated = [regex]::Replace($existing, $pattern, $evaluator, 'Singleline')
        $action = 'update'
    }
    elseif ($exists) {
        $updated = $existing.TrimEnd() + $eol + $eol + $block + $eol
        $action = 'append'
    }
    else {
        $updated = $block + $eol
        $action = 'create'
    }

    if ($updated -eq $existing) {
        Write-Host ("  [same]   {0}" -f $Label)
        $script:Skipped++
        return
    }
    if ($DryRun) {
        Write-Host ("  [{0}] {1} -> {2}" -f $action, $Label, $Path)
        return
    }
    if ($exists) { Backup-File $Path }
    Write-Utf8File $Path $updated
    Write-Host ("  [{0}] {1}" -f $action, $Label)
    $script:Changed++
}

function Backup-File {
    param([string]$Path)
    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Path.bak-$stamp"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    Write-Host ("  [backup] {0}" -f $backup)
}

function Copy-Tree {
    param([string]$Source, [string]$Destination, [string[]]$Exclude = @())
    if ($DryRun) {
        Write-Host ("  [copy]   {0} -> {1}" -f $Source, $Destination)
        return
    }
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    }
    Get-ChildItem -LiteralPath $Source -Force |
        Where-Object { $Exclude -notcontains $_.Name } |
        ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force }
    Write-Host ("  [copy]   {0}" -f $Destination)
    $script:Changed++
}

Write-Host ''
Write-Host 'agent-communication-guidelines installer'
Write-Host ("  repository : {0}" -f $RepoRoot)
Write-Host ("  tools      : {0}" -f ($toolList -join ', '))
if ($DryRun) { Write-Host '  mode       : dry run, nothing is written' }
Write-Host ''

if ($toolList -contains 'claude') {
    Write-Host 'Claude Code'
    $skillDir = Join-Path $HOME '.claude\skills\agent-communication-guidelines'
    if ($RepoRoot -eq $skillDir.TrimEnd('\')) {
        Write-Host '  [same]   repository is already the skills-dir plugin'
    }
    else {
        Copy-Tree -Source $RepoRoot -Destination $skillDir -Exclude @('.git')
    }
    Set-Mandate -Path (Join-Path $HOME '.claude\CLAUDE.md') -HeadFile 'head-claude.md' -Label 'CLAUDE.md mandate'
    Write-Host ''
}

if ($toolList -contains 'gemini') {
    Write-Host 'Gemini CLI'
    $gSkill = Join-Path $HOME '.gemini\skills\agent-communication-guidelines'
    $mandate = Read-Utf8File (Join-Path $SnippetDir 'mandate-core.md')
    $mandate = $mandate.TrimEnd()
    $template = Read-Utf8File (Join-Path $ScriptDir 'gemini-skill\SKILL.md')
    if ($DryRun) {
        Write-Host ("  [write]  {0}" -f (Join-Path $gSkill 'SKILL.md'))
        Write-Host ("  [write]  {0}" -f (Join-Path $gSkill 'references\guidelines.md'))
    }
    else {
        Write-Utf8File (Join-Path $gSkill 'SKILL.md') ($template.Replace('{{MANDATE}}', $mandate))
        Write-Utf8File (Join-Path $gSkill 'references\guidelines.md') (Read-Utf8File $RulesPath)
        Write-Host ("  [write]  {0}" -f $gSkill)
        $script:Changed++
    }
    Set-Mandate -Path (Join-Path $HOME '.gemini\GEMINI.md') -HeadFile 'head-gemini.md' -Label 'GEMINI.md mandate'
    Write-Host ''
}

if ($toolList -contains 'codex') {
    Write-Host 'Codex'
    Set-Mandate -Path (Join-Path $HOME '.codex\AGENTS.md') -HeadFile 'head-codex.md' -Label 'AGENTS.md mandate'
    Write-Host ''
}

Write-Host ("Done. {0} written, {1} already current." -f $script:Changed, $script:Skipped)
if (-not $DryRun) {
    Write-Host 'Rules load on each tool''s next session.'
}
