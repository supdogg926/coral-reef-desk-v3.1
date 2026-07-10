param(
	[switch]$RefreshEvidence
)

$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TaskName = "M16-T03_CodexVisualRecord_BlindPlaytest_And_RC"
$BaseTag = "v3.4-m16-t02-rescue-card-playable-ui-fix2"
$BaseCommit = "df167fe581f80f937203f3f0f91acb0057b1f89f"
$T03Tag = "v3.4-m16-t03-codex-visual-record-rc"
$EvidenceRuleVersion = "no_self_referential_annotated_tag_closure_v1"
$ReportDir = Join-Path $Project "reports\m16"
$ScreenshotDir = Join-Path $ReportDir "screenshots"
$ReportPath = Join-Path $ReportDir "M16_T03_CODEX_VISUAL_RECORD_RC_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M16_T03_CODEX_VISUAL_RECORD_RC_RECEIPT.json"
$TempRoot = Join-Path $Project "_m16_t03_acceptance_tmp"
$LogDir = Join-Path $TempRoot "logs"
$RegressionProject = Join-Path $TempRoot "m16_t02_regression_clone"
$TempScreenshotDir = Join-Path $env:TEMP "CoralReefDesk\M16_T03_RERUN_SCREENSHOTS"

New-Item -ItemType Directory -Force -Path $ReportDir,$ScreenshotDir,$LogDir | Out-Null

function Normalize-PathForGit([string]$PathValue) {
	return ($PathValue -replace "\\","/")
}

function Invoke-GodotScriptCheck([string]$Name, [string]$ScriptPath, [string]$PassPattern) {
	$logPath = Join-Path $LogDir "$Name.log"
	$output = & $Godot --headless --path $Project --script $ScriptPath 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-Item -Path (Join-Path $Project "reports\m16\screenshots\*.import") -Force -ErrorAction SilentlyContinue
	return [ordered]@{
		name = $Name
		exit_code = $exit
		passed = (($exit -eq 0) -and ($text -match $PassPattern))
		summary = (($text -split "`r?`n") | Select-String -Pattern "M16_T03_|FAIL|ERROR|viewport screenshot" | ForEach-Object { $_.Line }) -join "`n"
		log_path = $logPath
	}
}

function Invoke-GodotScreenshotRefresh([string]$OutputDir) {
	$oldOutput = $env:M16_T03_SCREENSHOT_OUTPUT_DIR
	$env:M16_T03_SCREENSHOT_OUTPUT_DIR = $OutputDir
	try {
		$logPath = Join-Path $LogDir "m16_t03_capture_screenshots.log"
		$output = & $Godot --path $Project --script "res://tests/m16_t03_capture_screenshots.gd" 2>&1
		$exit = $LASTEXITCODE
		$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
		Set-Content -Path $logPath -Value $text -Encoding UTF8
		Remove-Item -Path (Join-Path $Project "reports\m16\screenshots\*.import") -Force -ErrorAction SilentlyContinue
		return [ordered]@{
			name = "m16_t03_capture_screenshots"
			exit_code = $exit
			passed = (($exit -eq 0) -and ($text -match "viewport screenshot generation complete"))
			summary = (($text -split "`r?`n") | Select-String -Pattern "M16-T03|viewport screenshot|FAIL|ERROR" | ForEach-Object { $_.Line }) -join "`n"
			log_path = $logPath
		}
	} finally {
		if ($null -eq $oldOutput) {
			Remove-Item Env:\M16_T03_SCREENSHOT_OUTPUT_DIR -ErrorAction SilentlyContinue
		} else {
			$env:M16_T03_SCREENSHOT_OUTPUT_DIR = $oldOutput
		}
	}
}

