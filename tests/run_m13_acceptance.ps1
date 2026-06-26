$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
$ReportDir = "$Project\reports\m13_30day_simulation"
$ReportFile = "$ReportDir\m13_30day_acceptance_report.html"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$GitHead = (git -C $Project rev-parse HEAD 2>$null) -replace '\s+', ''

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M13 30-DAY ACCEPTANCE HARNESS" -ForegroundColor Cyan
Write-Host " Project: $Project" -ForegroundColor Gray
Write-Host " Git HEAD: $GitHead" -ForegroundColor Gray
Write-Host " Time: $Timestamp" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Phase 1: M11/M12 Gates
# =============================================================================
Write-Host "--- PHASE 1: M11/M12 Gates ---" -ForegroundColor Yellow
$GatesPass = $true

# Fast smoke check
$SmokeResult = & $Godot --headless --path $Project --script tests/smoke_test.gd 2>&1
$SmokeStr = if ($SmokeResult -is [array]) { $SmokeResult -join "`n" } else { "$SmokeResult" }
if ($LASTEXITCODE -ne 0 -or $SmokeStr -notmatch "SMOKE_TEST_RESULT=PASS") {
    Write-Host "  [FAIL] M11 smoke gate" -ForegroundColor Red
    $GatesPass = $false
} else {
    Write-Host "  [PASS] M11 smoke gate" -ForegroundColor Green
}
Write-Host ""

# =============================================================================
# Phase 2: M13 30-Day Simulation Tests
# =============================================================================
Write-Host "--- PHASE 2: M13 30-Day Simulation ---" -ForegroundColor Yellow

$M13Scripts = @(
    @{Name="M13_progression_sim"; File="tests/m13_30day_progression_sim_verify.gd"},
    @{Name="M13_economy_balance"; File="tests/m13_economy_balance_30day_verify.gd"},
    @{Name="M13_unlock_capacity"; File="tests/m13_unlock_capacity_30day_verify.gd"},
    @{Name="M13_save_load"; File="tests/m13_save_load_30day_verify.gd"}
)

$Results = @()
$M13Pass = $true

foreach ($Script in $M13Scripts) {
    $Name = $Script.Name
    $File = $Script.File
    Write-Host "[RUN] $Name ($File)..." -ForegroundColor Yellow

    $Output = & $Godot --headless --path $Project --script $File 2>&1
    $ExitCode = $LASTEXITCODE
    $OutputStr = if ($Output -is [array]) { $Output -join "`n" } else { "$Output" }

    $Passed = ($ExitCode -eq 0) -and ($OutputStr -match "PASS")
    if (-not $Passed) { $M13Pass = $false }

    $AssertCount = ""
    if ($OutputStr -match "(\d+)/(\d+)") {
        $AssertCount = $Matches[0]
    }

    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  [$Status] $Name $AssertCount (exit=$ExitCode)" -ForegroundColor $Color

    $Results += @{name=$Name; file=$File; passed=$Passed; exit=$ExitCode; assertions=$AssertCount; output=$OutputStr}

    if (-not $Passed) {
        $Lines = $Output -split "`n"
        $Tail = $Lines[-8..-1] -join "`n"
        Write-Host "  Last output:" -ForegroundColor Red
        Write-Host $Tail -ForegroundColor Red
    }
    Write-Host ""
}

# =============================================================================
# Phase 3: Integration Smoke
# =============================================================================
Write-Host "--- PHASE 3: Integration Smoke ---" -ForegroundColor Yellow
$IntOutput = & $Godot --headless --path $Project --script tests/smoke_test.gd 2>&1
$IntStr = if ($IntOutput -is [array]) { $IntOutput -join "`n" } else { "$IntOutput" }
$IntPass = ($LASTEXITCODE -eq 0) -and ($IntStr -match "PASS")
$IStatus = if ($IntPass) { "PASS" } else { "FAIL" }
$IColor = if ($IntPass) { "Green" } else { "Red" }
Write-Host "  [$IStatus] integration_smoke" -ForegroundColor $IColor
Write-Host ""

# =============================================================================
# Final Result
# =============================================================================
$OverallPass = $GatesPass -and $M13Pass -and $IntPass

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M13_30DAY_SIM_RESULT=$($(if ($M13Pass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($M13Pass) { "Green" } else { "Red" })
Write-Host " M11_GATE=$($(if ($GatesPass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($GatesPass) { "Green" } else { "Red" })
Write-Host " OVERALL=$($(if ($OverallPass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($OverallPass) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

# Generate report
$HtmlRows = ""
foreach ($r in $Results) {
    $s = if ($r.passed) { "PASS" } else { "FAIL" }
    $c = if ($r.passed) { "#4caf50" } else { "#f44336" }
    $HtmlRows += @"
<tr><td>$($r.name)</td><td>$($r.file)</td><td style="color:$c;font-weight:bold">$s</td><td>$($r.assertions)</td><td>$($r.exit)</td></tr>
"@
}

$HTML = @"
<!DOCTYPE html>
<html lang="zh">
<head><meta charset="UTF-8"><title>M13 30-Day Acceptance Report</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #e0e0e0; padding: 20px; }
h1 { color: #64b5f6; } h2 { color: #81c784; margin-top: 30px; }
table { border-collapse: collapse; width: 100%; }
th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #333; }
th { background: #16213e; color: #90caf9; }
.result-pass { color: #4caf50; font-weight: bold; font-size: 1.5em; }
.result-fail { color: #f44336; font-weight: bold; font-size: 1.5em; }
</style></head>
<body>
<h1>M13 30-Day Simulation Acceptance Report</h1>
<p><strong>Git HEAD:</strong> <code>$GitHead</code></p>
<p><strong>Timestamp:</strong> $Timestamp</p>
<h2>Results</h2>
<table><tr><th>Script</th><th>File</th><th>Result</th><th>Assertions</th><th>Exit</th></tr>$HtmlRows</table>
<h2>Final</h2>
<p class="result-$($(if ($M13Pass) { "pass" } else { "fail" }))">M13_30DAY_SIM_RESULT=$($(if ($M13Pass) { "PASS" } else { "FAIL" }))</p>
<p>M11 Gate: $($(if ($GatesPass) { "PASS" } else { "FAIL" }))</p>
</body></html>
"@
Set-Content -Path $ReportFile -Value $HTML -Encoding UTF8
Write-Host "Report saved: $ReportFile" -ForegroundColor Gray

exit $(if ($OverallPass) { 0 } else { 1 })
