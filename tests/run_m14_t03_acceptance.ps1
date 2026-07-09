$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Project "reports\m14"
$LogDir = Join-Path $ReportDir "logs"
$ScreenshotDir = Join-Path $ReportDir "screenshots"
$ReportPath = Join-Path $ReportDir "M14_T03_RESCUE_UX_PACING_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M14_T03_RESCUE_UX_PACING_RECEIPT.json"
$HandoffPath = Join-Path $ReportDir "M14_T03_CODEX_HANDOFF.md"
$BlindPlaytestPath = Join-Path $ReportDir "M14_T03_BLIND_PLAYTEST_REPORT.md"
$EvidenceFixupReportPath = Join-Path $ReportDir "M14_T03_EVIDENCE_FIXUP_REPORT.md"
$FinalClosureMetadataReportPath = Join-Path $ReportDir "M14_T03_FINAL_CLOSURE_METADATA_REPORT.md"
$OriginalCloudCodeCommit = "bfa50f30c7e1f9b79ca5ea38463136482aaf69ed"
$SupersededTag = "v3.2-m14-t03-rescue-ux-pacing"
$EvidenceFixupValidationCommit = "a566b3ac15ba44381661a7918f6da4e6bf1eeb8b"
$Fix1FinalClosureCommit = "d6a29aac73b963f7d9b21600c2c9b364573e6ad6"
$Fix1Tag = "v3.2-m14-t03-rescue-ux-pacing-fix1"
$Fix1TagTargetCommit = "d6a29aac73b963f7d9b21600c2c9b364573e6ad6"
$FinalCandidateTag = "v3.2-m14-t03-rescue-ux-pacing-fix2"
$FinalCandidateTagTargetVerificationCommand = "git rev-parse v3.2-m14-t03-rescue-ux-pacing-fix2"
$EvidenceChainStatus = "fix1 tag target d6a29aac73b963f7d9b21600c2c9b364573e6ad6 is explicitly recorded; fix2 is a metadata-only alignment candidate pending Codex review"
$CodexSecondReviewBlockerResolved = "pending_codex_review"
$TopUxIssues = @(
	"恢复等待期间缺少主动操作 -> M15 护理决策",
	"救助生物没有视觉形象 -> M16 卡牌美术接入",
	"声望缺乏阶段感 -> M18 守护者等级 / 称号"
)
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
		summary = (($text -split "`r?`n") | Select-String -Pattern "RESULT=|PASS|FAIL|first_loop_duration|M13_30DAY|M14-T01|M14-T02|M14-T03" | Select-Object -Last 16 | ForEach-Object { $_.Line }) -join "`n"
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
$tests += Invoke-GodotCheck "m14_t03_copy_ui_verify" "tests/m14_t03_copy_ui_verify.gd" "M14_T03_COPY_UI_VERIFY_RESULT=PASS"
$tests += Invoke-GodotCheck "m14_t03_screenshot_capture" "tests/m14_t03_capture_screenshots.gd" "M14_T03_SCREENSHOT_CAPTURE_RESULT=PASS"

# Clean up generated .import files
$generatedImports = @(Get-ChildItem -Path $ScreenshotDir -Filter "*.import" -File -ErrorAction SilentlyContinue)
foreach ($importFile in $generatedImports) {
	Remove-Item -LiteralPath $importFile.FullName -Force -ErrorAction SilentlyContinue
}

# Modified files detection
$baseTag = "v3.2-m14-t02-rescue-first-playable-ui"
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

# Forbidden scope check
$forbiddenPatterns = @(
	"sea_zone", "ocean", "ocean_map", "海域",
	"breeding", "繁殖",
	"injury_branch", "伤情",
	"care_action", "护理",
	"multi_rescue", "多救助位",
	"reputation_shop", "声望商店",
	"reputation_level", "声望等级",
	"species_master\.json",
	"card_art", "卡牌美术"
)
$forbiddenTouched = @()
foreach ($f in $changed) {
	foreach ($pattern in $forbiddenPatterns) {
		if ($f -match $pattern) {
			if ($forbiddenTouched -notcontains $f) { $forbiddenTouched += $f }
		}
	}
}

