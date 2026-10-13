# Pester 3.4 (built into Windows PowerShell 5.1), v3 syntax.
# ASCII-only like every .ps1 here: Korean fixtures are built from [char] codes.
# Dot-sourcing install.ps1 defines its functions without installing anything.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $here
. (Join-Path $repo 'install\install.ps1')

$hangul = [string][char]0xAC00 + [string][char]0xB098

function Count-Markers([string]$Text) { ([regex]::Matches($Text, [regex]::Escape($BeginTag))).Count }

Describe 'Resolve-ToolList' {
    It 'expands all to the three tools' {
        (@(Resolve-ToolList 'all')) -join ',' | Should Be 'claude,gemini,codex'
    }
    It 'accepts a list separated by a comma and spaces' {
        (@(Resolve-ToolList 'gemini, codex')) -join ',' | Should Be 'gemini,codex'
    }
    It 'rejects an unknown tool name' {
        { Resolve-ToolList 'cursor' } | Should Throw
    }
    It 'rejects a list with no tool in it' {
        { Resolve-ToolList ' , ' } | Should Throw
    }
}

Describe 'Read-Utf8File and Write-Utf8File' {
    It 'round-trips Korean text and writes no BOM' {
        $p = Join-Path $TestDrive 'a\b\t.md'
        Write-Utf8File $p $hangul
        Read-Utf8File $p | Should BeExactly $hangul
        ([System.IO.File]::ReadAllBytes($p))[0] | Should Not Be 0xEF
    }
    It 'reads an empty file as an empty string' {
        $p = Join-Path $TestDrive 'empty.md'
        Write-Utf8File $p ''
        Read-Utf8File $p | Should BeExactly ''
    }
    It 'throws on a missing file' {
        { Read-Utf8File (Join-Path $TestDrive 'missing.md') } | Should Throw
    }
    It 'throws on a path Windows cannot create' {
        { Write-Utf8File (Join-Path $TestDrive 'bad|name.md') 'x' } | Should Throw
    }
}

Describe 'Convert-Eol' {
    It 'converts LF to CRLF' {
        Convert-Eol "a`nb" "`r`n" | Should BeExactly "a`r`nb"
    }
    It 'does not double an existing CRLF' {
        Convert-Eol "a`r`nb`n" "`r`n" | Should BeExactly "a`r`nb`r`n"
    }
    It 'turns CRLF into LF for an LF file' {
        Convert-Eol "a`r`nb" "`n" | Should BeExactly "a`nb"
    }
}

Describe 'Get-MandateBlock' {
    $snip = Join-Path $repo 'install\snippets'
    It 'wraps head and core in the markers and fills the rules path' {
        $b = Get-MandateBlock -SnippetDir $snip -HeadFile 'head-codex.md' -RulesPath 'X:\rules\SKILL.md'
        $b.StartsWith($BeginTag) | Should Be $true
        $b.EndsWith($EndTag) | Should Be $true
        $b.Contains('X:\rules\SKILL.md') | Should Be $true
        $b.Contains('{{GUIDELINES_PATH}}') | Should Be $false
    }
    It 'emits LF only even when the snippets use CRLF' {
        $d = Join-Path $TestDrive 'snip'
        Write-Utf8File (Join-Path $d 'head.md') "h1`r`nh2`r`n"
        Write-Utf8File (Join-Path $d 'mandate-core.md') "c1`r`nc2`r`n"
        (Get-MandateBlock -SnippetDir $d -HeadFile 'head.md' -RulesPath 'p').Contains("`r") | Should Be $false
    }
    It 'throws when the head snippet is missing' {
        { Get-MandateBlock -SnippetDir $snip -HeadFile 'head-none.md' -RulesPath 'p' } | Should Throw
    }
}

Describe 'Get-UpdatedText' {
    $block = "$BeginTag`nnew`n$EndTag"
    It 'appends after existing text with one blank line between' {
        $r = Get-UpdatedText -Existing "# mine`n" -Exists $true -Block $block
        $r.Action | Should Be 'append'
        $r.Text | Should BeExactly "# mine`n`n$block`n"
    }
    It 'replaces an existing block and keeps the text around it' {
        $old = "top`n$BeginTag`nold`n$EndTag`nbottom`n"
        $r = Get-UpdatedText -Existing $old -Exists $true -Block $block
        $r.Action | Should Be 'update'
        Count-Markers $r.Text | Should Be 1
        $r.Text.Contains('old') | Should Be $false
        $r.Text | Should BeExactly "top`n$block`nbottom`n"
    }
    It 'keeps CRLF when the file uses CRLF' {
        $r = Get-UpdatedText -Existing "a`r`nb`r`n" -Exists $true -Block $block
        ($r.Text -replace "`r`n", '').Contains("`n") | Should Be $false
    }
    It 'creates the block for a missing or blank file' {
        (Get-UpdatedText -Existing '' -Exists $false -Block $block).Action | Should Be 'create'
        (Get-UpdatedText -Existing "  `n" -Exists $true -Block $block).Text | Should BeExactly "$block`n"
    }
}

