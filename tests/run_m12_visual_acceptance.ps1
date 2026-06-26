$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
$ReportDir = "$Project\reports\m12_visual_qa"
$ReportFile = "$ReportDir\m12_visual_acceptance_report.html"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$GitHead = (git -C $Project rev-parse HEAD 2>$null) -replace '\s+', ''

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M12 VISUAL ACCEPTANCE HARNESS" -ForegroundColor Cyan
Write-Host " Project: $Project" -ForegroundColor Gray
Write-Host " Git HEAD: $GitHead" -ForegroundColor Gray
Write-Host " Time: $Timestamp" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Phase 1: M11 Baseline
# =============================================================================
Write-Host "--- PHASE 1: M11 Baseline ---" -ForegroundColor Yellow
$M11Pass = $true
$M11Result = & $Godot --headless --path $Project --script tests/smoke_test.gd 2>&1
$M11OutputStr = if ($M11Result -is [array]) { $M11Result -join "`n" } else { "$M11Result" }
if ($LASTEXITCODE -ne 0 -or $M11OutputStr -notmatch "SMOKE_TEST_RESULT=PASS") {
    Write-Host "  [FAIL] M11 smoke" -ForegroundColor Red
    $M11Pass = $false
} else {
    Write-Host "  [PASS] M11 smoke (fast gate)" -ForegroundColor Green
}
Write-Host ""

# =============================================================================
# Phase 2: M12 Logic Acceptance
# =============================================================================
Write-Host "--- PHASE 2: M12 Logic Acceptance ---" -ForegroundColor Yellow
$M12Pass = $true

$M12Tests = @(
    @{Name="M12_stage_objectives"; File="tests/m12_stage_objectives_verify.gd"},
    @{Name="M12_feedback_timeline"; File="tests/m12_feedback_timeline_verify.gd"}
)

$Results = @()

foreach ($Test in $M12Tests) {
    $Name = $Test.Name
    $File = $Test.File
    Write-Host "[RUN] $Name ($File)..." -ForegroundColor Yellow
    $Output = & $Godot --headless --path $Project --script $File 2>&1
    $ExitCode = $LASTEXITCODE
    $Passed = ($ExitCode -eq 0) -and ($Output -match "PASS")
    if (-not $Passed) { $M12Pass = $false }
    $Status = if ($Passed) { "PASS" } else { "FAIL" }
    $Color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  [$Status] $Name" -ForegroundColor $Color
    $Results += @{name=$Name; file=$File; passed=$Passed; exit=$ExitCode}
}
Write-Host ""

# =============================================================================
# Phase 3: Reset Visual Regression
# =============================================================================
Write-Host "--- PHASE 3: Reset Visual Regression ---" -ForegroundColor Yellow
$VisualPass = $true

Write-Host "[RUN] M12_reset_visual_regression (tests/m12_reset_visual_regression_verify.gd)..." -ForegroundColor Yellow
$VisualOutput = & $Godot --headless --path $Project --script tests/m12_reset_visual_regression_verify.gd 2>&1
$VisualExit = $LASTEXITCODE
$VisualPassed = ($VisualExit -eq 0) -and ($VisualOutput -match "M12_RESET_VISUAL_RESULT=PASS")
if (-not $VisualPassed) { $VisualPass = $false }

$VStatus = if ($VisualPassed) { "PASS" } else { "FAIL" }
$VColor = if ($VisualPassed) { "Green" } else { "Red" }
Write-Host "  [$VStatus] M12_reset_visual_regression" -ForegroundColor $VColor

# Show assertion counts if available
$VOutputStr = if ($VisualOutput -is [array]) { $VisualOutput -join "`n" } else { "$VisualOutput" }
if ($VOutputStr -match "(\d+)/(\d+)") {
    Write-Host "  Assertions: $($Matches[0])" -ForegroundColor Gray
}
if (-not $VisualPassed) {
    $Lines = $VisualOutput -split "`n"
    $Tail = $Lines[-8..-1] -join "`n"
    Write-Host "  Last output:" -ForegroundColor Red
    Write-Host $Tail -ForegroundColor Red
}
$Results += @{name="M12_reset_visual"; file="tests/m12_reset_visual_regression_verify.gd"; passed=$VisualPassed; exit=$VisualExit}
Write-Host ""

