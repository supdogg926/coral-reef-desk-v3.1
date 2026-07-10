$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Project "reports\m15"
$LogDir = Join-Path $ReportDir "logs"
$ScreenshotDir = Join-Path $ReportDir "screenshots"
$ReportPath = Join-Path $ReportDir "M15_T02_CARE_PLAYABLE_UI_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M15_T02_CARE_PLAYABLE_UI_RECEIPT.json"
$TaskName = "M15-T02_CarePlayable_UI_FirstLoop"
$BaseTag = "v3.3-m15-t01-care-datamodel"
$FinalTag = "v3.3-m15-t02-care-playable-ui"
$EvidenceRuleVersion = "no_self_referential_annotated_tag_closure_v1"

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
		summary = (($text -split "`r?`n") | Select-String -Pattern "RESULT=|PASS|FAIL|first_loop_duration|BASELINE_BIT_EQUIVALENCE|RNG_DETERMINISM|V2_TO_V3_MIGRATION|M15-T02|M15_T02|SCREENSHOT|VIEWPORT|SEMANTIC" | Select-Object -Last 40 | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotViewportCheck($Name, $ScriptPath, $PassPattern) {
	$logPath = Join-Path $LogDir "$Name.log"
	$output = & $Godot --path $Project --script $ScriptPath 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	$passed = ($exit -eq 0) -and ($text -match $PassPattern)
	return [ordered]@{
		name = $Name
		command = "$Godot --path $Project --script $ScriptPath"
		script = $ScriptPath
		exit_code = $exit
		passed = $passed
		pass_pattern = $PassPattern
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "RESULT=|PASS|FAIL|first_loop_duration|M15-T02|M15_T02|SCREENSHOT|VIEWPORT|SEMANTIC" | Select-Object -Last 40 | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotStaticCheck() {
	$logPath = Join-Path $LogDir "m15_t02_godot_static_editor_check.log"
	$output = & $Godot --headless --editor --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-GeneratedImports
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

function Remove-GeneratedImports() {
	foreach ($dir in @((Join-Path $Project "reports\m14\screenshots"), (Join-Path $Project "reports\m15\screenshots"))) {
		$generatedImports = @(Get-ChildItem -Path $dir -Filter "*.import" -File -ErrorAction SilentlyContinue)
		foreach ($importFile in $generatedImports) {
			Remove-Item -LiteralPath $importFile.FullName -Force -ErrorAction SilentlyContinue
		}
	}
}

function Restore-GeneratedReportDrift() {
	git -C $Project restore -- reports/m14/M14_T04_RESCUE_CORE_RELEASE_CANDIDATE_REPORT.md reports/m14/M14_T04_RESCUE_CORE_RELEASE_CANDIDATE_RECEIPT.json 2>$null | Out-Null
}

function Restore-ScreenshotEvidenceDrift() {
	git -C $Project restore -- `
		reports/m15/screenshots/m15_t02_01_care_need_visible.png `
		reports/m15/screenshots/m15_t02_02_three_care_buttons.png `
		reports/m15/screenshots/m15_t02_03_after_care_feedback.png `
		reports/m15/screenshots/m15_t02_04_ready_after_care.png `
		reports/m15/screenshots/m15_t02_05_release_bonus_line.png 2>$null | Out-Null
}

function Test-ScreenshotEvidence {
	param(
		[string]$Path,
		[int]$MinWidth = 800,
		[int]$MinHeight = 450,
		[double]$MinPixelVariance = 1.0
	)
	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		return [ordered]@{ path = $Path; passed = $false; error = "missing"; width = 0; height = 0; pixel_variance = 0.0; length = 0 }
	}
	Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
	$image = [System.Drawing.Bitmap]::new($Path)
	try {
		$width = [int]$image.Width
		$height = [int]$image.Height
		$stepX = [Math]::Max([int]($width / 32), 1)
		$stepY = [Math]::Max([int]($height / 32), 1)
		$values = New-Object System.Collections.Generic.List[double]
		for ($y = 0; $y -lt $height; $y += $stepY) {
			for ($x = 0; $x -lt $width; $x += $stepX) {
				$p = $image.GetPixel($x, $y)
				$values.Add((0.299 * $p.R) + (0.587 * $p.G) + (0.114 * $p.B)) | Out-Null
			}
		}
		$avg = ($values | Measure-Object -Average).Average
		$variance = 0.0
		foreach ($v in $values) {
			$variance += [Math]::Pow(($v - $avg), 2)
		}
		$variance = $variance / [Math]::Max($values.Count, 1)
		$length = (Get-Item -LiteralPath $Path).Length
		$passed = ($width -ge $MinWidth) -and ($height -ge $MinHeight) -and ($width -ne 32) -and ($height -ne 32) -and ($variance -ge $MinPixelVariance)
		return [ordered]@{ path = $Path; passed = $passed; error = ""; width = $width; height = $height; pixel_variance = $variance; length = $length }
	}
	finally {
		$image.Dispose()
	}
}

function Test-ViewportCaptureSource() {
	$scriptPath = Join-Path $Project "tests\m15_t02_capture_screenshots.gd"
	$text = Get-Content -LiteralPath $scriptPath -Raw
	$hasViewportCapture = ($text -match "get_texture\(\)\.get_image\(\)")
	$banned = @("Image.create", "fill_rect", "draw_")
	$foundBanned = @()
	foreach ($token in $banned) {
		if ($text.Contains($token)) {
			$foundBanned += $token
		}
	}
	return [ordered]@{
		passed = ($hasViewportCapture -and $foundBanned.Count -eq 0)
		has_viewport_capture = $hasViewportCapture
		banned_tokens_found = $foundBanned
	}
}

function Add-UniqueFile([string[]]$Files, [string]$File) {
	if ($File -and ($Files -notcontains $File)) {
		return @($Files + $File)
	}
	return $Files
}

$staticCheck = Invoke-GodotStaticCheck
$m15T01Check = Invoke-GodotCheck "m15_t01_caremodel_verify" "tests/m15_t01_caremodel_verify.gd" "M15_T01_CAREMODEL_RESULT=PASS"
$m15T02Check = Invoke-GodotCheck "m15_t02_care_ui_verify" "tests/m15_t02_care_ui_verify.gd" "M15_T02_CARE_PLAYABLE_UI_RESULT=PASS"
$screenshotCapture = Invoke-GodotViewportCheck "m15_t02_screenshot_capture" "tests/m15_t02_capture_screenshots.gd" "M15_T02_SCREENSHOT_CAPTURE_RESULT=PASS"
Remove-GeneratedImports

$t04LogPath = Join-Path $LogDir "m15_t02_m14_final_regression.log"
$t04Output = & PowerShell -ExecutionPolicy Bypass -File (Join-Path $Project "tests\run_m14_t04_release_candidate.ps1") 2>&1
$t04Exit = $LASTEXITCODE
$t04Text = if ($t04Output -is [array]) { $t04Output -join "`n" } else { "$t04Output" }
Set-Content -Path $t04LogPath -Value $t04Text -Encoding UTF8
Restore-GeneratedReportDrift
Remove-GeneratedImports

$m13Result = if ($t04Text -match "M13_REGRESSION_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T01Result = if ($t04Text -match "M14_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T02Result = if ($t04Text -match "M14_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T03Result = if ($t04Text -match "M14_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T04Result = if (($t04Exit -eq 0) -and ($t04Text -match "M14_T04_RESCUE_CORE_RELEASE_CANDIDATE_RESULT=PASS")) { "PASS" } else { "FAIL" }
$firstLoopDuration = ""
if ($t04Text -match "FIRST_LOOP_DURATION=([0-9]+ seconds)") {
	$firstLoopDuration = $Matches[1]
}
$t04ForbiddenTouched = -1
if ($t04Text -match "FORBIDDEN_TOUCHED=([0-9]+)") {
	$t04ForbiddenTouched = [int]$Matches[1]
}
$t02FirstLoopDuration = ""
if ($m15T02Check.summary -match "first_loop_duration_seconds=([0-9]+)") {
	$t02FirstLoopDuration = $Matches[1] + " seconds"
}

$screenshots = @(Get-ChildItem -Path $ScreenshotDir -Filter "m15_t02_*.png" -File -ErrorAction SilentlyContinue | Sort-Object Name)
$screenshotChecks = @()
foreach ($shot in $screenshots) {
	$screenshotChecks += Test-ScreenshotEvidence $shot.FullName
}
$viewportSourceCheck = Test-ViewportCaptureSource
$uiSemanticPass = ($screenshotCapture.summary -match "M15_T02_UI_SEMANTIC_ASSERTIONS=PASS")
$viewportCapturePass = ($screenshotCapture.summary -match "M15_T02_VIEWPORT_CAPTURE_SOURCE=PASS")
$screenshotPass = ($screenshots.Count -ge 5) -and (@($screenshotChecks | Where-Object { -not $_.passed }).Count -eq 0) -and [bool]$screenshotCapture.passed -and [bool]$viewportSourceCheck.passed -and $uiSemanticPass -and $viewportCapturePass
Restore-ScreenshotEvidenceDrift
$screenshots = @(Get-ChildItem -Path $ScreenshotDir -Filter "m15_t02_*.png" -File -ErrorAction SilentlyContinue | Sort-Object Name)
$screenshotChecks = @()
foreach ($shot in $screenshots) {
	$screenshotChecks += Test-ScreenshotEvidence $shot.FullName
}
$screenshotPass = $screenshotPass -and ($screenshots.Count -ge 5) -and (@($screenshotChecks | Where-Object { -not $_.passed }).Count -eq 0)

$changed = @()
$diffFiles = @(git -C $Project diff --name-only "$BaseTag..HEAD" 2>$null)
foreach ($f in $diffFiles) { $changed = Add-UniqueFile $changed $f }
$statusLines = @(git -C $Project status --short)
foreach ($line in $statusLines) {
	if ($line.Length -ge 4) {
		$path = $line.Substring(3)
		$fullPath = Join-Path $Project $path
		if (Test-Path -LiteralPath $fullPath -PathType Container) {
			$files = @(Get-ChildItem -LiteralPath $fullPath -Recurse -File -Force | Where-Object { $_.Name -notlike "*.log" -and $_.Name -notlike "*.import" })
			foreach ($file in $files) {
				$relative = $file.FullName.Substring($Project.Length + 1).Replace("\", "/")
				$changed = Add-UniqueFile $changed $relative
			}
		} else {
			$changed = Add-UniqueFile $changed $path
		}
	}
}
$changed = Add-UniqueFile $changed "reports/m15/M15_T02_CARE_PLAYABLE_UI_REPORT.md"
$changed = Add-UniqueFile $changed "reports/m15/M15_T02_CARE_PLAYABLE_UI_RECEIPT.json"
$changed = Add-UniqueFile $changed "tests/run_m15_t02_acceptance.ps1"
$changed = Add-UniqueFile $changed "tests/m15_t02_care_ui_verify.gd"
$changed = Add-UniqueFile $changed "tests/m15_t02_capture_screenshots.gd"
$changed = @($changed | Sort-Object -Unique)

$allowedPrefixes = @(
	"scripts/systems/GameState.gd",
	"scripts/systems/RescueSystem.gd",
	"scenes/ui/RescueDockPanel.gd",
	"tests/m15_t02_care_ui_verify.gd",
	"tests/m15_t02_capture_screenshots.gd",
	"tests/run_m15_t02_acceptance.ps1",
	"reports/m15/M15_T02_CARE_PLAYABLE_UI_REPORT.md",
	"reports/m15/M15_T02_CARE_PLAYABLE_UI_RECEIPT.json",
	"reports/m15/M15_T03_CARE_DECISION_RC_REPORT.md",
	"reports/m15/M15_T03_CARE_DECISION_RC_RECEIPT.json",
	"reports/m15/M15_FINAL_CLOSEOUT_REPORT.md",
	"reports/m15/M15_FINAL_CLOSEOUT_RECEIPT.json",
	"tests/run_m15_t03_acceptance.ps1",
	"reports/m15/screenshots/"
)
$forbiddenTouched = @()
foreach ($f in $changed) {
	$allowed = $false
	foreach ($prefix in $allowedPrefixes) {
		if ($f -eq $prefix -or $f.StartsWith($prefix)) {
			$allowed = $true
			break
		}
	}
	if (-not $allowed) {
		$forbiddenTouched += $f
		continue
	}
	if ($f -match "\.tscn$" -or $f -match "LivestockSystem\.gd$" -or $f -match "WaterChemistrySystem\.gd$" -or $f -match "TimeSystem\.gd$" -or $f -match "species_master\.json$" -or $f -match "species_rescue_pool\.json$" -or $f -match "^tests/run_m1[34]_" -or $f -match "^tests/m1[34]_") {
		$forbiddenTouched += $f
	}
}
$forbiddenTouched = @($forbiddenTouched | Select-Object -Unique)

$allRegressionPass = ($m13Result -eq "PASS") -and ($m14T01Result -eq "PASS") -and ($m14T02Result -eq "PASS") -and ($m14T03Result -eq "PASS") -and ($m14T04Result -eq "PASS") -and [bool]$m15T01Check.passed
$t02LoopPass = $false
if ($t02FirstLoopDuration -match "([0-9]+)") {
	$t02LoopPass = ([int]$Matches[1] -le 900)
}
$result = if ($staticCheck.passed -and $m15T02Check.passed -and $screenshotPass -and $allRegressionPass -and $t02LoopPass -and ($t04ForbiddenTouched -eq 0) -and ($forbiddenTouched.Count -eq 0)) { "PASS" } else { "FAIL" }

$branch = (git -C $Project branch --show-current 2>$null) -replace "\s+", ""
$headCommitVerification = "verified externally by: git rev-parse HEAD"

$report = @()
$report += "# M15-T02 CarePlayable UI FirstLoop Report"
$report += ""
$report += "Overall Status: **$result**"
$report += ""
$report += "- Task: $TaskName"
$report += "- Branch: $branch"
$report += "- Base tag: $BaseTag"
$report += "- HEAD commit: $headCommitVerification"
$report += "- Evidence rule: $EvidenceRuleVersion"
$report += "- Final tag: $FinalTag"
$report += "- Validation command: PowerShell -ExecutionPolicy Bypass -File tests/run_m15_t02_acceptance.ps1"
$report += ""
$report += "## Scope"
$report += ""
$report += "T02 adds only playable UI access for the M15 care decision: a visible care need, three care buttons, single-use behavior, post-care feedback, and an appended care bonus line on successful release. It does not add observation, daily care, secondary needs, visible ratings, new resources, ocean systems, art, shops, or M16 work."
$report += ""
$report += "## Acceptance Results"
$report += ""
$report += "- M15-T02 UI result: $($(if ($m15T02Check.passed) { "PASS" } else { "FAIL" }))"
$report += "- Screenshot capture result: $($(if ($screenshotCapture.passed) { "PASS" } else { "FAIL" }))"
$report += "- Screenshot resolution/variance result: $($(if ($screenshotPass) { "PASS" } else { "FAIL" }))"
$report += "- Screenshot viewport source result: $($(if ($viewportSourceCheck.passed) { "PASS" } else { "FAIL" }))"
$report += "- UI semantic assertion result: $($(if ($uiSemanticPass) { "PASS" } else { "FAIL" }))"
$report += "- M15-T01 regression: $($(if ($m15T01Check.passed) { "PASS" } else { "FAIL" }))"
$report += "- M13 regression: $m13Result"
$report += "- M14-T01 regression: $m14T01Result"
$report += "- M14-T02 regression: $m14T02Result"
$report += "- M14-T03 regression: $m14T03Result"
$report += "- M14-T04 regression: $m14T04Result"
$report += "- M14 FIRST_LOOP_DURATION: $firstLoopDuration"
$report += "- M15-T02 FIRST_LOOP_DURATION: $t02FirstLoopDuration"
$report += "- FORBIDDEN_TOUCHED: $($forbiddenTouched.Count)"
$report += ""
$report += "## First Loop Stability"
$report += ""
$report += "- M14 / no-care baseline FIRST_LOOP_DURATION remains $firstLoopDuration from M14 final regression."
$report += "- M15 care path FIRST_LOOP_DURATION is $t02FirstLoopDuration under a fixed new-game test state, fixed rescue_id sequence, fixed care_need=weak, fixed care action=nutrition, water quality 40, and comfort 40."
$report += "- The M15 care path is <= 900 seconds and is separate from the M14 no-care baseline equivalence tested by M15-T01."
$report += "- This fix removes local save/offline-state influence from T02/T03 evidence and does not modify gameplay code."
$report += ""
$report += "## Screenshot Evidence"
$report += ""
$report += "| File | Width | Height | Pixel variance | Passed |"
$report += "|---|---:|---:|---:|---:|"
foreach ($check in $screenshotChecks) {
	$report += "| $($check.path) | $($check.width) | $($check.height) | $([Math]::Round($check.pixel_variance, 2)) | $($check.passed) |"
}
$report += ""
$report += "## Modified Files"
$report += ""
foreach ($f in $changed) { $report += "- $f" }
$report += ""
$report += "## Forbidden Scope"
$report += ""
if ($forbiddenTouched.Count -eq 0) {
	$report += "- None."
} else {
	foreach ($f in $forbiddenTouched) { $report += "- $f" }
}
$report += ""
$report += "## Evidence Rule"
$report += ""
$report += "- evidence_rule_version: $EvidenceRuleVersion"
$report += "- git rev-parse <tag> verifies the annotated tag object."
$report += "- git rev-parse <tag>^{} verifies the tag target commit."
$report += "- The annotated tag object is not required inside its own target commit."
Set-Content -Path $ReportPath -Value ($report -join "`n") -Encoding UTF8

$receipt = [ordered]@{
	task_name = $TaskName
	branch = $branch
	base_tag = $BaseTag
	commit_hash = $headCommitVerification
	result = $result
	evidence_rule_version = $EvidenceRuleVersion
	m15_t02_result = if ($m15T02Check.passed) { "PASS" } else { "FAIL" }
	m15_t01_result = if ($m15T01Check.passed) { "PASS" } else { "FAIL" }
	m13_result = $m13Result
	m14_t01_result = $m14T01Result
	m14_t02_result = $m14T02Result
	m14_t03_result = $m14T03Result
	m14_t04_result = $m14T04Result
	first_loop_duration = $firstLoopDuration
	m15_t02_first_loop_duration = $t02FirstLoopDuration
	first_loop_stability_note = "M14/no-care baseline remains $firstLoopDuration; M15 care path uses fixed test state with care_need=weak, action=nutrition, water_quality=40, comfort=40."
	forbidden_touched = $forbiddenTouched.Count
	forbidden_files_touched = $forbiddenTouched
	screenshot_result = if ($screenshotPass) { "PASS" } else { "FAIL" }
	screenshot_viewport_source_result = if ($viewportSourceCheck.passed) { "PASS" } else { "FAIL" }
	screenshot_viewport_source_check = $viewportSourceCheck
	ui_semantic_assertion_result = if ($uiSemanticPass) { "PASS" } else { "FAIL" }
	screenshot_checks = $screenshotChecks
	modified_files = $changed
	report_path = "reports/m15/M15_T02_CARE_PLAYABLE_UI_REPORT.md"
	receipt_path = "reports/m15/M15_T02_CARE_PLAYABLE_UI_RECEIPT.json"
	final_tag = $FinalTag
	final_tag_target_verification_command = "git rev-parse $FinalTag^{}"
	final_tag_object_verification_command = "git rev-parse $FinalTag"
	worktree_clean_after_rerun = "verified externally by: git status --short"
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8

Write-Host "M15_T02_CARE_PLAYABLE_UI_RESULT=$result"
Write-Host "M15_T01_RESULT=$($(if ($m15T01Check.passed) { "PASS" } else { "FAIL" }))"
Write-Host "M13_RESULT=$m13Result"
Write-Host "M14_T01_RESULT=$m14T01Result"
Write-Host "M14_T02_RESULT=$m14T02Result"
Write-Host "M14_T03_RESULT=$m14T03Result"
Write-Host "M14_T04_RESULT=$m14T04Result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "M15_T02_FIRST_LOOP_DURATION=$t02FirstLoopDuration"
Write-Host "SCREENSHOT_RESOLUTION_RESULT=$($(if ($screenshotPass) { "PASS" } else { "FAIL" }))"
Write-Host "SCREENSHOT_VIEWPORT_SOURCE_RESULT=$($(if ($viewportSourceCheck.passed) { "PASS" } else { "FAIL" }))"
Write-Host "UI_SEMANTIC_ASSERTION_RESULT=$($(if ($uiSemanticPass) { "PASS" } else { "FAIL" }))"
Write-Host "FORBIDDEN_TOUCHED=$($forbiddenTouched.Count)"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