Describe 'Set-Mandate' {
    $block = "$BeginTag`n$hangul`n$EndTag"
    It 'writes the block and backs up the previous file' {
        $p = Join-Path $TestDrive 'CLAUDE.md'
        Write-Utf8File $p "# mine`n"
        Set-Mandate -Path $p -Block $block -Label 't'
        (Read-Utf8File $p).Contains($hangul) | Should Be $true
        @(Get-ChildItem -LiteralPath $TestDrive -Filter 'CLAUDE.md.bak-*').Count | Should Be 1
    }
    It 'changes nothing and makes no backup on a second run' {
        $p = Join-Path $TestDrive 'CLAUDE.md'
        $before = [System.IO.File]::GetLastWriteTimeUtc($p)
        Start-Sleep -Milliseconds 1100
        Set-Mandate -Path $p -Block $block -Label 't'
        [System.IO.File]::GetLastWriteTimeUtc($p) | Should Be $before
        @(Get-ChildItem -LiteralPath $TestDrive -Filter 'CLAUDE.md.bak-*').Count | Should Be 1
    }
    It 'detects a change that only alters letter case' {
        $p = Join-Path $TestDrive 'case.md'
        Write-Utf8File $p ("$BeginTag`nabc`n$EndTag`n")
        Set-Mandate -Path $p -Block "$BeginTag`nABC`n$EndTag" -Label 't'
        (Read-Utf8File $p).Contains('ABC') | Should Be $true
    }
    It 'writes nothing in a dry run' {
        $p = Join-Path $TestDrive 'dry.md'
        Set-Mandate -Path $p -Block $block -Label 't' -DryRun
        Test-Path -LiteralPath $p | Should Be $false
    }
}

Describe 'Backup-File' {
    It 'copies the file next to itself with a timestamp' {
        $p = Join-Path $TestDrive 'x.md'
        Write-Utf8File $p $hangul
        $b = Backup-File $p
        $b | Should Match 'x\.md\.bak-\d{8}-\d{6}$'
        Read-Utf8File $b | Should BeExactly $hangul
    }
    It 'backs up an empty file' {
        $p = Join-Path $TestDrive 'e.md'
        Write-Utf8File $p ''
        Test-Path -LiteralPath (Backup-File $p) | Should Be $true
    }
    It 'throws when there is nothing to back up' {
        { Backup-File (Join-Path $TestDrive 'none.md') } | Should Throw
    }
}

Describe 'Test-TreeEqual' {
    $a = Join-Path $TestDrive 'A'; $b = Join-Path $TestDrive 'B'
    Write-Utf8File (Join-Path $a 'SKILL.md') $hangul; Write-Utf8File (Join-Path $a 'r\x.md') 'x'
    Write-Utf8File (Join-Path $b 'SKILL.md') $hangul; Write-Utf8File (Join-Path $b 'r\x.md') 'x'
    It 'is true for identical trees' {
        Test-TreeEqual $a $b | Should Be $true
    }
    It 'is false when one file differs by a single character' {
        Write-Utf8File (Join-Path $b 'r\x.md') 'y'
        Test-TreeEqual $a $b | Should Be $false
    }
    It 'is false when one side has an extra file' {
        Write-Utf8File (Join-Path $b 'r\x.md') 'x'
        Write-Utf8File (Join-Path $b 'extra.md') 'z'
        Test-TreeEqual $a $b | Should Be $false
    }
    It 'is false when a folder does not exist' {
        Test-TreeEqual $a (Join-Path $TestDrive 'nope') | Should Be $false
    }
}

Describe 'Copy-Tree' {
    $src = Join-Path $TestDrive 'src'
    Write-Utf8File (Join-Path $src 'a.md') 'a'
    Write-Utf8File (Join-Path $src '.git\HEAD') 'ref'
    It 'copies everything except the excluded names' {
        $dst = Join-Path $TestDrive 'dst'
        Copy-Tree -Source $src -Destination $dst -Exclude @('.git')
        Test-Path -LiteralPath (Join-Path $dst 'a.md') | Should Be $true
        Test-Path -LiteralPath (Join-Path $dst '.git') | Should Be $false
    }
    It 'writes nothing in a dry run' {
        $dst = Join-Path $TestDrive 'dst-dry'
        Copy-Tree -Source $src -Destination $dst -DryRun
        Test-Path -LiteralPath $dst | Should Be $false
    }
    It 'throws when the source is missing' {
        { Copy-Tree -Source (Join-Path $TestDrive 'nosrc') -Destination (Join-Path $TestDrive 'd') } | Should Throw
    }
}

