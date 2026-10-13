# Runs every test suite: node --test (rules, install.sh) and Pester (install.ps1).
# Exits non-zero when any suite fails. ASCII-only (PowerShell 5.1 reads BOM-less .ps1 as CP949).
#   powershell -ExecutionPolicy Bypass -File tests\run-all.ps1
#   powershell -ExecutionPolicy Bypass -File tests\run-all.ps1 -WithShell   # also run install.sh tests
# install.sh tests are skipped on Windows unless -WithShell: under Git Bash each short command can
# cost seconds, so they can take a long time there. On macOS and Linux they always run.
param([switch]$WithShell)
$ErrorActionPreference = 'Stop'
if ($WithShell) { $env:ACG_TEST_SH = '1' }
$testsDir = $PSScriptRoot
if (-not $testsDir) { $testsDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$root = Split-Path -Parent $testsDir

Push-Location $root
try {
    & node --test 'tests/*.test.mjs'
    $nodeExit = $LASTEXITCODE
    $result = Invoke-Pester -Script (Join-Path $testsDir 'install.Tests.ps1') -PassThru
    $pesterFailed = $result.FailedCount
}
finally {
    Pop-Location
}

if ($nodeExit -ne 0 -or $pesterFailed -gt 0) {
    Write-Host ("FAILED: node exit {0}, Pester failed {1}" -f $nodeExit, $pesterFailed)
    exit 1
}
Write-Host 'All suites passed.'
exit 0
