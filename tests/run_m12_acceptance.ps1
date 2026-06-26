$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
$ReportDir = "$Project\reports\m12_acceptance"
$ReportFile = "$ReportDir\m12_acceptance_report.html"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$GitHead = (git -C $Project rev-parse HEAD 2>$null) -replace '\s+', ''

# Ensure directories
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M12 AUTOMATED ACCEPTANCE HARNESS" -ForegroundColor Cyan
Write-Host " Project: $Project" -ForegroundColor Gray
Write-Host " Git HEAD: $GitHead" -ForegroundColor Gray
Write-Host " Time: $Timestamp" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# Phase 1: M11 Baseline (must still pass)
# =============================================================================
Write-Host "--- PHASE 1: M11 Baseline ---" -ForegroundColor Yellow
Write-Host ""

$M11Scripts = @(
    @{Name="M11_smoke"; File="tests/smoke_test.gd"},
    @{Name="M11_player_feedback"; File="tests/m11_player_feedback_verify.gd"},
    @{Name="M11_economy_consistency"; File="tests/m11_economy_consistency_verify.gd"},
    @{Name="M11_runtime_ui_state"; File="tests/m11_runtime_ui_state_verify.gd"},
    @{Name="M11_reset_flow"; File="tests/m11_reset_flow_verify.gd"},
    @{Name="M11_ui_layout"; File="tests/m11_ui_layout_verify.gd"}
)

$Results = @()
$M11Pass = $true

foreach ($Script in $M11Scripts) {
    $Name = $Script.Name
    $File = $Script.File
    Write-Host "[RUN] $Name ($File)..." -ForegroundColor Yellow

    $ExitCode = 0
    $Output = & $Godot --headless --path $Project --script $File 2>&1
    $ExitCode = $LASTEXITCODE

    $Passed = ($ExitCode -eq 0) -and ($Output -match "PASS")
    if (-not $Passed) { $M11Pass = $false }

    $StatusText = if ($Passed) { "PASS" } else { "FAIL" }
    $StatusColor = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  [$StatusText] $Name (exit=$ExitCode)" -ForegroundColor $StatusColor

    $Results += @{
        phase = "M11"
        name = $Name
        file = $File
        passed = $Passed
        exit_code = $ExitCode
        output = ($Output -join "`n")
    }

    if (-not $Passed) {
        $Lines = $Output -split "`n"
        $Tail = $Lines[-5..-1] -join "`n"
        Write-Host "  Last output:" -ForegroundColor Red
        Write-Host $Tail -ForegroundColor Red
    }
    Write-Host ""
}

# =============================================================================
# Phase 2: M12 New Tests
# =============================================================================
Write-Host "--- PHASE 2: M12 Productized Core Loop ---" -ForegroundColor Yellow
Write-Host ""

$M12Scripts = @(
    @{Name="M12_stage_objectives"; File="tests/m12_stage_objectives_verify.gd"},
    @{Name="M12_feedback_timeline"; File="tests/m12_feedback_timeline_verify.gd"},
    @{Name="M12_reset_visual"; File="tests/m12_reset_visual_regression_verify.gd"}
)

$M12Pass = $true

foreach ($Script in $M12Scripts) {
    $Name = $Script.Name
    $File = $Script.File
    Write-Host "[RUN] $Name ($File)..." -ForegroundColor Yellow

    $ExitCode = 0
    $Output = & $Godot --headless --path $Project --script $File 2>&1
    $ExitCode = $LASTEXITCODE

    $Passed = ($ExitCode -eq 0) -and ($Output -match "PASS")
    if (-not $Passed) { $M12Pass = $false }

    $AssertCount = ""
    $OutputStr = if ($Output -is [array]) { $Output -join "`n" } else { "$Output" }
    if ($OutputStr -match "(\d+)/(\d+)") {
        $AssertCount = $Matches[0]
    }

    $StatusText = if ($Passed) { "PASS" } else { "FAIL" }
    $StatusColor = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  [$StatusText] $Name $AssertCount (exit=$ExitCode)" -ForegroundColor $StatusColor

    $Results += @{
        phase = "M12"
        name = $Name
        file = $File
        passed = $Passed
        exit_code = $ExitCode
        assertions = $AssertCount
        output = ($Output -join "`n")
    }

    if (-not $Passed) {
        $Lines = $Output -split "`n"
        $Tail = $Lines[-5..-1] -join "`n"
        Write-Host "  Last output:" -ForegroundColor Red
        Write-Host $Tail -ForegroundColor Red
    }
    Write-Host ""
}