# =============================================================================
# Phase 4: Integration Smoke
# =============================================================================
Write-Host "--- PHASE 4: Integration Smoke ---" -ForegroundColor Yellow
$IntPass = $true
$IntOutput = & $Godot --headless --path $Project --script tests/smoke_test.gd 2>&1
$IntExit = $LASTEXITCODE
$IntPassed = ($IntExit -eq 0) -and ($IntOutput -match "PASS")
if (-not $IntPassed) { $IntPass = $false }
$IStatus = if ($IntPassed) { "PASS" } else { "FAIL" }
$IColor = if ($IntPassed) { "Green" } else { "Red" }
Write-Host "  [$IStatus] integration_smoke" -ForegroundColor $IColor
Write-Host ""

# =============================================================================
# Final Result
# =============================================================================
$OverallPass = $M11Pass -and $M12Pass -and $VisualPass -and $IntPass

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M12_RESET_VISUAL_RESULT=$($(if ($VisualPass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($VisualPass) { "Green" } else { "Red" })
Write-Host " M12_ACCEPTANCE_RESULT=$($(if ($M12Pass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($M12Pass) { "Green" } else { "Red" })
Write-Host " M11_ACCEPTANCE_RESULT=$($(if ($M11Pass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($M11Pass) { "Green" } else { "Red" })
Write-Host " OVERALL=$($(if ($OverallPass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($OverallPass) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

# Generate HTML report
$HtmlRows = ""
foreach ($r in $Results) {
    $status = if ($r.passed) { "PASS" } else { "FAIL" }
    $color = if ($r.passed) { "#4caf50" } else { "#f44336" }
    $HtmlRows += @"
<tr>
  <td>$($r.name)</td>
  <td>$($r.file)</td>
  <td style="color:$color;font-weight:bold">$status</td>
  <td>$($r.exit)</td>
</tr>
"@
}

$HTML = @"
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<title>M12 Visual Acceptance Report</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #e0e0e0; padding: 20px; }
h1 { color: #64b5f6; }
h2 { color: #81c784; margin-top: 30px; }
table { border-collapse: collapse; width: 100%; }
th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #333; }
th { background: #16213e; color: #90caf9; }
.result-pass { color: #4caf50; font-weight: bold; font-size: 1.5em; }
.result-fail { color: #f44336; font-weight: bold; font-size: 1.5em; }
</style>
</head>
<body>
<h1>M12 Visual Acceptance Report</h1>
<p><strong>Git HEAD:</strong> <code>$GitHead</code></p>
<p><strong>Timestamp:</strong> $Timestamp</p>
<p><strong>Project:</strong> CoralReefIdleV3</p>

<h2>Results</h2>
<table>
<tr><th>Test</th><th>File</th><th>Result</th><th>Exit</th></tr>
$HtmlRows
</table>

<h2>Final</h2>
<p>M11_ACCEPTANCE_RESULT=$($(if ($M11Pass) { "PASS" } else { "FAIL" }))</p>
<p>M12_ACCEPTANCE_RESULT=$($(if ($M12Pass) { "PASS" } else { "FAIL" }))</p>
<p class="result-$($(if ($VisualPass) { "pass" } else { "fail" }))">M12_RESET_VISUAL_RESULT=$($(if ($VisualPass) { "PASS" } else { "FAIL" }))</p>

<h2>Verification Points</h2>
<ol>
<li>M11 baseline smoke passes</li>
<li>Stage objective system (16 assertions)</li>
<li>Feedback & timeline quality (19 assertions)</li>
<li>Reset #1 does not duplicate UI buttons</li>
<li>Reset #1 no duplicate button texts</li>
<li>Entry panel has exactly 商店/生物 buttons</li>
<li>System panel has <= 3 buttons</li>
<li>Reset #2 button count = Reset #1</li>
<li>Reset #3 button count = Reset #1</li>
<li>Stage objective label not clipped</li>
<li>Maintenance button count stable across resets</li>
</ol>
</body>
</html>
"@
Set-Content -Path $ReportFile -Value $HTML -Encoding UTF8
Write-Host "Report saved: $ReportFile" -ForegroundColor Gray

exit $(if ($OverallPass) { 0 } else { 1 })
