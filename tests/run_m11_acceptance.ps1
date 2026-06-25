$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3"
$ReportDir = "$Project\reports\m11_acceptance"
$ScreenshotDir = "$ReportDir\screenshots"
$ReportFile = "$ReportDir\m11_acceptance_report.html"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$GitHead = (git -C $Project rev-parse HEAD 2>$null) -replace '\s+', ''

# Ensure directories
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
New-Item -ItemType Directory -Force -Path $ScreenshotDir | Out-Null

$Scripts = @(
    @{Name="smoke"; File="tests/smoke_test.gd"},
    @{Name="player_feedback"; File="tests/m11_player_feedback_verify.gd"},
    @{Name="economy_consistency"; File="tests/m11_economy_consistency_verify.gd"},
    @{Name="runtime_ui_state"; File="tests/m11_runtime_ui_state_verify.gd"},
    @{Name="reset_flow"; File="tests/m11_reset_flow_verify.gd"},
    @{Name="ui_layout"; File="tests/m11_ui_layout_verify.gd"}
)

$Results = @()
$OverallPass = $true

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M11 AUTOMATED ACCEPTANCE HARNESS" -ForegroundColor Cyan
Write-Host " Project: $Project" -ForegroundColor Gray
Write-Host " Git HEAD: $GitHead" -ForegroundColor Gray
Write-Host " Time: $Timestamp" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($Script in $Scripts) {
    $Name = $Script.Name
    $File = $Script.File
    Write-Host "[RUN] $Name ($File)..." -ForegroundColor Yellow

    $ExitCode = 0
    $Output = & $Godot --headless --path $Project --script $File 2>&1
    $ExitCode = $LASTEXITCODE

    $Passed = ($ExitCode -eq 0) -and ($Output -match "PASS")
    if (-not $Passed) { $OverallPass = $false }

    $AssertCount = ""
    $OutputStr = if ($Output -is [array]) { $Output -join "`n" } else { "$Output" }
    if ($OutputStr -match "\((\d+)/(\d+)\)") {
        $AssertCount = $Matches[0]
    }

    $StatusText = if ($Passed) { "PASS" } else { "FAIL" }
    $StatusColor = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  [$StatusText] $Name $AssertCount (exit=$ExitCode)" -ForegroundColor $StatusColor

    $Results += @{
        name = $Name
        file = $File
        passed = $Passed
        exit_code = $ExitCode
        assertions = $AssertCount
        output = ($Output -join "`n")
    }

    if (-not $Passed) {
        # Print last few lines of output for debugging
        $Lines = $Output -split "`n"
        $Tail = $Lines[-5..-1] -join "`n"
        Write-Host "  Last output:" -ForegroundColor Red
        Write-Host $Tail -ForegroundColor Red
    }
    Write-Host ""
}

$FinalResult = if ($OverallPass) { "PASS" } else { "FAIL" }
$ResultColor = if ($OverallPass) { "Green" } else { "Red" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " M11_ACCEPTANCE_RESULT=$FinalResult" -ForegroundColor $ResultColor
Write-Host "========================================" -ForegroundColor Cyan

# Save screenshot attempts (headless: document what we checked)
$ScreenshotNote = @"
M11 Acceptance Screenshots (headless)
=====================================
Generated: $Timestamp
Git HEAD: $GitHead
Result: $FinalResult

Note: In headless mode, actual screenshots require a GPU/renderer.
The UI layout verification script (m11_ui_layout_verify.gd) validates:
- All key Control nodes are within viewport bounds
- No unicode escape residue in labels
- No empty button texts
- ShopPanel/LivestockPanel hidden by default
- Timeline entries have correct format

For visual screenshots, run the project in the Godot editor
and capture the following views manually:
1. main_default.png  - Default view with bottom dock visible
2. shop_open.png     - Shop panel open
3. after_purchase.png - After a purchase, showing timeline entry
4. after_release.png  - After a release, showing timeline entry
5. after_reset.png    - After reset, showing default state
"@
Set-Content -Path "$ScreenshotDir\README.md" -Value $ScreenshotNote

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
  <td>$($r.assertions)</td>
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
<title>M11 Acceptance Report</title>
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
.note { color: #ffab40; }
</style>
</head>
<body>
<h1>M11 Automated Acceptance Report</h1>
<p><strong>Git HEAD:</strong> <code>$GitHead</code></p>
<p><strong>Timestamp:</strong> $Timestamp</p>
<p><strong>Project:</strong> CoralReefIdleV3</p>
<p><strong>Branch:</strong> prototype/m11-biomanage-vertical-slice</p>

<h2>Test Results</h2>
<table>
<tr><th>Script</th><th>File</th><th>Result</th><th>Assertions</th><th>Exit</th></tr>
$HtmlRows
</table>

<h2>M11_ACCEPTANCE_RESULT</h2>
<p class="result-$($FinalResult.ToLower())">$FinalResult</p>

<h2>Modified Files</h2>
<div class="code">$ModFiles</div>

<h2>Diff Stat</h2>
<div class="code">$DiffStat</div>

<h2>M11 Default State (口径)</h2>
<table>
<tr><th>Metric</th><th>Value</th><th>Note</th></tr>
<tr><td>Coral Count</td><td>4</td><td>海葵临时归入珊瑚</td></tr>
<tr><td>Fish Count</td><td>3</td><td>小丑鱼一对按2条聚合</td></tr>
<tr><td>Total Livestock</td><td>6</td><td>Starter seed</td></tr>
<tr><td>Invertebrate</td><td>0</td><td>无独立无脊椎类显示</td></tr>
</table>

<h2>Screenshots</h2>
<p class="note">Headless mode: see reports/m11_acceptance/screenshots/README.md</p>

<h2>Verification Scripts</h2>
<ol>
<li>smoke_test.gd — Basic project integrity</li>
<li>m11_player_feedback_verify.gd — Purchase/release timeline + status</li>
<li>m11_economy_consistency_verify.gd — RP source of truth + release rewards</li>
<li>m11_runtime_ui_state_verify.gd — UI label refresh + reset defaults</li>
<li>m11_reset_flow_verify.gd — Real reset path through Main.gd</li>
<li>m11_ui_layout_verify.gd — Label quality, bounds, no debug leak</li>
</ol>
</body>
</html>
"@
Set-Content -Path $ReportFile -Value $HTML -Encoding UTF8

Write-Host "Report saved: $ReportFile" -ForegroundColor Gray
Write-Host "Screenshots dir: $ScreenshotDir" -ForegroundColor Gray

exit $(if ($OverallPass) { 0 } else { 1 })