# Also check that forbidden files weren't diffed
$forbiddenFiles = @("species_master.json", "scripts/systems/WaterChemistrySystem.gd")
foreach ($ff in $forbiddenFiles) {
	$ffDiff = @(git -C $Project diff --name-only "$baseTag..HEAD" -- $ff 2>$null)
	if ($ffDiff.Count -gt 0) {
		if ($forbiddenTouched -notcontains $ff) { $forbiddenTouched += $ff }
	}
}

# Screenshot evidence check
$screenshotFiles = @(
	(Join-Path $ScreenshotDir "t03_01_dock_entry.png"),
	(Join-Path $ScreenshotDir "t03_02_dock_candidate.png"),
	(Join-Path $ScreenshotDir "t03_03_rescue_slot_after_bring.png"),
	(Join-Path $ScreenshotDir "t03_04_recovering.png"),
	(Join-Path $ScreenshotDir "t03_05_ready_to_release.png"),
	(Join-Path $ScreenshotDir "t03_06_release_settlement.png"),
	(Join-Path $ScreenshotDir "t03_07_reputation_change.png"),
	(Join-Path $ScreenshotDir "t03_08_codex_rescued_mark.png"),
	(Join-Path $ScreenshotDir "t03_09_next_arrival_waiting.png")
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

# Results computation
$allTestsPass = (@($tests | Where-Object { -not $_.passed }).Count -eq 0)
$m13Pass = (@($tests | Where-Object { $_.name -like "m13_*" -and -not $_.passed }).Count -eq 0)
$t01Pass = (@($tests | Where-Object { $_.name -eq "m14_t01_core_regression" -and $_.passed }).Count -eq 1)
$t02Pass = (@($tests | Where-Object { $_.name -eq "m14_t02_rescue_ui_verify" -and $_.passed }).Count -eq 1)
$t03CopyPass = (@($tests | Where-Object { $_.name -eq "m14_t03_copy_ui_verify" -and $_.passed }).Count -eq 1)
$t03ScreenshotPass = (@($tests | Where-Object { $_.name -eq "m14_t03_screenshot_capture" -and $_.passed }).Count -eq 1)
$screensPass = ($missingScreenshots.Count -eq 0)
$forbiddenPass = ($forbiddenTouched.Count -eq 0)

# First loop duration extraction
$firstLoopDuration = ""
$t02Log = Join-Path $LogDir "m14_t02_rescue_ui_verify.log"
if (Test-Path $t02Log) {
	$match = Select-String -Path $t02Log -Pattern "first_loop_duration_seconds=([0-9]+)" | Select-Object -Last 1
	if ($match -ne $null) {
		$firstLoopDuration = $match.Matches[0].Groups[1].Value + " seconds"
	}
}

$result = if ($allTestsPass -and $m13Pass -and $t01Pass -and $t02Pass -and $t03CopyPass -and $t03ScreenshotPass -and $screensPass -and $forbiddenPass) { "PASS" } else { "FAIL" }
$branch = (git -C $Project branch --show-current 2>$null) -replace "\s+", ""
$commitHash = (git -C $Project rev-parse HEAD 2>$null) -replace "\s+", ""
$existingFinalValidationCommit = ""
$existingMetadataAlignmentCommit = ""
if (Test-Path $ReceiptPath) {
	try {
		$existingReceipt = Get-Content -Raw -Path $ReceiptPath | ConvertFrom-Json
		$existingFinalValidationCommit = [string]$existingReceipt.final_validation_commit
		$existingMetadataAlignmentCommit = [string]$existingReceipt.metadata_alignment_commit
	} catch {
		$existingFinalValidationCommit = ""
		$existingMetadataAlignmentCommit = ""
	}
}
$finalValidationCommit = if ($existingFinalValidationCommit -match "^[0-9a-f]{40}$" -and $existingFinalValidationCommit -ne $OriginalCloudCodeCommit) { $existingFinalValidationCommit } else { $commitHash }
$metadataAlignmentCommit = if ($existingMetadataAlignmentCommit -match "^[0-9a-f]{40}$") { $existingMetadataAlignmentCommit } else { $commitHash }
$worktreeClean = (@(git -C $Project status --short).Count -eq 0)

# Generate report
$report = @()
$report += "# M14-T03 RescueCore BlindPlaytest UX And Pacing Hardening Report"
$report += ""
$report += "Overall Status: **$result**"
$report += ""
$report += "- Branch: $branch"
$report += "- Base tag: $baseTag"
$report += "- Commit at validation: $finalValidationCommit"
$report += "- Original Cloud Code commit: $OriginalCloudCodeCommit"
$report += "- Final validation commit: $finalValidationCommit"
$report += "- Superseded tag: $SupersededTag"
$report += "- Closure candidate tag: $FinalCandidateTag"
$report += "- First loop duration: $firstLoopDuration"
$report += "- Worktree clean at validation: $worktreeClean"
$report += "- Project: $Project"
$report += ""
$report += "## Evidence Closure Chain"
$report += ""
$report += "- original_cloudcode_commit = $OriginalCloudCodeCommit"
$report += "- evidence_fixup_validation_commit = $EvidenceFixupValidationCommit"
$report += "- fix1_final_closure_commit = $Fix1FinalClosureCommit"
$report += "- fix1_tag = $Fix1Tag"
$report += "- fix1_tag_target_commit = $Fix1TagTargetCommit"
$report += "- metadata_alignment_commit = $metadataAlignmentCommit"
$report += "- fix2_purpose = metadata-only clarification of final closure chain"
$report += "- final_candidate_tag = $FinalCandidateTag"
$report += "- final_candidate_tag_target must be verified by: $FinalCandidateTagTargetVerificationCommand"
$report += "- evidence_chain_status = $EvidenceChainStatus"
$report += "- codex_second_review_blocker_resolved = $CodexSecondReviewBlockerResolved"
$report += ""
$report += "## Scope"
$report += ""
$report += "M14-T03 is a UX hardening pass over the M14-T02 rescue loop: copy text refinement (dock entry, rescue status, bring-back button, recovery progress, release settlement, reputation explanation, codex marks), rescue_config pacing tuning, and UI state feedback hardening. No new systems were added. No ocean, multi-slot, injury branching, care actions, breeding, card art, or reputation shop changes."
$report += ""
$report += "## Copy Text Changes"
$report += ""
$report += "- RescueDockPanel: title 救助码头→海洋救助站, dock status contextualized, candidate description softened, bring-back button 带回救助→带回照料, slot labels clarified, progress text improved, release button 放归→放归大海, feedback defaults updated, codex marks labeled as 救助图鉴"
$report += "- StatusPanel: rescue button states refined (救助!/救助中/可放归!), tooltips improved with gameplay hints, color coding enhanced"
$report += "- GameState: settlement feedback texts rewritten for emotional clarity (带回照料, 放归成功+回归大海)"
$report += "- LivestockPanel: codex display header updated to 救助图鉴（已救助物种）"
$report += "- rescue_config.json: added dock_entry_hint, next_arrival_hint, release_settlement_hint for UI display"
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
$report += "M14-T03 screenshot evidence generated as deterministic PNG state captures."
foreach ($shot in $screenshotFiles) { $report += "- $shot" }
$report += ""
$report += "## Modified Files"
$report += ""
foreach ($f in $changed) { $report += "- $f" }
$report += ""
$report += "## Forbidden Files Touched"
$report += ""
if ($forbiddenTouched.Count -eq 0) {
	$report += "- None. Forbidden scope check PASS."
} else {
	foreach ($f in $forbiddenTouched) { $report += "- $f (FORBIDDEN)" }
}
$report += ""
$report += "## Acceptance Summary"
$report += ""
$report += "- M13 regression result: $(if ($m13Pass) { "PASS" } else { "FAIL" })"
$report += "- M14-T01 regression result: $(if ($t01Pass) { "PASS" } else { "FAIL" })"
$report += "- M14-T02 regression result: $(if ($t02Pass) { "PASS" } else { "FAIL" })"
$report += "- M14-T03 copy/UI verify result: $(if ($t03CopyPass) { "PASS" } else { "FAIL" })"
$report += "- M14-T03 screenshot evidence: $(if ($t03ScreenshotPass) { "PASS" } else { "FAIL" })"
$report += "- Forbidden scope check: $(if ($forbiddenPass) { "PASS (0 touched)" } else { "FAIL" })"
$report += "- M14_T03_RESCUE_UX_PACING_RESULT=$result"
$report += ""
$report += "## Known Limitations"
$report += ""
$report += "- Headless screenshot evidence uses deterministic state captures (dummy renderer limitation)"
$report += "- Blind playtest report is a separate human-authored document (M14_T03_BLIND_PLAYTEST_REPORT.md)"
$report += "- Copy refinements are in Chinese (zh-CN); no i18n framework exists yet"
$report += "- T03 does not add new systems; all changes are cosmetic/feedback within the existing rescue loop"
$report += "- ${SupersededTag}: superseded by evidence fix"
$report += "- ${Fix1Tag}: superseded by fix2 metadata alignment candidate"
$report += "- ${FinalCandidateTag}: Codex-reviewable metadata alignment candidate"
Set-Content -Path $ReportPath -Value ($report -join "`n") -Encoding UTF8

# Generate receipt
$receipt = [ordered]@{
	task_name = "M14-T03_RescueCore_BlindPlaytest_UX_And_Pacing_Hardening"
	branch = $branch
	base_tag = $baseTag
	original_cloudcode_commit = $OriginalCloudCodeCommit
	evidence_fixup_validation_commit = $EvidenceFixupValidationCommit
	fix1_final_closure_commit = $Fix1FinalClosureCommit
	fix1_tag = $Fix1Tag
	fix1_tag_target_commit = $Fix1TagTargetCommit
	metadata_alignment_commit = $metadataAlignmentCommit
	final_candidate_tag = $FinalCandidateTag
	final_candidate_tag_target_verification_command = $FinalCandidateTagTargetVerificationCommand
	evidence_chain_status = $EvidenceChainStatus
	codex_second_review_blocker_resolved = $CodexSecondReviewBlockerResolved
	fixup_commit_hash = $finalValidationCommit
	final_validation_commit = $finalValidationCommit
	commit_hash = $finalValidationCommit
	result = $result
	m13_regression_result = if ($m13Pass) { "PASS" } else { "FAIL" }
	m14_t01_regression_result = if ($t01Pass) { "PASS" } else { "FAIL" }
	m14_t02_regression_result = if ($t02Pass) { "PASS" } else { "FAIL" }
	m14_t03_acceptance_result = $result
	first_loop_duration = $firstLoopDuration
	blind_playtest_result = "See M14_T03_BLIND_PLAYTEST_REPORT.md"
	top_ux_issues = $TopUxIssues
	screenshots = $screenshotFiles
	modified_files = $changed
	forbidden_files_touched = $forbiddenTouched
	report_path = $ReportPath
	blind_playtest_report_path = $BlindPlaytestPath
	codex_handoff_path = $HandoffPath
	evidence_fixup_report_path = $EvidenceFixupReportPath
	final_closure_metadata_report_path = $FinalClosureMetadataReportPath
	receipt_path = $ReceiptPath
	tag = $FinalCandidateTag
	supersedes_tag = $SupersededTag
	worktree_clean_after_rerun = $worktreeClean
	recommendation_for_m14_t04 = "DO_NOT_ENTER_T04_PENDING_CODEX_REVIEW"
	codex_handoff_ready = $true
	tests_run = @($tests | ForEach-Object { $_.name })
	tests_passed = @($tests | Where-Object { $_.passed } | ForEach-Object { $_.name })
	worktree_clean_at_validation = $worktreeClean
	test_details = $tests
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8

Write-Host "M14_T01_RESCUE_CORE_DATAMODEL_RESULT=$(if ($t01Pass) { "PASS" } else { "FAIL" })"
Write-Host "M13_REGRESSION_RESULT=$(if ($m13Pass) { "PASS" } else { "FAIL" })"
Write-Host "M14_T02_RESCUE_FIRST_PLAYABLE_UI_RESULT=$(if ($t02Pass) { "PASS" } else { "FAIL" })"
Write-Host "M14_T03_RESCUE_UX_PACING_RESULT=$result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "FORBIDDEN_TOUCHED=$($forbiddenTouched.Count)"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
