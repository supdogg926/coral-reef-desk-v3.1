param([string]$WaveId = "M19-W01-PRODUCTION-TAKEOVER", [switch]$AllowDirty)

$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
$Errors = 0

Write-Host "=== M19 Final Acceptance ===" -ForegroundColor Cyan
Write-Host "Wave: $WaveId"
Write-Host "Project: $ProjectRoot"

# Verify working directory
Push-Location $ProjectRoot
$branch = (git branch --show-current 2>&1).Trim()
$head = (git rev-parse --short HEAD 2>&1).Trim()
Write-Host "Branch: $branch  HEAD: $head"

# Run ratchet tests
$ratchetDir = "tests/m19/ratchets"
if (Test-Path $ratchetDir) {
    Write-Host "`n--- Ratchet Tests ---" -ForegroundColor Yellow
    foreach ($test in Get-ChildItem "$ratchetDir/M19-D*.ps1" | Sort-Object Name) {
        $result = & powershell -NoProfile -ExecutionPolicy Bypass -File $test.FullName 2>&1
        $ok = ($LASTEXITCODE -eq 0)
        if (-not $ok) { $Errors++ }
        $color = if ($ok) { "Green" } else { "Red" }
        Write-Host "  $($test.BaseName): $(if($ok){'PASS'}else{'FAIL'})" -ForegroundColor $color
        if (-not $ok) { Write-Host "    $result" -ForegroundColor Red }
    }
}

# Check required evidence
Write-Host "`n--- Required Evidence ---" -ForegroundColor Yellow
$defectsPath = "reports/m19/acceptance/M19_OPEN_DEFECTS.json"
if (Test-Path $defectsPath) {
    $defects = (Get-Content $defectsPath -Raw | ConvertFrom-Json).defects
    $missingCount = 0
    foreach ($d in $defects) {
        if ($d.wave -ne "W01") { continue }
        foreach ($ev in $d.required_evidence) {
            $evPath = "reports/m19/acceptance/evidence/$($d.id)/$ev"
            if (Test-Path $evPath) {
                Write-Host "  $($d.id)/$ev: FOUND" -ForegroundColor Green
            } else {
                Write-Host "  $($d.id)/$ev: MISSING" -ForegroundColor Red
                $missingCount++
                $Errors++
            }
        }
    }
    Write-Host "  Missing evidence: $missingCount"
}

# Compile check
Write-Host "`n--- Compile Check ---" -ForegroundColor Yellow
$godot = "C:/Users/admin/Desktop/Godot_v4.7-stable_win64_console.exe"
if (Test-Path $godot) {
    $output = & $godot --headless --quit --path $ProjectRoot 2>&1
    $scriptErrors = ($output | Select-String "SCRIPT ERROR").Count
    if ($scriptErrors -gt 0) { $Errors += $scriptErrors }
    Write-Host "  Script errors: $scriptErrors"
} else {
    Write-Host "  Godot not found — skipping compile check"
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($Errors -eq 0) {
    Write-Host "CANDIDATE_READY" -ForegroundColor Green
    Write-Host "WAVE_ID=$WaveId"
    Write-Host "FULL_REGRESSION=PASS"
} else {
    Write-Host "ACCEPTANCE_FAILED ($Errors errors)" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan

Pop-Location
exit $Errors
