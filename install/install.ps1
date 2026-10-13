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

    Dot-sourcing this file (". .\install\install.ps1") defines the functions without
    installing anything. tests\install.Tests.ps1 relies on that.

.PARAMETER Tools
    Which agents to wire up. Default is all three.

.PARAMETER Layout
    plugin (default): copy the repository to ~/.claude/skills/agent-communication-guidelines.
    skills: copy each folder under skills/ to ~/.claude/skills/<name>. Use this when the
    skills are already kept as standalone folders, so the two layouts do not collide.

.PARAMETER HomeDir
    Home directory to install into. Defaults to $HOME.

.PARAMETER DryRun
    Print the planned actions without touching anything.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install\install.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install\install.ps1 -Layout skills -DryRun
#>
[CmdletBinding()]
param(
    [string]$Tools = 'all',
    [string]$Layout = 'plugin',
    [string]$HomeDir = '',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$RepoRoot = Split-Path -Parent $ScriptDir
$BeginTag = '<!-- agent-communication-guidelines:begin -->'
$EndTag   = '<!-- agent-communication-guidelines:end -->'

$script:Changed = 0
$script:Skipped = 0

# powershell -File collapses an array argument into a single string, so -Tools
# arrives as text and is split here rather than by a ValidateSet attribute.
function Resolve-ToolList {
    param([string]$Tools)
    $valid = @('claude', 'gemini', 'codex')
    $list  = @($Tools -split '[,;\s]+' | Where-Object { $_ })
    if ($list.Count -eq 0) {
        throw ("No tool given. Use 'all', or a comma-separated list of: {0}" -f ($valid -join ', '))
    }
    if ($list -contains 'all') { return $valid }
    $bad = @($list | Where-Object { $valid -notcontains $_ })
    if ($bad.Count -gt 0) {
        throw ("Unknown tool: {0}. Use 'all', or a comma-separated list of: {1}" -f ($bad -join ', '), ($valid -join ', '))
    }
    return $list
}

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
    param([string]$SnippetDir, [string]$HeadFile, [string]$RulesPath)
    $head = Read-Utf8File (Join-Path $SnippetDir $HeadFile)
    $core = Read-Utf8File (Join-Path $SnippetDir 'mandate-core.md')
    $head = $head.Replace('{{GUIDELINES_PATH}}', $RulesPath)
    $body = ($head.TrimEnd() + "`n`n" + $core.TrimEnd()) -replace "`r`n", "`n"
    return $BeginTag + "`n" + $body + "`n" + $EndTag
}

function Convert-Eol {
    param([string]$Text, [string]$Eol)
    $lf = $Text -replace "`r`n", "`n"
    if ($Eol -eq "`r`n") { return $lf -replace "`n", "`r`n" }
    return $lf
}

# Pure part of Set-Mandate: the new file text and the action name. Appends the
# block, or replaces an existing marked block, in the file's dominant line ending.
function Get-UpdatedText {
    param([string]$Existing, [bool]$Exists, [string]$Block)
    $eol = "`n"
    if ($Existing -match "`r`n") { $eol = "`r`n" }
    $block = Convert-Eol $Block $eol
    if ($Exists -and $Existing -match [regex]::Escape($BeginTag)) {
        $pattern = [regex]::Escape($BeginTag) + '.*?' + [regex]::Escape($EndTag)
        $script:BlockText = $block
        $evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($m) $script:BlockText }
        $text = [regex]::Replace($Existing, $pattern, $evaluator, 'Singleline')
        return @{ Text = $text; Action = 'update' }
    }
    if ($Exists -and $Existing.Trim()) {
        return @{ Text = ($Existing.TrimEnd() + $eol + $eol + $block + $eol); Action = 'append' }
    }
    return @{ Text = ($block + $eol); Action = 'create' }
}

function Set-Mandate {
    param([string]$Path, [string]$Block, [string]$Label, [switch]$DryRun)
    $exists   = Test-Path -LiteralPath $Path
    $existing = ''
    if ($exists) { $existing = Read-Utf8File $Path }
    $r = Get-UpdatedText -Existing $existing -Exists $exists -Block $Block
    if ($exists -and $r.Text -ceq $existing) {
        Write-Host ("  [same]   {0}" -f $Label)
        $script:Skipped++
        return
    }
    if ($DryRun) {
        Write-Host ("  [{0}] {1} -> {2}" -f $r.Action, $Label, $Path)
        return
    }
    if ($exists) { Backup-File $Path | Out-Null }
    Write-Utf8File $Path $r.Text
    Write-Host ("  [{0}] {1}" -f $r.Action, $Label)
    $script:Changed++
}