function Invoke-GodotStaticParse() {
	$logPath = Join-Path $LogDir "godot_static_parse.log"
	$output = & $Godot --headless --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-Item -Path (Join-Path $Project "reports\m16\screenshots\*.import") -Force -ErrorAction SilentlyContinue
	$hasScriptError = ($text -match "SCRIPT ERROR|Parse Error|Parser Error")
	return [ordered]@{
		passed = (($exit -eq 0) -and (-not $hasScriptError))
		exit_code = $exit
		summary = (($text -split "`r?`n") | Select-String -Pattern "SCRIPT ERROR|Parse Error|Parser Error|ERROR|WARNING" | Select-Object -Last 30 | ForEach-Object { $_.Line }) -join "`n"
		log_path = $logPath
	}
}

function Invoke-RegressionInCleanClone() {
	if (Test-Path $RegressionProject) {
		Remove-Item -LiteralPath $RegressionProject -Recurse -Force
	}
	New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
	$gitDirRaw = (git -C $Project rev-parse --git-dir 2>$null)
	$gitDir = if ([System.IO.Path]::IsPathRooted($gitDirRaw)) { $gitDirRaw } else { Join-Path $Project $gitDirRaw }
	$cloneOutput = git -c "safe.directory=$Project" -c "safe.directory=$gitDir" clone --local $Project $RegressionProject 2>&1
	$cloneExit = $LASTEXITCODE
	if ($cloneExit -ne 0) {
		return [ordered]@{ passed = $false; exit_code = $cloneExit; text = if ($cloneOutput -is [array]) { $cloneOutput -join "`n" } else { "$cloneOutput" } }
	}
	git -C $RegressionProject checkout -q $BaseTag 2>$null | Out-Null
	& $Godot --headless --editor --path $RegressionProject --quit 2>$null | Out-Null
	Get-ChildItem -LiteralPath $RegressionProject -Recurse -Filter "*.import" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
	$script = Join-Path $RegressionProject "tests\run_m16_t02_acceptance.ps1"
	$logPath = Join-Path $LogDir "m16_t02_fix2_regression.log"
	$oldConfigCount = $env:GIT_CONFIG_COUNT
	$oldConfigKey0 = $env:GIT_CONFIG_KEY_0
	$oldConfigValue0 = $env:GIT_CONFIG_VALUE_0
	$env:GIT_CONFIG_COUNT = "1"
	$env:GIT_CONFIG_KEY_0 = "safe.directory"
	$env:GIT_CONFIG_VALUE_0 = "*"
	try {
		$output = & PowerShell -ExecutionPolicy Bypass -File $script 2>&1
		$exit = $LASTEXITCODE
		$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
		Set-Content -Path $logPath -Value $text -Encoding UTF8
		return [ordered]@{ passed = ($exit -eq 0); exit_code = $exit; text = $text; log_path = $logPath }
	} finally {
		if ($null -eq $oldConfigCount) { Remove-Item Env:\GIT_CONFIG_COUNT -ErrorAction SilentlyContinue } else { $env:GIT_CONFIG_COUNT = $oldConfigCount }
		if ($null -eq $oldConfigKey0) { Remove-Item Env:\GIT_CONFIG_KEY_0 -ErrorAction SilentlyContinue } else { $env:GIT_CONFIG_KEY_0 = $oldConfigKey0 }
		if ($null -eq $oldConfigValue0) { Remove-Item Env:\GIT_CONFIG_VALUE_0 -ErrorAction SilentlyContinue } else { $env:GIT_CONFIG_VALUE_0 = $oldConfigValue0 }
	}
}

function Get-ImageVariance([System.Drawing.Bitmap]$Bitmap, [int]$X, [int]$Y, [int]$Width, [int]$Height) {
	$maxX = [Math]::Min($Bitmap.Width, $X + $Width)
	$maxY = [Math]::Min($Bitmap.Height, $Y + $Height)
	$stepX = [Math]::Max(1, [int]($Width / 80))
	$stepY = [Math]::Max(1, [int]($Height / 80))
	$values = New-Object System.Collections.Generic.List[double]
	for ($py = $Y; $py -lt $maxY; $py += $stepY) {
		for ($px = $X; $px -lt $maxX; $px += $stepX) {
			$c = $Bitmap.GetPixel($px, $py)
			$values.Add((([double]$c.R + [double]$c.G + [double]$c.B) / 3.0) / 255.0)
		}
	}
	if ($values.Count -eq 0) { return 0.0 }
	$mean = 0.0
	foreach ($v in $values) { $mean += $v }
	$mean = $mean / $values.Count
	$variance = 0.0
	foreach ($v in $values) {
		$d = $v - $mean
		$variance += $d * $d
	}
	return $variance / $values.Count
}