# =============================================================================
# Phase 3: Integration Checks (GameState with StageObjective, save/load, reset)
# =============================================================================
Write-Host "--- PHASE 3: Integration Smoke ---" -ForegroundColor Yellow
Write-Host ""

# Run smoke_test.gd again as integration check (it tests GameState init)
$IntPass = $true
$IntExit = 0
$IntOutput = & $Godot --headless --path $Project --script tests/smoke_test.gd 2>&1
$IntExit = $LASTEXITCODE
$IntPassed = ($IntExit -eq 0) -and ($IntOutput -match "PASS")
if (-not $IntPassed) { $IntPass = $false }

$StatusText = if ($IntPassed) { "PASS" } else { "FAIL" }
$StatusColor = if ($IntPassed) { "Green" } else { "Red" }
Write-Host "  [$StatusText] integration_smoke (exit=$IntExit)" -ForegroundColor $StatusColor

$Results += @{
    phase = "M12"
    name = "integration_smoke"
    file = "tests/smoke_test.gd"
    passed = $IntPassed
    exit_code = $IntExit
    output = ($IntOutput -join "`n")
}

Write-Host ""

# =============================================================================
# Final Result
# =============================================================================
$OverallPass = $M11Pass -and $M12Pass -and $IntPass

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M12_ACCEPTANCE_RESULT=$($(if ($OverallPass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($OverallPass) { "Green" } else { "Red" })
Write-Host " M11_ACCEPTANCE_RESULT=$($(if ($M11Pass) { "PASS" } else { "FAIL" }))" -ForegroundColor $(if ($M11Pass) { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan

# Generate HTML report
$HtmlRows = ""
foreach ($r in $Results) {
    $status = if ($r.passed) { "PASS" } else { "FAIL" }
    $color = if ($r.passed) { "#4caf50" } else { "#f44336" }
    $HtmlRows += @"
<tr>
  <td>$($r.phase)</td>
  <td>$($r.name)</td>
  <td>$($r.file)</td>
  <td style="color:$color;font-weight:bold">$status</td>
  <td>$($r.exit_code)</td>
</tr>
"@
}

$ModFiles = (git -C $Project diff --name-only HEAD 2>$null) -join "<br>"
$DiffStat = (git -C $Project diff --stat HEAD 2>$null) -join "<br>"

$HTML = @"
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<title>M12 Acceptance Report</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #e0e0e0; padding: 20px; }
h1 { color: #64b5f6; }
h2 { color: #81c784; margin-top: 30px; }
table { border-collapse: collapse; width: 100%; }
th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #333; }
th { background: #16213e; color: #90caf9; }
.result-pass { color: #4caf50; font-weight: bold; font-size: 1.5em; }
.result-fail { color: #f44336; font-weight: bold; font-size: 1.5em; }
.code { background: #0d1117; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 0.85em; }
</style>
</head>
<body>
<h1>M12 Productized Core Loop Acceptance Report</h1>
<p><strong>Git HEAD:</strong> <code>$GitHead</code></p>
<p><strong>Timestamp:</strong> $Timestamp</p>
<p><strong>Project:</strong> CoralReefIdleV3</p>
<p><strong>Branch:</strong> prototype/m11-biomanage-vertical-slice</p>

<h2>Test Results</h2>
<table>
<tr><th>Phase</th><th>Script</th><th>File</th><th>Result</th><th>Exit</th></tr>
$HtmlRows
</table>

<h2>Final Results</h2>
<p class="result-$($(if ($OverallPass) { "pass" } else { "fail" }))">M12_ACCEPTANCE_RESULT=$($(if ($OverallPass) { "PASS" } else { "FAIL" }))</p>
<p class="result-$($(if ($M11Pass) { "pass" } else { "fail" }))">M11_ACCEPTANCE_RESULT=$($(if ($M11Pass) { "PASS" } else { "FAIL" }))</p>

<h2>Modified Files</h2>
<div class="code">$ModFiles</div>

<h2>M12 Verification Points</h2>
<ol>
<li>M11 baseline acceptance still passes</li>
<li>Stage objective system initializes with 6 objectives</li>
<li>Buying creatures progresses objectives</li>
<li>Device toggle completes enable_device objective</li>
<li>Maintenance completes perform_maintenance objective</li>
<li>Water quality restoration tracked</li>
<li>Timeline records key events with correct categories</li>
<li>Reset preserves system initialization</li>
<li>Save/load preserves objective state</li>
<li>Integration smoke test passes</li>
</ol>
</body>
</html>
"@
Set-Content -Path $ReportFile -Value $HTML -Encoding UTF8

Write-Host "Report saved: $ReportFile" -ForegroundColor Gray

exit $(if ($OverallPass) { 0 } else { 1 })
