$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Project "reports\m14"
$LogDir = Join-Path $ReportDir "logs"
$ScreenshotDir = Join-Path $ReportDir "screenshots"
$ReportPath = Join-Path $ReportDir "M14_T02_RESCUE_FIRST_PLAYABLE_UI_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M14_T02_RESCUE_FIRST_PLAYABLE_UI_RECEIPT.json"
New-Item -ItemType Directory -Force -Path $ReportDir,$LogDir,$ScreenshotDir | Out-Null

function Invoke-GodotCheck($Name, $ScriptPath, $PassPattern) {
	$logPath = Join-Path $LogDir "$Name.log"
	$output = & $Godot --headless --path $Project --script $ScriptPath 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	$passed = ($exit -eq 0) -and ($text -match $PassPattern)
	return [ordered]@{
		name = $Name
		command = "$Godot --headless --path $Project --script $ScriptPath"
		script = $ScriptPath
		exit_code = $exit
		passed = $passed
		pass_pattern = $PassPattern
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "RESULT=|PASS|FAIL|first_loop_duration|M13_30DAY|M14-T01|M14-T02" | Select-Object -Last 16 | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotStaticCheck() {
	$logPath = Join-Path $LogDir "godot_static_editor_check.log"
	$output = & $Godot --headless --editor --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	return [ordered]@{
		name = "godot_static_editor_check"
		command = "$Godot --headless --editor --path $Project --quit"
		script = ""
		exit_code = $exit
		passed = ($exit -eq 0)
		pass_pattern = "exit 0"
		log_path = $logPath
		summary = "Godot editor class registration exit_code=$exit"
	}
}

$tests = @()
$tests += Invoke-GodotStaticCheck
$tests += Invoke-GodotCheck "m14_t01_core_regression" "tests/m14_rescue_core_verify.gd" "M14_T01_RESCUE_CORE_RESULT=PASS"
$tests += Invoke-GodotCheck "m13_smoke_regression" "tests/smoke_test.gd" "SMOKE_TEST_RESULT=PASS"
$tests += Invoke-GodotCheck "m13_progression_regression" "tests/m13_30day_progression_sim_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_economy_balance_regression" "tests/m13_economy_balance_30day_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_unlock_capacity_regression" "tests/m13_unlock_capacity_30day_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_save_load_regression" "tests/m13_save_load_30day_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m14_t02_rescue_ui_verify" "tests/m14_t02_rescue_ui_verify.gd" "M14_T02_RESCUE_FIRST_PLAYABLE_RESULT=PASS"
$tests += Invoke-GodotCheck "m14_t02_screenshot_capture" "tests/m14_t02_capture_screenshots.gd" "M14_T02_SCREENSHOT_CAPTURE_RESULT=PASS"

$generatedImports = @(Get-ChildItem -Path $ScreenshotDir -Filter "*.import" -File -ErrorAction SilentlyContinue)
foreach ($importFile in $generatedImports) {
	Remove-Item -LiteralPath $importFile.FullName -Force -ErrorAction SilentlyContinue
}

$baseTag = "v3.2-m14-t01-rescue-datamodel"
$changed = @()
$diffFiles = @(git -C $Project diff --name-only "$baseTag..HEAD" 2>$null)
foreach ($f in $diffFiles) {
	if ($changed -notcontains $f) { $changed += $f }
}
$statusLines = @(git -C $Project status --short)
foreach ($line in $statusLines) {
	if ($line.Length -ge 4) {
		$path = $line.Substring(3)
		if ($changed -notcontains $path) { $changed += $path }
	}
}
$sceneFilesModified = @($changed | Where-Object { $_ -match "\.tscn$" })
$forbiddenTouched = @()
foreach ($f in $changed) {
	if ($f -match "species_master\.json$" -or $f -match "sea_zone|ocean|breeding|reputation_shop|injury_branch|care_action|multi_rescue") {
		$forbiddenTouched += $f
	}
}
$screenshotFiles = @(
	(Join-Path $ScreenshotDir "01_dock_entry.png"),
	(Join-Path $ScreenshotDir "02_dock_panel_candidate.png"),
	(Join-Path $ScreenshotDir "03_rescue_slot_recovering.png"),
	(Join-Path $ScreenshotDir "04_ready_to_release.png"),
	(Join-Path $ScreenshotDir "05_release_settlement.png"),
	(Join-Path $ScreenshotDir "06_reputation_display.png"),
	(Join-Path $ScreenshotDir "07_codex_rescued_badge.png")
)
$missingScreenshots = @()
foreach ($shot in $screenshotFiles) {
	if (-not (Test-Path $shot)) {
		$missingScreenshots += $shot
		continue
	}
	if ((Get-Item $shot).Length -le 1000) {
		$missingScreenshots += $shot
	}
}

$allTestsPass = (@($tests | Where-Object { -not $_.passed }).Count -eq 0)
$m13Pass = (@($tests | Where-Object { $_.name -like "m13_*" -and -not $_.passed }).Count -eq 0)
$t01Pass = (@($tests | Where-Object { $_.name -eq "m14_t01_core_regression" -and $_.passed }).Count -eq 1)
$t02Pass = (@($tests | Where-Object { $_.name -eq "m14_t02_rescue_ui_verify" -and $_.passed }).Count -eq 1)
$screensPass = ($missingScreenshots.Count -eq 0) -and (@($tests | Where-Object { $_.name -eq "m14_t02_screenshot_capture" -and $_.passed }).Count -eq 1)
$firstLoopDuration = ""
$t02Log = Join-Path $LogDir "m14_t02_rescue_ui_verify.log"
if (Test-Path $t02Log) {
	$match = Select-String -Path $t02Log -Pattern "first_loop_duration_seconds=([0-9]+)" | Select-Object -Last 1
	if ($match -ne $null) {
		$firstLoopDuration = $match.Matches[0].Groups[1].Value + " seconds"
	}
}
$result = if ($allTestsPass -and $m13Pass -and $t01Pass -and $t02Pass -and $screensPass -and $forbiddenTouched.Count -eq 0) { "PASS" } else { "FAIL" }
$branch = (git -C $Project branch --show-current 2>$null) -replace "\s+", ""
$commitHash = (git -C $Project rev-parse HEAD 2>$null) -replace "\s+", ""
$worktreeClean = (@(git -C $Project status --short).Count -eq 0)

$report = @()
$report += "# M14-T02 RescueCore FirstPlayable UI And 15MinLoop Report"
$report += ""
$report += "Overall Status: **$result**"
$report += ""
$report += "- Branch: $branch"
$report += "- Base tag: $baseTag"
$report += "- Commit at validation: $commitHash"
$report += "- First loop duration: $firstLoopDuration"
$report += "- Worktree clean at validation: $worktreeClean"
$report += "- Project: $Project"
$report += ""
$report += "## Scope"
$report += ""
$report += "Implemented the minimal playable rescue loop UI over the existing M14-T01 RescueSystem: dock entry, dock panel, single rescue slot, progress display, manual release settlement, ecological reputation display, and rescued codex badge. No ocean system, multi-slot rescue, injury branching, care actions, breeding, card art, reputation shop, or species_master.json changes were added."
$report += ""
$report += "## Scene Diff"
$report += ""
if ($sceneFilesModified.Count -eq 0) {
	$report += "- No .tscn scene files modified. UI is built through existing programmatic panel patterns."
} else {
	foreach ($f in $sceneFilesModified) { $report += "- $f" }
}
$report += ""
$report += "## Test Results"
$report += ""
$report += "| Test | Passed | Exit | Log |"
$report += "|---|---:|---:|---|"
foreach ($t in $tests) {
	$report += "| $($t.name) | $($t.passed) | $($t.exit_code) | $($t.log_path) |"
}
$report += ""
$report += "## Screenshots"
$report += ""
$report += "Headless Godot uses the dummy renderer, so screenshot evidence is generated as deterministic PNG state captures from the same GameState/RescueDockPanel/StatusPanel/LivestockPanel state used by the tests."
foreach ($shot in $screenshotFiles) { $report += "- $shot" }
$report += ""
$report += "## Modified Files"
$report += ""
foreach ($f in $changed) { $report += "- $f" }
$report += ""
$report += "## Forbidden Files Touched"
$report += ""
if ($forbiddenTouched.Count -eq 0) {
	$report += "- None."
} else {
	foreach ($f in $forbiddenTouched) { $report += "- $f" }
}
$report += ""
$report += "## Acceptance Summary"
$report += ""
$report += "- M13 regression result: $($(if ($m13Pass) { "PASS" } else { "FAIL" }))"
$report += "- M14-T01 regression result: $($(if ($t01Pass) { "PASS" } else { "FAIL" }))"
$report += "- M14-T02 first playable result: $($(if ($t02Pass) { "PASS" } else { "FAIL" }))"
$report += "- Screenshot evidence result: $($(if ($screensPass) { "PASS" } else { "FAIL" }))"
$report += "- M14_T01_RESCUE_CORE_DATAMODEL_RESULT=$($(if ($t01Pass) { "PASS" } else { "FAIL" }))"
$report += "- M14_T02_RESCUE_FIRST_PLAYABLE_UI_RESULT=$result"
$report += ""
$report += "## Known Limitations"
$report += ""
$report += "- The screenshot files are automated headless state captures rather than live viewport grabs because the headless dummy renderer does not expose a viewport texture."
$report += "- The rescue UI is intentionally minimal and contains no M14-T03 systems."
Set-Content -Path $ReportPath -Value ($report -join "`n") -Encoding UTF8

$receipt = [ordered]@{
	task_name = "M14-T02_RescueCore_FirstPlayable_UI_And_15MinLoop"
	branch = $branch
	base_tag = $baseTag
	commit_hash = $commitHash
	result = $result
	tests_run = @($tests | ForEach-Object { $_.name })
	tests_passed = @($tests | Where-Object { $_.passed } | ForEach-Object { $_.name })
	m13_regression_result = if ($m13Pass) { "PASS" } else { "FAIL" }
	m14_t01_regression_result = if ($t01Pass) { "PASS" } else { "FAIL" }
	first_playable_result = if ($t02Pass) { "PASS" } else { "FAIL" }
	first_loop_duration = $firstLoopDuration
	save_load_ui_consistency_result = if ($t02Pass) { "PASS" } else { "FAIL" }
	screenshots = $screenshotFiles
	modified_files = $changed
	scene_files_modified = $sceneFilesModified
	forbidden_files_touched = $forbiddenTouched
	report_path = $ReportPath
	receipt_path = $ReceiptPath
	tag = "v3.2-m14-t02-rescue-first-playable-ui"
	known_limitations = @(
		"Headless screenshot evidence is generated from real UI/GameState state rather than viewport texture",
		"No ocean, multi-slot, injury branching, care actions, breeding, card art, or reputation shop",
		"Ecological reputation only accumulates"
	)
	worktree_clean_at_validation = $worktreeClean
	test_details = $tests
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8

Write-Host "M14_T01_RESCUE_CORE_DATAMODEL_RESULT=$($(if ($t01Pass) { "PASS" } else { "FAIL" }))"
Write-Host "M13_REGRESSION_RESULT=$($(if ($m13Pass) { "PASS" } else { "FAIL" }))"
Write-Host "M14_T02_RESCUE_FIRST_PLAYABLE_UI_RESULT=$result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