Describe 'Install-SkillDirs' {
    $src = Join-Path $TestDrive 'skills-src'
    $dst = Join-Path $TestDrive 'home\.claude\skills'
    $bak = Join-Path $TestDrive 'home\.claude\backups\b1'
    Write-Utf8File (Join-Path $src 's1\SKILL.md') 'new-1'
    Write-Utf8File (Join-Path $src 's2\SKILL.md') 'new-2'
    It 'copies each skill folder into the target' {
        Install-SkillDirs -SkillsSource $src -SkillsTarget $dst -BackupRoot $bak
        Read-Utf8File (Join-Path $dst 's1\SKILL.md') | Should BeExactly 'new-1'
        Read-Utf8File (Join-Path $dst 's2\SKILL.md') | Should BeExactly 'new-2'
    }
    It 'moves a differing folder to the backup root, never next to the skills' {
        Write-Utf8File (Join-Path $dst 's1\SKILL.md') 'old-1'
        Install-SkillDirs -SkillsSource $src -SkillsTarget $dst -BackupRoot $bak
        Read-Utf8File (Join-Path $bak 's1\SKILL.md') | Should BeExactly 'old-1'
        Read-Utf8File (Join-Path $dst 's1\SKILL.md') | Should BeExactly 'new-1'
        @(Get-ChildItem -LiteralPath $dst -Directory | Where-Object { $_.Name -notmatch '^s[12]$' }).Count | Should Be 0
    }
    It 'skips an identical folder without a backup' {
        $bak2 = Join-Path $TestDrive 'home\.claude\backups\b2'
        Install-SkillDirs -SkillsSource $src -SkillsTarget $dst -BackupRoot $bak2
        Test-Path -LiteralPath $bak2 | Should Be $false
    }
    It 'throws when the source folder is missing' {
        { Install-SkillDirs -SkillsSource (Join-Path $TestDrive 'none') -SkillsTarget $dst -BackupRoot $bak } | Should Throw
    }
}

Describe 'Write-GeminiSkill' {
    $t = Join-Path $TestDrive 'gem'
    It 'writes SKILL.md with the mandate and every reference file' {
        Write-GeminiSkill -RepoRoot $repo -Target $t
        $skill = Read-Utf8File (Join-Path $t 'SKILL.md')
        $skill.Contains('{{MANDATE}}') | Should Be $false
        $skill.Contains($BeginTag) | Should Be $false
        foreach ($f in @('guidelines.md', 'style-router.md', 'mail-format.md', 'document-rules.md', 'report-format.md', 'korean-expression-alternatives.md')) {
            Test-Path -LiteralPath (Join-Path $t "references\$f") | Should Be $true
        }
    }
    It 'leaves the files untouched on a second run' {
        $p = Join-Path $t 'references\guidelines.md'
        $before = [System.IO.File]::GetLastWriteTimeUtc($p)
        Start-Sleep -Milliseconds 1100
        Write-GeminiSkill -RepoRoot $repo -Target $t
        [System.IO.File]::GetLastWriteTimeUtc($p) | Should Be $before
    }
    It 'writes nothing in a dry run' {
        $d = Join-Path $TestDrive 'gem-dry'
        Write-GeminiSkill -RepoRoot $repo -Target $d -DryRun
        Test-Path -LiteralPath $d | Should Be $false
    }
    It 'throws when the repository root is wrong' {
        { Write-GeminiSkill -RepoRoot (Join-Path $TestDrive 'norepo') -Target $t } | Should Throw
    }
}

Describe 'Invoke-Install' {
    $h = Join-Path $TestDrive 'home'
    It 'installs all three tools into a temp home with the skills layout' {
        Invoke-Install -Tools 'all' -Layout 'skills' -HomeDir $h
        Test-Path -LiteralPath (Join-Path $h '.claude\skills\agent-tone\references\report-format.md') | Should Be $true
        Test-Path -LiteralPath (Join-Path $h '.claude\skills\style-router\SKILL.md') | Should Be $true
        Test-Path -LiteralPath (Join-Path $h '.claude\skills\agent-communication-guidelines') | Should Be $false
        foreach ($f in @('.claude\CLAUDE.md', '.gemini\GEMINI.md', '.codex\AGENTS.md')) {
            Count-Markers (Read-Utf8File (Join-Path $h $f)) | Should Be 1
        }
    }
    It 'adds no second block and rewrites nothing on a re-run' {
        $p = Join-Path $h '.codex\AGENTS.md'
        $before = [System.IO.File]::GetLastWriteTimeUtc($p)
        Start-Sleep -Milliseconds 1100
        Invoke-Install -Tools 'all' -Layout 'skills' -HomeDir $h
        [System.IO.File]::GetLastWriteTimeUtc($p) | Should Be $before
        Count-Markers (Read-Utf8File (Join-Path $h '.claude\CLAUDE.md')) | Should Be 1
        Test-Path -LiteralPath (Join-Path $h '.claude\backups') | Should Be $false
    }
    It 'rejects an unknown layout' {
        { Invoke-Install -Tools 'all' -Layout 'flat' -HomeDir $h } | Should Throw
    }
}