function Backup-File {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Nothing to back up: $Path" }
    $stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backup = "$Path.bak-$stamp"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    Write-Host ("  [backup] {0}" -f $backup)
    return $backup
}

# True when both folders hold the same relative file names with the same bytes.
function Test-TreeEqual {
    param([string]$A, [string]$B)
    if (-not (Test-Path -LiteralPath $A) -or -not (Test-Path -LiteralPath $B)) { return $false }
    $A = [System.IO.Path]::GetFullPath($A).TrimEnd('\', '/')
    $B = [System.IO.Path]::GetFullPath($B).TrimEnd('\', '/')
    $fa = @(Get-ChildItem -LiteralPath $A -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($A.Length).TrimStart('\', '/') } | Sort-Object)
    $fb = @(Get-ChildItem -LiteralPath $B -Recurse -File -Force | ForEach-Object { $_.FullName.Substring($B.Length).TrimStart('\', '/') } | Sort-Object)
    if (($fa -join '|') -cne ($fb -join '|')) { return $false }
    foreach ($rel in $fa) {
        $ba = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $A $rel)))
        $bb = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes((Join-Path $B $rel)))
        if ($ba -cne $bb) { return $false }
    }
    return $true
}

function Copy-Tree {
    param([string]$Source, [string]$Destination, [string[]]$Exclude = @(), [switch]$DryRun)
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source not found: $Source" }
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

# Layout "skills": each skills/<name> becomes ~/.claude/skills/<name>. A differing
# existing folder is moved to BackupRoot first; it must not stay under skills/,
# where its SKILL.md would load as a second copy of the same skill.
function Install-SkillDirs {
    param([string]$SkillsSource, [string]$SkillsTarget, [string]$BackupRoot, [switch]$DryRun)
    if (-not (Test-Path -LiteralPath $SkillsSource)) { throw "Skills folder not found: $SkillsSource" }
    foreach ($dir in @(Get-ChildItem -LiteralPath $SkillsSource -Directory)) {
        $dest = Join-Path $SkillsTarget $dir.Name
        $exists = Test-Path -LiteralPath $dest
        if ($exists -and (Test-TreeEqual $dir.FullName $dest)) {
            Write-Host ("  [same]   skill {0}" -f $dir.Name)
            $script:Skipped++
            continue
        }
        if ($DryRun) {
            Write-Host ("  [copy]   skill {0} -> {1}" -f $dir.Name, $dest)
            continue
        }
        if ($exists) {
            if (-not (Test-Path -LiteralPath $BackupRoot)) { New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null }
            $bk = Join-Path $BackupRoot $dir.Name
            Move-Item -LiteralPath $dest -Destination $bk
            Write-Host ("  [backup] {0}" -f $bk)
        }
        if (-not (Test-Path -LiteralPath $SkillsTarget)) { New-Item -ItemType Directory -Force -Path $SkillsTarget | Out-Null }
        Copy-Item -LiteralPath $dir.FullName -Destination $dest -Recurse -Force
        Write-Host ("  [copy]   skill {0}" -f $dir.Name)
        $script:Changed++
    }
}

# Gemini has no plugin mechanism: one skill folder with the mandate as SKILL.md and
# the full rules, their references and the router under references/.
function Write-GeminiSkill {
    param([string]$RepoRoot, [string]$Target, [switch]$DryRun)
    $toneDir  = Join-Path $RepoRoot 'skills\agent-tone'
    $refDir   = Join-Path $Target 'references'
    $mandate  = (Read-Utf8File (Join-Path $RepoRoot 'install\snippets\mandate-core.md')).TrimEnd()
    $template = Read-Utf8File (Join-Path $RepoRoot 'install\gemini-skill\SKILL.md')
    $files = @{}
    $files[(Join-Path $Target 'SKILL.md')] = $template.Replace('{{MANDATE}}', $mandate)
    $files[(Join-Path $refDir 'guidelines.md')] = Read-Utf8File (Join-Path $toneDir 'SKILL.md')
    $files[(Join-Path $refDir 'style-router.md')] = Read-Utf8File (Join-Path $RepoRoot 'skills\style-router\SKILL.md')
    foreach ($f in @(Get-ChildItem -LiteralPath (Join-Path $toneDir 'references') -Filter '*.md' -File)) {
        $files[(Join-Path $refDir $f.Name)] = Read-Utf8File $f.FullName
    }
    $same = $true
    foreach ($p in $files.Keys) {
        if (-not (Test-Path -LiteralPath $p) -or (Read-Utf8File $p) -cne $files[$p]) { $same = $false }
    }
    if ($same) {
        Write-Host ("  [same]   {0}" -f $Target)
        $script:Skipped++
        return
    }
    if ($DryRun) {
        foreach ($p in ($files.Keys | Sort-Object)) { Write-Host ("  [write]  {0}" -f $p) }
        return
    }
    foreach ($p in $files.Keys) { Write-Utf8File $p $files[$p] }
    Write-Host ("  [write]  {0} ({1} files)" -f $Target, $files.Count)
    $script:Changed++
}

function Invoke-Install {
    param([string]$Tools = 'all', [string]$Layout = 'plugin', [string]$HomeDir = '', [switch]$DryRun)
    $rulesPath = Join-Path $RepoRoot 'skills\agent-tone\SKILL.md'
    if (-not (Test-Path -LiteralPath $rulesPath)) {
        throw "Run this from inside the cloned repository. Not found: $rulesPath"
    }
    if (@('plugin', 'skills') -notcontains $Layout) { throw "Unknown layout: $Layout. Use plugin or skills." }
    if (-not $HomeDir) { $HomeDir = $HOME }
    $toolList   = @(Resolve-ToolList $Tools)
    $snippetDir = Join-Path $RepoRoot 'install\snippets'
    $stamp      = Get-Date -Format 'yyyyMMdd-HHmmss'
    $script:Changed = 0
    $script:Skipped = 0

    Write-Host ''
    Write-Host 'agent-communication-guidelines installer'
    Write-Host ("  repository : {0}" -f $RepoRoot)
    Write-Host ("  home       : {0}" -f $HomeDir)
    Write-Host ("  tools      : {0}" -f ($toolList -join ', '))
    Write-Host ("  layout     : {0}" -f $Layout)
    if ($DryRun) { Write-Host '  mode       : dry run, nothing is written' }
    Write-Host ''

    if ($toolList -contains 'claude') {
        Write-Host 'Claude Code'
        $skillsRoot = Join-Path $HomeDir '.claude\skills'
        $pluginDir  = Join-Path $skillsRoot 'agent-communication-guidelines'
        if ($Layout -eq 'skills') {
            Install-SkillDirs -SkillsSource (Join-Path $RepoRoot 'skills') -SkillsTarget $skillsRoot `
                -BackupRoot (Join-Path $HomeDir ('.claude\backups\agent-communication-guidelines-' + $stamp)) -DryRun:$DryRun
            if (Test-Path -LiteralPath $pluginDir) {
                Write-Host ("  [warn]   plugin copy also present, remove one layout: {0}" -f $pluginDir)
            }
        }
        elseif ($RepoRoot -eq $pluginDir.TrimEnd('\')) {
            Write-Host '  [same]   repository is already the skills-dir plugin'
        }
        else {
            Copy-Tree -Source $RepoRoot -Destination $pluginDir -Exclude @('.git') -DryRun:$DryRun
            foreach ($d in @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'skills') -Directory)) {
                if (Test-Path -LiteralPath (Join-Path $skillsRoot $d.Name)) {
                    Write-Host ("  [warn]   standalone skill {0} shadows the plugin copy; use -Layout skills or remove it" -f $d.Name)
                }
            }
        }
        $block = Get-MandateBlock -SnippetDir $snippetDir -HeadFile 'head-claude.md' -RulesPath $rulesPath
        Set-Mandate -Path (Join-Path $HomeDir '.claude\CLAUDE.md') -Block $block -Label 'CLAUDE.md mandate' -DryRun:$DryRun
        Write-Host ''
    }

    if ($toolList -contains 'gemini') {
        Write-Host 'Gemini CLI'
        Write-GeminiSkill -RepoRoot $RepoRoot -Target (Join-Path $HomeDir '.gemini\skills\agent-communication-guidelines') -DryRun:$DryRun
        $block = Get-MandateBlock -SnippetDir $snippetDir -HeadFile 'head-gemini.md' -RulesPath $rulesPath
        Set-Mandate -Path (Join-Path $HomeDir '.gemini\GEMINI.md') -Block $block -Label 'GEMINI.md mandate' -DryRun:$DryRun
        Write-Host ''
    }

    if ($toolList -contains 'codex') {
        Write-Host 'Codex'
        $block = Get-MandateBlock -SnippetDir $snippetDir -HeadFile 'head-codex.md' -RulesPath $rulesPath
        Set-Mandate -Path (Join-Path $HomeDir '.codex\AGENTS.md') -Block $block -Label 'AGENTS.md mandate' -DryRun:$DryRun
        Write-Host ''
    }

    Write-Host ("Done. {0} written, {1} already current." -f $script:Changed, $script:Skipped)
    if (-not $DryRun) { Write-Host 'Rules load on each tool''s next session.' }
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Install -Tools $Tools -Layout $Layout -HomeDir $HomeDir -DryRun:$DryRun
}
