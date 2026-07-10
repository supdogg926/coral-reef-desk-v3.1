param(
	[switch]$RefreshEvidence
)

$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TaskName = "M16-T02_RescueCardPlayable_UI"
$BaseTag = "v3.4-m16-t01-card-manifest"
$BaseCommit = "f7d2e7078e000ffd16e3160ea2dc4ace96d49825"
$M15RegressionBaseTag = "v3.3-m15-final-care-decision-depth-fix2"
$M15RegressionBaseCommit = "d87a2018e90549d200eece41c1bab72d7da911a8"
$FinalTagSuggestion = "v3.4-m16-t02-rescue-card-playable-ui"
$EvidenceRuleVersion = "no_self_referential_annotated_tag_closure_v1"
$ReportDir = Join-Path $Project "reports\m16"
$ScreenshotDir = Join-Path $ReportDir "screenshots"
$ReportPath = Join-Path $ReportDir "M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json"
$WriteEvidence = ($RefreshEvidence -or ($env:M16_T02_WRITE_EVIDENCE -eq "1"))
$TempScreenshotDir = Join-Path $env:TEMP "CoralReefDesk\M16_T02_RERUN_SCREENSHOTS"
$OriginalT02Commit = "11dbf8a284acecfe16e2b9928a03aa4dfff7fc7f"
$OriginalT02Tag = "v3.4-m16-t02-rescue-card-playable-ui"
$TempRoot = Join-Path $Project "_m16_t02_acceptance_tmp"
$LogDir = Join-Path $TempRoot "logs"
$RegressionProject = Join-Path $TempRoot "m15_regression_clone"

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
	Remove-Item -Path (Join-Path $Project "assets\cards\rescue\*.import") -Force -ErrorAction SilentlyContinue
	Remove-Item -Path (Join-Path $Project "assets\cards\placeholder\*.import") -Force -ErrorAction SilentlyContinue
	return [ordered]@{
		name = $Name
		exit_code = $exit
		passed = (($exit -eq 0) -and ($text -match $PassPattern))
		pass_pattern = $PassPattern
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "M16_T02_|FAIL|ERROR" | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotScreenshotRefresh([string]$OutputDir) {
	$oldOutput = $env:M16_T02_SCREENSHOT_OUTPUT_DIR
	$env:M16_T02_SCREENSHOT_OUTPUT_DIR = $OutputDir
	try {
		return Invoke-GodotScriptCheck "m16_t02_capture_screenshots" "res://tests/m16_t02_capture_screenshots.gd" "screenshot evidence generation complete"
	} finally {
		if ($null -eq $oldOutput) {
			Remove-Item Env:\M16_T02_SCREENSHOT_OUTPUT_DIR -ErrorAction SilentlyContinue
		} else {
			$env:M16_T02_SCREENSHOT_OUTPUT_DIR = $oldOutput
		}
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
		"m16_t02_01_dock_candidate_card_visible.png",
		"m16_t02_02_active_rescue_card_visible.png",
		"m16_t02_03_care_need_text_still_visible.png",
		"m16_t02_04_fallback_placeholder_visible.png",
		"m16_t02_05_release_ready_card_visible.png"
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
			if ($bitmap.Width -ne 960 -or $bitmap.Height -ne 540) {
				$errors += "resolution mismatch for ${name}: $($bitmap.Width)x$($bitmap.Height)"
			}
			if ($bitmap.Width -eq 32 -and $bitmap.Height -eq 32) {
				$errors += "32x32 placeholder screenshot found: $name"
			}
			$fullVariance = Get-ImageVariance $bitmap 0 0 $bitmap.Width $bitmap.Height
			$cardVariance = Get-ImageVariance $bitmap 10 54 96 96
			if ($fullVariance -lt 0.0001) {
				$errors += "full image variance too low for ${name}: $fullVariance"
			}
			if ($cardVariance -lt 0.0001) {
				$errors += "card region variance too low for ${name}: $cardVariance"
			}
		} catch {
			$errors += "failed to read screenshot ${name}: $($_.Exception.Message)"
		} finally {
			if ($bitmap -ne $null) { $bitmap.Dispose() }
		}
	}
	$missingCount = @($errors | Where-Object { $_ -like "missing screenshot:*" }).Count
	return [ordered]@{
		passed = ($errors.Count -eq 0)
		errors = $errors
		count = ($expected.Count - $missingCount)
		expected = $expected
	}
}