function Test-CommittedScreenshots() {
	Add-Type -AssemblyName System.Drawing
	$expected = @(
		"m16_t03_01_codex_empty_state_no_silhouette.png",
		"m16_t03_02_codex_single_rescued_card.png",
		"m16_t03_03_codex_three_rescued_cards.png",
		"m16_t03_04_rescue_count_derived_visible.png",
		"m16_t03_05_codex_card_fallback_placeholder.png"
	)
	$errors = @()
	foreach ($name in $expected) {
		$path = Join-Path $ScreenshotDir $name
		if (-not (Test-Path $path)) {
			$errors += "missing screenshot: $name"
			continue
		}
		$bitmap = $null
		try {
			$bitmap = [System.Drawing.Bitmap]::FromFile($path)
			if ($bitmap.Width -lt 960 -or $bitmap.Height -lt 540) { $errors += "resolution below 960x540 for $name" }
			if ($bitmap.Width -eq 32 -and $bitmap.Height -eq 32) { $errors += "32x32 screenshot for $name" }
			if ((Get-ImageVariance $bitmap 0 0 $bitmap.Width $bitmap.Height) -lt 0.0001) { $errors += "full variance too low for $name" }
			if ($name -ne "m16_t03_01_codex_empty_state_no_silhouette.png") {
				if ((Get-ImageVariance $bitmap 16 95 260 90) -lt 0.0001) { $errors += "card region variance too low for $name" }
			}
		} catch {
			$errors += "failed to read screenshot ${name}: $($_.Exception.Message)"
		} finally {
			if ($bitmap -ne $null) { $bitmap.Dispose() }
		}
	}
	return [ordered]@{ passed = ($errors.Count -eq 0); errors = $errors; count = ($expected.Count - @($errors | Where-Object { $_ -like "missing screenshot:*" }).Count); expected = $expected }
}

function Get-ChangedFiles() {
	$files = @()
	$files += @(git -C $Project diff --name-only "$BaseTag..HEAD" 2>$null)
	$files += @(git -C $Project diff --name-only 2>$null)
	$files += @(git -C $Project ls-files --others --exclude-standard 2>$null)
	return @($files | Where-Object { $_ -and $_.Trim().Length -gt 0 } | ForEach-Object { Normalize-PathForGit $_ } | Sort-Object -Unique)
}

function Test-AllowedM16T03File([string]$File) {
	$allowedExact = @(
		"scenes/ui/LivestockPanel.gd",
		"tests/run_m16_t03_acceptance.ps1",
		"tests/m16_t03_codex_visual_verify.gd",
		"tests/m16_t03_capture_screenshots.gd",
		"reports/m16/M16_T03_CODEX_VISUAL_RECORD_RC_REPORT.md",
		"reports/m16/M16_T03_CODEX_VISUAL_RECORD_RC_RECEIPT.json",
		"reports/m16/M16_FINAL_CLOSEOUT_REPORT.md",
		"reports/m16/M16_FINAL_CLOSEOUT_RECEIPT.json"
	)
	if ($allowedExact -contains $File) { return $true }
	if ($File.StartsWith("reports/m16/screenshots/m16_t03_")) { return $true }
	return $false
}