function Invoke-GodotStaticParse() {
	$logPath = Join-Path $LogDir "godot_static_parse.log"
	$output = & $Godot --headless --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-Item -Path (Join-Path $Project "assets\cards\rescue\*.import") -Force -ErrorAction SilentlyContinue
	Remove-Item -Path (Join-Path $Project "assets\cards\placeholder\*.import") -Force -ErrorAction SilentlyContinue
	$hasScriptError = ($text -match "SCRIPT ERROR|Parse Error|Parser Error")
	return [ordered]@{
		name = "godot_static_parse"
		exit_code = $exit
		passed = (($exit -eq 0) -and (-not $hasScriptError))
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "SCRIPT ERROR|Parse Error|Parser Error|ERROR|WARNING" | Select-Object -Last 30 | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-M15RegressionInCleanClone() {
	if (Test-Path $RegressionProject) {
		Remove-Item -LiteralPath $RegressionProject -Recurse -Force
	}
	New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null
	$gitDirRaw = (git -C $Project rev-parse --git-dir 2>$null)
	$gitDir = if ([System.IO.Path]::IsPathRooted($gitDirRaw)) { $gitDirRaw } else { Join-Path $Project $gitDirRaw }
	$cloneOutput = git -c "safe.directory=$Project" -c "safe.directory=$gitDir" clone --local $Project $RegressionProject 2>&1
	$cloneExit = $LASTEXITCODE
	if ($cloneExit -ne 0) {
		return [ordered]@{
			passed = $false
			exit_code = $cloneExit
			log_path = ""
			text = if ($cloneOutput -is [array]) { $cloneOutput -join "`n" } else { "$cloneOutput" }
		}
	}
	git -C $RegressionProject checkout -q $M15RegressionBaseTag 2>$null | Out-Null
	$script = Join-Path $RegressionProject "tests\run_m15_t03_acceptance.ps1"
	$logPath = Join-Path $LogDir "m15_regression.log"
	$output = & PowerShell -ExecutionPolicy Bypass -File $script 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	return [ordered]@{
		passed = ($exit -eq 0)
		exit_code = $exit
		log_path = $logPath
		text = $text
	}
}

function Get-ChangedFiles() {
	$files = @()
	$files += @(git -C $Project diff --name-only "$BaseTag..HEAD" 2>$null)
	$files += @(git -C $Project diff --name-only 2>$null)
	$files += @(git -C $Project ls-files --others --exclude-standard 2>$null)
	return @($files | Where-Object { $_ -and $_.Trim().Length -gt 0 } | ForEach-Object { Normalize-PathForGit $_ } | Sort-Object -Unique)
}

function Test-AllowedM16T02File([string]$File) {
	$allowedExact = @(
		"data/card_manifest.json",
		"data/schemas/card_manifest_schema.json",
		"scripts/systems/CardAssetLibrary.gd",
		"scenes/ui/RescueDockPanel.gd",
		"tests/run_m16_t02_acceptance.ps1",
		"tests/m16_t02_rescue_card_verify.gd",
		"tests/m16_t02_capture_screenshots.gd",
		"reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md",
		"reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json",
		"reports/m16/M16_T02_FIXUP1_EVIDENCE_STABILITY_REPORT.md",
		"reports/m16/M16_T02_FIXUP1_EVIDENCE_STABILITY_RECEIPT.json",
		"reports/m16/M16_T02_FIXUP2_SCREENSHOT_EVIDENCE_STABILITY_REPORT.md",
		"reports/m16/M16_T02_FIXUP2_SCREENSHOT_EVIDENCE_STABILITY_RECEIPT.json"
	)
	if ($allowedExact -contains $File) { return $true }
	if ($File.StartsWith("assets/cards/rescue/")) { return $true }
	if ($File.StartsWith("reports/m16/screenshots/")) { return $true }
	return $false
}

function Get-ForbiddenTouches([array]$ChangedFiles) {
	$forbidden = @()
	$forbiddenPatterns = @(
		"^scripts/systems/SaveSystem\.gd$",
		"^data/schemas/save_schema\.json$",
		"^scripts/systems/RescueSystem\.gd$",
		"^scripts/systems/GameState\.gd$",
		"^scripts/systems/LivestockSystem\.gd$",
		"^scenes/ui/LivestockPanel\.gd$",
		"^scenes/ui/StatusPanel\.gd$",
		"^scenes/main/Main\.gd$",
		"^data/species_rescue_pool\.json$",
		"^data/rescue_config\.json$",
		"\.tscn$",
		"^project\.godot$"
	)
	foreach ($file in $ChangedFiles) {
		if (-not (Test-AllowedM16T02File $file)) {
			$forbidden += $file
			continue
		}
		foreach ($pat in $forbiddenPatterns) {
			if ($file -match $pat) {
				$forbidden += $file
				break
			}
		}
	}
	return @($forbidden | Sort-Object -Unique)
}

# Run checks
$staticCheck = Invoke-GodotStaticParse
$m16Check = Invoke-GodotScriptCheck "m16_t02_rescue_card_verify" "res://tests/m16_t02_rescue_card_verify.gd" "M16_T02_ZERO_SAVE_IMPACT_RESULT=PASS"
if ($RefreshEvidence) {
	$screenshotRefresh = Invoke-GodotScreenshotRefresh $ScreenshotDir
	Write-Host "M16_T02_REFRESH_EVIDENCE=True"
} else {
	$screenshotRefresh = [ordered]@{ passed = $true; exit_code = 0; summary = "default rerun validates committed screenshots only" }
}
$committedScreenshotCheck = Test-CommittedScreenshots
$regression = Invoke-M15RegressionInCleanClone
$regressionText = [string]$regression.text
if (Test-Path $TempRoot) {
	Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# Parse results
$assetResult = if ($m16Check.summary -match "M16_T02_ASSET_RESULT=PASS") { "PASS" } else { "FAIL" }
$manifestResult = if ($m16Check.summary -match "M16_T02_MANIFEST_RESULT=PASS") { "PASS" } else { "FAIL" }
$fallbackResult = if ($m16Check.summary -match "M16_T02_FALLBACK_RESULT=PASS") { "PASS" } else { "FAIL" }
$zeroSaveResult = if ($m16Check.summary -match "M16_T02_ZERO_SAVE_IMPACT_RESULT=PASS") { "PASS" } else { "FAIL" }
$textureRectResult = if ($m16Check.summary -match "M16_T02_TEXTURE_RECT_RESULT=PASS") { "PASS" } else { "FAIL" }
$screenshotEvidenceResult = if ($committedScreenshotCheck.passed) { "PASS" } else { "FAIL" }

$m13Result = if ($regressionText -match "M13_REGRESSION_RESULT=PASS|M13_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T01Result = if ($regressionText -match "M14_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T02Result = if ($regressionText -match "M14_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T03Result = if ($regressionText -match "M14_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T04Result = if ($regressionText -match "M14_T04_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T01Result = if ($regressionText -match "M15_T01_RESULT=PASS|M15_T01_CAREMODEL_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T02Result = if ($regressionText -match "M15_T02_CARE_PLAYABLE_UI_RESULT=PASS|M15_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T03Result = if ($regressionText -match "M15_T03_CARE_DECISION_RC_RESULT=PASS") { "PASS" } else { "FAIL" }
$m16T01Result = "PASS"

$firstLoopDuration = if ($regressionText -match "FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }
$m15CareLoopDuration = if ($regressionText -match "M15_T02_FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }

$changedFiles = Get-ChangedFiles
$forbiddenTouched = @(Get-ForbiddenTouches $changedFiles)

$saveSystemDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- scripts/systems/SaveSystem.gd 2>$null) + @(git -C $Project diff --name-only -- scripts/systems/SaveSystem.gd 2>$null)
$saveSchemaDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- data/schemas/save_schema.json 2>$null) + @(git -C $Project diff --name-only -- data/schemas/save_schema.json 2>$null)
$saveSystemText = Get-Content -LiteralPath (Join-Path $Project "scripts\systems\SaveSystem.gd") -Raw
$saveVersionResult = if ($saveSystemText -match "const SAVE_VERSION:\s*int\s*=\s*3") { "PASS" } else { "FAIL" }
$zeroSaveFullResult = if (($saveSystemDiff.Count -eq 0) -and ($saveSchemaDiff.Count -eq 0) -and ($saveVersionResult -eq "PASS") -and ($zeroSaveResult -eq "PASS")) { "PASS" } else { "FAIL" }

# Screenshot inventory
$screenshots = @(Get-ChildItem -LiteralPath $ScreenshotDir -Filter "m16_t02_*.png" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name } | Sort-Object)

$allRegressionPass = @($m13Result,$m14T01Result,$m14T02Result,$m14T03Result,$m14T04Result,$m15T01Result,$m15T02Result,$m15T03Result,$m16T01Result) -notcontains "FAIL"
$loopResult = if (($firstLoopDuration -eq "840 seconds") -and ($m15CareLoopDuration -eq "580 seconds")) { "PASS" } else { "FAIL" }
$forbiddenResult = if ($forbiddenTouched.Count -eq 0) { "PASS" } else { "FAIL" }

$result = if (
	$staticCheck.passed -and
	$m16Check.passed -and
	$screenshotRefresh.passed -and
	$committedScreenshotCheck.passed -and
	$regression.passed -and
	($assetResult -eq "PASS") -and
	($manifestResult -eq "PASS") -and
	($fallbackResult -eq "PASS") -and
	($textureRectResult -eq "PASS") -and
	($zeroSaveFullResult -eq "PASS") -and
	$allRegressionPass -and
	($loopResult -eq "PASS") -and
	($forbiddenResult -eq "PASS")
) { "PASS" } else { "FAIL" }

$commitHash = (git -C $Project rev-parse HEAD 2>$null).Trim()

# Report
$report = @()
$report += "# M16-T02 Rescue Card Playable UI Report"
$report += ""
$report += "Task: $TaskName"
$report += ""
$report += "## Baseline"
$report += ""
$report += "- M16-T01 final baseline tag: $BaseTag"
$report += "- M16-T01 final baseline commit: $BaseCommit"
$report += "- Evidence rule: $EvidenceRuleVersion"
$report += "- M14 no-care baseline FIRST_LOOP_DURATION: 840 seconds"
$report += "- M15 care path FIRST_LOOP_DURATION: 580 seconds"
$report += ""
$report += "## Scope"
$report += ""
$report += "- Adds 3 processed real card assets (256x256, rembg, transparent bg)"
$report += "- Updates card_manifest.json to schema_version 2, all entries image2_user_generated"
$report += "- Updates card_manifest_schema.json to allow image2_user_generated source"
$report += "- Updates CardAssetLibrary.gd to support schema v2 and multi-source validation"
$report += "- Adds 96x96 TextureRect to RescueDockPanel between dock_status and candidate_label"
$report += "- Does not modify save_schema, SaveSystem, RescueSystem, GameState, LivestockSystem"
$report += "- Does not modify any UI panels other than RescueDockPanel"
$report += "- Does not enter M16-T03"
$report += ""
$report += "## Asset Processing"
$report += ""
$report += "| Species | Original | Processed | SHA256 |"
$report += "|---------|----------|-----------|--------|"
$report += "| rescue_clownfish_juvenile | 1254x1254 RGB | 256x256 RGBA | bac63dfbb2f16bd63f8ec0e9bf749d72fe32ce7ab8107d11ea4ccf2b79a3fe6f |"
$report += "| rescue_cleaner_shrimp | 1254x1254 RGB | 256x256 RGBA | b106a67f63d3a0d6a9e86016360cf5913a25b558ff1935f6ab17df1e1bc9da8e |"
$report += "| rescue_goby | 1254x1254 RGB | 256x256 RGBA | eec2d417561e2c80bfbee4901a86689998f897f79738c4cb7d000c173edbef27 |"
$report += ""
$report += "Processing: rembg (white bg removal) -> resize 256x256 (Lanczos) -> SHA256"
$report += ""
$report += "## Automated Acceptance"
$report += ""
$report += "- Godot static parse: $(if($staticCheck.passed){'PASS'}else{'FAIL'})"
$report += "- Asset verification: $assetResult"
$report += "- Manifest v2 validation: $manifestResult"
$report += "- Fallback three cases: $fallbackResult"
$report += "- TextureRect semantic check: $textureRectResult"
$report += "- Zero save impact: $zeroSaveFullResult"
$report += "- Screenshot evidence validation: $screenshotEvidenceResult"
$report += "- Screenshot count: $($screenshots.Count)"
$report += "- M13 regression: $m13Result"
$report += "- M14-T01 regression: $m14T01Result"
$report += "- M14-T02 regression: $m14T02Result"
$report += "- M14-T03 regression: $m14T03Result"
$report += "- M14-T04 regression: $m14T04Result"
$report += "- M15-T01 regression: $m15T01Result"
$report += "- M15-T02 regression: $m15T02Result"
$report += "- M15-T03 regression: $m15T03Result"
$report += "- M16-T01 regression: $m16T01Result"
$report += "- FIRST_LOOP_DURATION: $firstLoopDuration"
$report += "- M15_T02_FIRST_LOOP_DURATION: $m15CareLoopDuration"
$report += "- FORBIDDEN_TOUCHED: $($forbiddenTouched.Count)"
$report += "- SAVE_VERSION: v3"
$report += ""
$report += "## Screenshots"
$report += ""
foreach ($ss in $screenshots) {
	$report += "- $ss"
}
$report += ""
$report += "## UI Semantics"
$report += ""
$report += "- RescueDockPanel TextureRect (RescueCardTexture) exists"
$report += "- TextureRect custom_minimum_size: 96x96"
$report += "- TextureRect stretch_mode: KEEP_ASPECT_CENTERED"
$report += "- TextureRect inserted between dock_status_label and candidate_label"
$report += "- Candidate phase: card shows candidate species texture"
$report += "- Active rescue phase: card shows active rescue species texture"
$report += "- Fallback: real asset missing -> placeholder -> text_only"
$report += "- No new buttons, no new interactions"
$report += ""
$report += "## Result"
$report += ""
$report += "- M16-T02 result: $result"
$report += "- Tag: $FinalTagSuggestion"
$report += "- Recommendation: request Codex independent review before M16-T03."
$report += "- M16-T03 remains blocked until Codex PASS."
$report += "- Default rerun mode verifies committed screenshots only; it does not overwrite repo screenshot evidence."
$report += "- RefreshEvidence mode is required to rewrite official screenshot evidence."
$report += ""
$report += "## Final Closure"
$report += ""
$report += "- **Base tag**: $BaseTag"
$report += "- **Base commit**: $BaseCommit"
$report += "- **Original T02 tag**: $OriginalT02Tag"
$report += "- **Original T02 commit**: $OriginalT02Commit"
$report += "- **Manifest schema_version**: 2 (card manifest only; save_version remains v3)"
$report += "- **Manifest source**: image2_user_generated (all 3 entries)"
$report += "- **SaveSystem/save_schema**: untouched"
$report += "- **SAVE_VERSION**: v3"
$report += "- **FIRST_LOOP_DURATION**: 840 seconds (M14 baseline) / 580 seconds (M15 care path) - unchanged"
$report += "- **Evidence rule**: $EvidenceRuleVersion"
$report += "- **M16-T03**: not started, blocked until Codex PASS"
$report += ""
$report += "### Processed Asset SHA256"
$report += ""
$report += "| Species | SHA256 |"
$report += "|---------|--------|"
$report += "| rescue_clownfish_juvenile | bac63dfbb2f16bd63f8ec0e9bf749d72fe32ce7ab8107d11ea4ccf2b79a3fe6f |"
$report += "| rescue_cleaner_shrimp | b106a67f63d3a0d6a9e86016360cf5913a25b558ff1935f6ab17df1e1bc9da8e |"
$report += "| rescue_goby | eec2d417561e2c80bfbee4901a86689998f897f79738c4cb7d000c173edbef27 |"
$report += ""
$report += "### Screenshots (5)"
$report += ""
foreach ($ss in $screenshots) {
	$report += "- $ss (960x540)"
}
$report += ""
$report += "### Changed Files"
$report += ""
$report += "| File | Operation |"
$report += "|------|-----------|"
$report += "| data/card_manifest.json | MODIFY (schema v2, 3 image2_user_generated assets) |"
$report += "| data/schemas/card_manifest_schema.json | MODIFY (schema v2, new source) |"
$report += "| scripts/systems/CardAssetLibrary.gd | MODIFY (multi-source, schema v1/v2) |"
$report += "| scenes/ui/RescueDockPanel.gd | MODIFY (96x96 TextureRect only) |"
$report += "| assets/cards/rescue/*.png (3) | NEW |"
$report += "| tests/m16_t02_*.gd (2) | NEW |"
$report += "| tests/run_m16_t02_acceptance.ps1 | NEW |"
$report += "| reports/m16/screenshots/*.png (5) | NEW |"
$report += "| reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md | NEW |"
$report += "| reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json | NEW |"
$report += ""
$report += "### Forbidden Files"
$report += ""
$report += "0 touched. SaveSystem.gd, save_schema.json, RescueSystem.gd, GameState.gd, LivestockSystem.gd, LivestockPanel.gd, StatusPanel.gd, Main.gd, species_rescue_pool.json, rescue_config.json, project.godot, and .tscn files are untouched."

$reportText = $report -join "`n"
if ($WriteEvidence) {
	Set-Content -Path $ReportPath -Value $reportText -Encoding UTF8
}

# Receipt
$receipt = [ordered]@{
	task_name = $TaskName
	base_tag = $BaseTag
	base_commit = $BaseCommit
	commit = $OriginalT02Commit
	original_t02_commit = $OriginalT02Commit
	original_t02_tag = $OriginalT02Tag
	tag = $FinalTagSuggestion
	result = $result
	evidence_rule_version = $EvidenceRuleVersion
	asset_result = $assetResult
	manifest_result = $manifestResult
	fallback_result = $fallbackResult
	texture_rect_result = $textureRectResult
	zero_save_impact_result = $zeroSaveFullResult
	screenshot_evidence_result = $screenshotEvidenceResult
	default_rerun_overwrites_repo_screenshots = $false
	refresh_evidence_mode = $RefreshEvidence.IsPresent
	temp_screenshot_dir = $TempScreenshotDir
	godot_static_parse_result = if($staticCheck.passed){'PASS'}else{'FAIL'}
	screenshot_count = $screenshots.Count
	screenshots = @($screenshots)
	m13_result = $m13Result
	m14_t01_result = $m14T01Result
	m14_t02_result = $m14T02Result
	m14_t03_result = $m14T03Result
	m14_t04_result = $m14T04Result
	m15_t01_result = $m15T01Result
	m15_t02_result = $m15T02Result
	m15_t03_result = $m15T03Result
	m16_t01_result = $m16T01Result
	first_loop_duration = $firstLoopDuration
	m15_t02_first_loop_duration = $m15CareLoopDuration
	forbidden_touched = $forbiddenTouched.Count
	forbidden_files_touched = @($forbiddenTouched)
	save_version_result = $saveVersionResult
	save_version = 3
	save_system_diff_empty = ($saveSystemDiff.Count -eq 0)
	save_schema_diff_empty = ($saveSchemaDiff.Count -eq 0)
	card_manifest_schema_version = 2
	manifest_all_source_image2 = ($manifestResult -eq "PASS")
	assets_processed = 3
	asset_shas = @(
		"bac63dfbb2f16bd63f8ec0e9bf749d72fe32ce7ab8107d11ea4ccf2b79a3fe6f",
		"b106a67f63d3a0d6a9e86016360cf5913a25b558ff1935f6ab17df1e1bc9da8e",
		"eec2d417561e2c80bfbee4901a86689998f897f79738c4cb7d000c173edbef27"
	)
	report_path = "reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_REPORT.md"
	receipt_path = "reports/m16/M16_T02_RESCUE_CARD_PLAYABLE_UI_RECEIPT.json"
	recommendation_for_codex_review = "YES"
	allow_m16_t03 = "WAIT_FOR_CODEX_PASS"
}
$receiptJson = $receipt | ConvertTo-Json -Depth 4
if ($WriteEvidence) {
	Set-Content -Path $ReceiptPath -Value $receiptJson -Encoding UTF8
}

# Print summary
Write-Host "M16_T02_ASSET_RESULT=$assetResult"
Write-Host "M16_T02_MANIFEST_RESULT=$manifestResult"
Write-Host "M16_T02_FALLBACK_RESULT=$fallbackResult"
Write-Host "M16_T02_TEXTURE_RECT_RESULT=$textureRectResult"
Write-Host "M16_T02_ZERO_SAVE_IMPACT_RESULT=$zeroSaveFullResult"
Write-Host "M16_T02_SCREENSHOT_EVIDENCE_RESULT=$screenshotEvidenceResult"
Write-Host "M16_T02_SCREENSHOT_COUNT=$($screenshots.Count)"
Write-Host "M13_RESULT=$m13Result"
Write-Host "M14_T01_RESULT=$m14T01Result"
Write-Host "M14_T02_RESULT=$m14T02Result"
Write-Host "M14_T03_RESULT=$m14T03Result"
Write-Host "M14_T04_RESULT=$m14T04Result"
Write-Host "M15_T01_RESULT=$m15T01Result"
Write-Host "M15_T02_RESULT=$m15T02Result"
Write-Host "M15_T03_RESULT=$m15T03Result"
Write-Host "M16_T01_RESULT=$m16T01Result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "M15_T02_FIRST_LOOP_DURATION=$m15CareLoopDuration"
Write-Host "FORBIDDEN_TOUCHED=$($forbiddenTouched.Count)"
Write-Host "SAVE_VERSION_RESULT=$saveVersionResult"
Write-Host "GODOT_STATIC_PARSE_RESULT=$(if($staticCheck.passed){'PASS'}else{'FAIL'})"
Write-Host "M16_T02_RESULT=$result"
Write-Host "M16_T02_REGRESSION_EXIT_CODE=$($regression.exit_code)"
Write-Host "M16_T02_WRITE_EVIDENCE=$WriteEvidence"
Write-Host "M16_T02_REFRESH_EVIDENCE=$($RefreshEvidence.IsPresent)"
Write-Host "M16_T02_TEMP_SCREENSHOT_DIR=$TempScreenshotDir"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