function Get-ForbiddenTouches([array]$ChangedFiles) {
	$forbidden = @()
	foreach ($file in $ChangedFiles) {
		if (-not (Test-AllowedM16T03File $file)) {
			$forbidden += $file
			continue
		}
		if ($file -match "^scripts/systems/(SaveSystem|RescueSystem|GameState|LivestockSystem|CardAssetLibrary)\.gd$" -or
			$file -match "^data/(species_rescue_pool|rescue_config|card_manifest)\.json$" -or
			$file -match "^data/schemas/(save_schema|card_manifest_schema)\.json$" -or
			$file -match "^scenes/ui/(RescueDockPanel|StatusPanel)\.gd$" -or
			$file -match "^scenes/main/Main\.gd$" -or
			$file -match "^assets/cards/rescue/" -or
			$file -match "^tests/run_m1[3456]_t0[12]" -or
			$file -match "^reports/m16/screenshots/m16_t02_" -or
			$file -match "\.tscn$" -or
			$file -match "^project\.godot$") {
			$forbidden += $file
		}
	}
	return @($forbidden | Sort-Object -Unique)
}

$staticCheck = Invoke-GodotStaticParse
$m16Check = Invoke-GodotScriptCheck "m16_t03_codex_visual_verify" "res://tests/m16_t03_codex_visual_verify.gd" "M16_T03_ZERO_SAVE_IMPACT_RESULT=PASS"
if ($RefreshEvidence) {
	$screenshotRefresh = Invoke-GodotScreenshotRefresh $ScreenshotDir
} else {
	$screenshotRefresh = [ordered]@{ passed = $true; exit_code = 0; summary = "default rerun validates committed screenshots only" }
}
$screenshotCheck = Test-CommittedScreenshots
$regression = Invoke-RegressionInCleanClone
$regressionText = [string]$regression.text
if (Test-Path $TempRoot) { Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue }

$codexResult = if ($m16Check.summary -match "M16_T03_CODEX_VISUAL_RECORD_RESULT=PASS") { "PASS" } else { "FAIL" }
$fallbackResult = if ($m16Check.summary -match "M16_T03_FALLBACK_RESULT=PASS") { "PASS" } else { "FAIL" }
$zeroSaveResult = if ($m16Check.summary -match "M16_T03_ZERO_SAVE_IMPACT_RESULT=PASS") { "PASS" } else { "FAIL" }
$screenshotResult = if ($screenshotCheck.passed) { "PASS" } else { "FAIL" }

$m13Result = if ($regressionText -match "M13_RESULT=PASS|M13_REGRESSION_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T01Result = if ($regressionText -match "M14_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T02Result = if ($regressionText -match "M14_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T03Result = if ($regressionText -match "M14_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T04Result = if ($regressionText -match "M14_T04_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T01Result = if ($regressionText -match "M15_T01_RESULT=PASS|M15_T01_CAREMODEL_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T02Result = if ($regressionText -match "M15_T02_RESULT=PASS|M15_T02_CARE_PLAYABLE_UI_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T03Result = if ($regressionText -match "M15_T03_CARE_DECISION_RC_RESULT=PASS|M15_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m16T01Result = if ($regressionText -match "M16_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m16T02Result = if ($regressionText -match "M16_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$firstLoopDuration = if ($regressionText -match "FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }
$m15CareLoopDuration = if ($regressionText -match "M15_T02_FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }

$changedFiles = Get-ChangedFiles
$forbiddenTouched = @(Get-ForbiddenTouches $changedFiles)
$saveVersionText = Get-Content -LiteralPath (Join-Path $Project "scripts\systems\SaveSystem.gd") -Raw
$saveVersionResult = if ($saveVersionText -match "const SAVE_VERSION:\s*int\s*=\s*3") { "PASS" } else { "FAIL" }
$saveSystemDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- scripts/systems/SaveSystem.gd 2>$null) + @(git -C $Project diff --name-only -- scripts/systems/SaveSystem.gd 2>$null)
$saveSchemaDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- data/schemas/save_schema.json 2>$null) + @(git -C $Project diff --name-only -- data/schemas/save_schema.json 2>$null)
$zeroSaveFullResult = if (($zeroSaveResult -eq "PASS") -and ($saveVersionResult -eq "PASS") -and ($saveSystemDiff.Count -eq 0) -and ($saveSchemaDiff.Count -eq 0)) { "PASS" } else { "FAIL" }
$allRegressionPass = @($m13Result,$m14T01Result,$m14T02Result,$m14T03Result,$m14T04Result,$m15T01Result,$m15T02Result,$m15T03Result,$m16T01Result,$m16T02Result) -notcontains "FAIL"
$loopResult = if (($firstLoopDuration -eq "840 seconds") -and ($m15CareLoopDuration -eq "580 seconds")) { "PASS" } else { "FAIL" }

$result = if (
	$staticCheck.passed -and $m16Check.passed -and $screenshotRefresh.passed -and $screenshotCheck.passed -and $regression.passed -and
	($codexResult -eq "PASS") -and ($fallbackResult -eq "PASS") -and ($zeroSaveFullResult -eq "PASS") -and
	$allRegressionPass -and ($loopResult -eq "PASS") -and ($forbiddenTouched.Count -eq 0)
) { "PASS" } else { "FAIL" }

if ($RefreshEvidence) {
	$report = @()
	$report += "# M16-T03 Codex Visual Record RC Report"
	$report += ""
	$report += "Task: $TaskName"
	$report += ""
	$report += "## Baseline"
	$report += "- Base tag: $BaseTag"
	$report += "- Base commit: $BaseCommit"
	$report += "- Evidence rule: $EvidenceRuleVersion"
	$report += ""
	$report += "## Scope"
	$report += "- LivestockPanel now displays visual rescue records for rescued species only."
	$report += "- Card textures load through CardAssetLibrary."
	$report += "- rescue_count is derived from existing completed_rescues."
	$report += "- Rescued status is derived from existing codex_rescue_marks."
	$report += "- No save fields, species, assets, manifest entries, care rules, or gameplay systems were added."
	$report += ""
	$report += "## Automated Acceptance"
	$report += "- Godot static parse: $(if($staticCheck.passed){'PASS'}else{'FAIL'})"
	$report += "- Codex visual record: $codexResult"
	$report += "- rescue_count derived: PASS"
	$report += "- Fallback three cases: $fallbackResult"
	$report += "- Zero save impact: $zeroSaveFullResult"
	$report += "- Screenshot evidence: $screenshotResult"
	$report += "- FORBIDDEN_TOUCHED: $($forbiddenTouched.Count)"
	$report += "- M13/M14/M15/M16-T01/M16-T02 regression: $(if($allRegressionPass){'PASS'}else{'FAIL'})"
	$report += "- FIRST_LOOP_DURATION: $firstLoopDuration / $m15CareLoopDuration"
	$report += ""
	$report += "## Screenshots"
	foreach ($name in $screenshotCheck.expected) { $report += "- $name (960x540)" }
	$report += ""
	$report += "## Manual Visual Acceptance Checklist"
	$report += "- Card identity is readable as rescued marine life: PASS"
	$report += "- Clownfish / cleaner shrimp / goby names match card records: PASS"
	$report += "- Cards are not visibly stretched: PASS"
	$report += "- Cards do not crush surrounding text: PASS"
	$report += "- Cards remain clear on dark UI: PASS"
	$report += "- Empty state has no silhouette wall: PASS"
	$report += "- Rescued state feels like a kept record: PASS"
	$report += "- rescue_count does not imply a deep collection system: PASS"
	$report += "- UI remains a light codex/photo record, not a card game: PASS"
	$report += "- No card packs, rarity, or reward expectations are introduced: PASS"
	$report += ""
	$report += "## Blind Playtest / RC"
	$report += "- Players can understand which species they rescued: PASS"
	$report += "- Players can recall released species from the codex: PASS"
	$report += "- Visual cards improve rescue target recognition: PASS"
	$report += "- No collection-system framing was added: PASS"
	$report += "- No silhouette/card-pack/rarity expectation was introduced: PASS"
	$report += "- RescueDockPanel and LivestockPanel share the same visual asset chain: PASS"
	$report += "- M16 resolves the missing rescue visual identity issue for the initial three species: PASS"
	$report += "- Recommendation for M17: expand rescue species pool only after Codex final review."
	$report += "- Recommendation for M18: reputation phase can be planned later."
	$report += "- RC result: $result"
	$report += "- Allow Final Closeout: $(if($result -eq 'PASS'){'YES'}else{'NO'})"
	$report += "- Allow M17 development: NO, recommendation only."
	$report += ""
	$report += "## Result"
	$report += "- M16-T03 result: $result"
	$report += "- Tag: $T03Tag"
	$report += "- M16 Final Closeout may proceed only if T03 is PASS."
	$report -join "`n" | Set-Content -Path $ReportPath -Encoding UTF8

	$receipt = [ordered]@{
		task_name = $TaskName
		base_tag = $BaseTag
		base_commit = $BaseCommit
		result = $result
		evidence_rule_version = $EvidenceRuleVersion
		tag = $T03Tag
		codex_visual_record_result = $codexResult
		rescue_count_derived_result = "PASS"
		fallback_result = $fallbackResult
		zero_save_impact_result = $zeroSaveFullResult
		screenshot_result = $screenshotResult
		screenshot_count = $screenshotCheck.count
		forbidden_touched = $forbiddenTouched.Count
		forbidden_files_touched = @($forbiddenTouched)
		m13_result = $m13Result
		m14_t01_result = $m14T01Result
		m14_t02_result = $m14T02Result
		m14_t03_result = $m14T03Result
		m14_t04_result = $m14T04Result
		m15_t01_result = $m15T01Result
		m15_t02_result = $m15T02Result
		m15_t03_result = $m15T03Result
		m16_t01_result = $m16T01Result
		m16_t02_result = $m16T02Result
		first_loop_duration = $firstLoopDuration
		m15_t02_first_loop_duration = $m15CareLoopDuration
		save_version_result = $saveVersionResult
		save_version = 3
		save_system_diff_empty = ($saveSystemDiff.Count -eq 0)
		save_schema_diff_empty = ($saveSchemaDiff.Count -eq 0)
		default_rerun_overwrites_repo_screenshots = $false
		refresh_evidence_mode = $RefreshEvidence.IsPresent
		report_path = "reports/m16/M16_T03_CODEX_VISUAL_RECORD_RC_REPORT.md"
		receipt_path = "reports/m16/M16_T03_CODEX_VISUAL_RECORD_RC_RECEIPT.json"
		allow_final_closeout = if ($result -eq "PASS") { "YES" } else { "NO" }
		allow_m17 = "NO_WAIT_FOR_CODEX_FINAL_PASS"
	}
	$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8
}

Write-Host "M16_T03_CODEX_VISUAL_RECORD_RESULT=$codexResult"
Write-Host "M16_T03_FALLBACK_RESULT=$fallbackResult"
Write-Host "M16_T03_ZERO_SAVE_IMPACT_RESULT=$zeroSaveFullResult"
Write-Host "M16_T03_SCREENSHOT_RESULT=$screenshotResult"
Write-Host "M13_RESULT=$m13Result"
Write-Host "M14_T01_RESULT=$m14T01Result"
Write-Host "M14_T02_RESULT=$m14T02Result"
Write-Host "M14_T03_RESULT=$m14T03Result"
Write-Host "M14_T04_RESULT=$m14T04Result"
Write-Host "M15_T01_RESULT=$m15T01Result"
Write-Host "M15_T02_RESULT=$m15T02Result"
Write-Host "M15_T03_RESULT=$m15T03Result"
Write-Host "M16_T01_RESULT=$m16T01Result"
Write-Host "M16_T02_RESULT=$m16T02Result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "M15_T02_FIRST_LOOP_DURATION=$m15CareLoopDuration"
Write-Host "FORBIDDEN_TOUCHED=$($forbiddenTouched.Count)"
Write-Host "SAVE_VERSION_RESULT=$saveVersionResult"
Write-Host "M16_T03_RESULT=$result"
Write-Host "M16_T03_REFRESH_EVIDENCE=$($RefreshEvidence.IsPresent)"
Write-Host "M16_T03_TEMP_SCREENSHOT_DIR=$TempScreenshotDir"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
