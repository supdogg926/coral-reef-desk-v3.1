$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TaskName = "M16-T01_VisualCardManifest_And_PlaceholderPipeline"
$BaseTag = "v3.3-m15-final-care-decision-depth-fix2"
$BaseCommit = "d87a2018e90549d200eece41c1bab72d7da911a8"
$FinalTag = "v3.4-m16-t01-card-manifest"
$EvidenceRuleVersion = "no_self_referential_annotated_tag_closure_v1"
$ReportDir = Join-Path $Project "reports\m16"
$ReportPath = Join-Path $ReportDir "M16_T01_CARD_MANIFEST_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M16_T01_CARD_MANIFEST_RECEIPT.json"
$TempRoot = Join-Path $Project "_m16_t01_acceptance_tmp"
$LogDir = Join-Path $TempRoot "logs"
$RegressionProject = Join-Path $TempRoot "m15_regression_clone"

New-Item -ItemType Directory -Force -Path $ReportDir,$LogDir | Out-Null

function Normalize-PathForGit([string]$PathValue) {
	return ($PathValue -replace "\\","/")
}

function Invoke-GodotScriptCheck([string]$Name, [string]$ScriptPath, [string]$PassPattern) {
	$logPath = Join-Path $LogDir "$Name.log"
	$output = & $Godot --headless --path $Project --script $ScriptPath 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-Item -Path (Join-Path $Project "assets\cards\placeholder\*.import") -Force -ErrorAction SilentlyContinue
	return [ordered]@{
		name = $Name
		exit_code = $exit
		passed = (($exit -eq 0) -and ($text -match $PassPattern))
		pass_pattern = $PassPattern
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "M16_T01_|FAIL|ERROR" | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotStaticParse() {
	$logPath = Join-Path $LogDir "godot_static_parse.log"
	$output = & $Godot --headless --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
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
	git -C $RegressionProject checkout -q $BaseTag 2>$null | Out-Null
	$script = Join-Path $RegressionProject "tests\run_m15_t03_acceptance.ps1"
	$logPath = Join-Path $LogDir "m15_fix2_regression.log"
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

function Test-AllowedM16T01File([string]$File) {
	$allowedExact = @(
		"data/card_manifest.json",
		"data/schemas/card_manifest_schema.json",
		"scripts/systems/CardAssetLibrary.gd",
		"tests/run_m16_t01_acceptance.ps1",
		"reports/m16/M16_T01_CARD_MANIFEST_REPORT.md",
		"reports/m16/M16_T01_CARD_MANIFEST_RECEIPT.json"
	)
	if ($allowedExact -contains $File) { return $true }
	if ($File.StartsWith("assets/cards/placeholder/")) { return $true }
	if ($File.StartsWith("tests/m16_t01_") -and $File.EndsWith(".gd")) { return $true }
	return $false
}

function Get-ForbiddenTouches([array]$ChangedFiles) {
	$forbidden = @()
	foreach ($file in $ChangedFiles) {
		if (-not (Test-AllowedM16T01File $file)) {
			$forbidden += $file
			continue
		}
		if ($file -match "^scripts/systems/(SaveSystem|RescueSystem|GameState|LivestockSystem)\.gd$" -or
			$file -match "^data/schemas/save_schema\.json$" -or
			$file -match "^scenes/ui/" -or
			$file -match "^data/species_rescue_pool\.json$" -or
			$file -match "^data/rescue_config\.json$" -or
			$file -match "\.tscn$" -or
			$file -match "^tests/run_m1[345]_" -or
			$file -match "^tests/m1[345]_") {
			$forbidden += $file
		}
	}
	return @($forbidden | Sort-Object -Unique)
}

function Get-T02ReadinessSummary() {
	$artRoot = "D:\NuwaSystem\ReefSpeciesCards\outputs"
	$artSummary = @()
	if (Test-Path $artRoot) {
		$artSummary = @(Get-ChildItem -LiteralPath $artRoot -Filter *.png -Recurse -File -ErrorAction SilentlyContinue |
			Sort-Object LastWriteTime -Descending |
			Select-Object -First 5 |
			ForEach-Object { $_.FullName })
	}
	$visionFiles = @(Get-ChildItem -LiteralPath $Project -Filter "DESIGN_VISION.md" -Recurse -File -ErrorAction SilentlyContinue |
		ForEach-Object { Normalize-PathForGit ($_.FullName.Substring($Project.Length + 1)) })
	return [ordered]@{
		reef_species_cards_candidates = $artSummary
		design_vision_files = $visionFiles
		overlay_pixel_note = "T01 does not enter UI. Project viewport is 1280x720; M15 evidence viewport is 960x540. T02 must measure actual overlay usable card region."
	}
}

$staticCheck = Invoke-GodotStaticParse
$m16Check = Invoke-GodotScriptCheck "m16_t01_card_manifest_verify" "res://tests/m16_t01_card_manifest_verify.gd" "M16_T01_SCREENSHOT_VALIDATOR_RESULT=PASS"
$regression = Invoke-M15RegressionInCleanClone
$regressionText = [string]$regression.text
if (Test-Path $TempRoot) {
	Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$m13Result = if ($regressionText -match "M13_REGRESSION_RESULT=PASS|M13_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T01Result = if ($regressionText -match "M14_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T02Result = if ($regressionText -match "M14_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T03Result = if ($regressionText -match "M14_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T04Result = if ($regressionText -match "M14_T04_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T01Result = if ($regressionText -match "M15_T01_RESULT=PASS|M15_T01_CAREMODEL_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T02Result = if ($regressionText -match "M15_T02_CARE_PLAYABLE_UI_RESULT=PASS|M15_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T03Result = if ($regressionText -match "M15_T03_CARE_DECISION_RC_RESULT=PASS") { "PASS" } else { "FAIL" }
$firstLoopDuration = if ($regressionText -match "FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }
$m15CareLoopDuration = if ($regressionText -match "M15_T02_FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }

$changedFiles = Get-ChangedFiles
$forbiddenTouched = @(Get-ForbiddenTouches $changedFiles)
$saveSystemDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- scripts/systems/SaveSystem.gd 2>$null) + @(git -C $Project diff --name-only -- scripts/systems/SaveSystem.gd 2>$null)
$saveSchemaDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- data/schemas/save_schema.json 2>$null) + @(git -C $Project diff --name-only -- data/schemas/save_schema.json 2>$null)
$saveSystemText = Get-Content -LiteralPath (Join-Path $Project "scripts\systems\SaveSystem.gd") -Raw
$saveVersionResult = if ($saveSystemText -match "const SAVE_VERSION:\s*int\s*=\s*3") { "PASS" } else { "FAIL" }
$zeroSaveImpact = if (($saveSystemDiff.Count -eq 0) -and ($saveSchemaDiff.Count -eq 0) -and ($saveVersionResult -eq "PASS")) { "PASS" } else { "FAIL" }

$manifestResult = if ($m16Check.summary -match "M16_T01_MANIFEST_RESULT=PASS") { "PASS" } else { "FAIL" }
$placeholderResult = if ($m16Check.summary -match "M16_T01_PLACEHOLDER_DETERMINISM_RESULT=PASS") { "PASS" } else { "FAIL" }
$fallbackResult = if ($m16Check.summary -match "M16_T01_FALLBACK_RESULT=PASS") { "PASS" } else { "FAIL" }
$visualValidatorResult = if ($m16Check.summary -match "M16_T01_SCREENSHOT_VALIDATOR_RESULT=PASS") { "PASS" } else { "FAIL" }
$allRegressionPass = @($m13Result,$m14T01Result,$m14T02Result,$m14T03Result,$m14T04Result,$m15T01Result,$m15T02Result,$m15T03Result) -notcontains "FAIL"
$loopResult = if (($firstLoopDuration -eq "840 seconds") -and ($m15CareLoopDuration -eq "580 seconds")) { "PASS" } else { "FAIL" }
$forbiddenResult = if ($forbiddenTouched.Count -eq 0) { "PASS" } else { "FAIL" }
$staticResult = if ($staticCheck.passed) { "PASS" } else { "FAIL" }
$t02Readiness = Get-T02ReadinessSummary

$result = if (
	$staticCheck.passed -and
	$m16Check.passed -and
	$regression.passed -and
	($manifestResult -eq "PASS") -and
	($placeholderResult -eq "PASS") -and
	($fallbackResult -eq "PASS") -and
	($visualValidatorResult -eq "PASS") -and
	($zeroSaveImpact -eq "PASS") -and
	$allRegressionPass -and
	($loopResult -eq "PASS") -and
	($forbiddenResult -eq "PASS")
) { "PASS" } else { "FAIL" }

$report = @()
$report += "# M16-T01 Card Manifest Report"
$report += ""
$report += "Task: $TaskName"
$report += ""
$report += "## Baseline"
$report += ""
$report += "- Effective M15 final baseline tag: $BaseTag"
$report += "- Effective M15 final baseline commit: $BaseCommit"
$report += "- Evidence rule: $EvidenceRuleVersion"
$report += "- M15 care path first loop is 580 seconds. This is below first_loop_min_seconds=600 because that lower bound only constrains the M14 no-care baseline path; M16-T01 does not modify M15 config or scripts."
$report += "- M14 no-care baseline FIRST_LOOP_DURATION remains 840 seconds."
$report += ""
$report += "## Scope"
$report += ""
$report += "- Adds card manifest contract, schema, placeholder card assets, CardAssetLibrary API, M16-T01 headless verification, and this report/receipt."
$report += "- Does not modify UI, save schema, SaveSystem, RescueSystem, GameState, LivestockSystem, species_rescue_pool, rescue_config, scenes, or existing M13/M14/M15 tests."
$report += "- Does not enter M16-T02 and does not connect real art samples."
$report += ""
$report += "## Manifest Contract"
$report += ""
$report += "- data/card_manifest.json uses schema_version=1."
$report += "- max_entries=3, matching the current species_rescue_pool count."
$report += "- species_id is the card id."
$report += "- T01 source is placeholder only."
$report += "- Asset paths are res:// paths and placeholder filenames are ASCII."
$report += "- SHA256 values are checked against actual placeholder PNG files."
$report += ""
$report += "## CardAssetLibrary API"
$report += ""
$report += "- Reads data/card_manifest.json on demand."
$report += "- Validates manifest schema and species pool constraints."
$report += "- get_card_texture(species_id) fallback order: manifest asset, generated placeholder texture, text_only fallback."
$report += "- Asset-missing and placeholder-disabled paths return structured fallback results and do not throw."
$report += "- No card fields are persisted."
$report += ""
$report += "## Automated Acceptance"
$report += ""
$report += "- Godot static parse: $staticResult"
$report += "- Manifest legal/illegal sample tests: $manifestResult"
$report += "- Placeholder determinism: $placeholderResult"
$report += "- Fallback three cases: $fallbackResult"
$report += "- Zero save impact: $zeroSaveImpact"
$report += "- Screenshot validator upgrade: $visualValidatorResult"
$report += "- M13 regression: $m13Result"
$report += "- M14-T01 regression: $m14T01Result"
$report += "- M14-T02 regression: $m14T02Result"
$report += "- M14-T03 regression: $m14T03Result"
$report += "- M14-T04 regression: $m14T04Result"
$report += "- M15-T01 regression: $m15T01Result"
$report += "- M15-T02 regression: $m15T02Result"
$report += "- M15-T03 regression: $m15T03Result"
$report += "- FIRST_LOOP_DURATION: $firstLoopDuration"
$report += "- M15_T02_FIRST_LOOP_DURATION: $m15CareLoopDuration"
$report += "- FORBIDDEN_TOUCHED: $($forbiddenTouched.Count)"
$report += ""
$report += "## Screenshot Validator Upgrade"
$report += ""
$report += "- T01 does not consume screenshots."
$report += "- CardAssetLibrary.validate_visual_evidence supports viewport source checks, resolution >=960x540, variance checks, UI semantic assertions, TextureRect.texture != null, TextureRect rendered size >=64px, card-region variance, and manifest SHA checks."
$report += ""
$report += "## T02 Readiness Notes"
$report += ""
$report += "- ReefSpeciesCards candidates recorded only for planning; T01 does not connect real art."
if ($t02Readiness.reef_species_cards_candidates.Count -gt 0) {
	foreach ($candidate in $t02Readiness.reef_species_cards_candidates) { $report += "  - $candidate" }
} else {
	$report += "  - No local ReefSpeciesCards PNG candidates found or accessible."
}
$report += "- DESIGN_VISION.md files:"
if ($t02Readiness.design_vision_files.Count -gt 0) {
	foreach ($vision in $t02Readiness.design_vision_files) { $report += "  - $vision" }
} else {
	$report += "  - Not found in project tree."
}
$report += "- Overlay note: $($t02Readiness.overlay_pixel_note)"
$report += ""
$report += "## Result"
$report += ""
$report += "- M16-T01 result: $result"
$report += "- Recommendation: request Codex independent review before M16-T02."
$report += "- M16-T02 remains blocked until Codex PASS."
$report -join "`n" | Set-Content -Path $ReportPath -Encoding UTF8

$receipt = [ordered]@{
	task_name = $TaskName
	base_tag = $BaseTag
	base_commit = $BaseCommit
	result = $result
	evidence_rule_version = $EvidenceRuleVersion
	suggested_tag = $FinalTag
	tag_object_verification_command = "git rev-parse $FinalTag"
	tag_target_verification_command = "git rev-parse $FinalTag^{}"
	manifest_result = $manifestResult
	placeholder_determinism_result = $placeholderResult
	fallback_result = $fallbackResult
	zero_save_impact_result = $zeroSaveImpact
	screenshot_validator_result = $visualValidatorResult
	godot_static_parse_result = $staticResult
	m13_result = $m13Result
	m14_t01_result = $m14T01Result
	m14_t02_result = $m14T02Result
	m14_t03_result = $m14T03Result
	m14_t04_result = $m14T04Result
	m15_t01_result = $m15T01Result
	m15_t02_result = $m15T02Result
	m15_t03_result = $m15T03Result
	first_loop_duration = $firstLoopDuration
	m15_t02_first_loop_duration = $m15CareLoopDuration
	forbidden_touched = $forbiddenTouched.Count
	forbidden_files_touched = @($forbiddenTouched)
	save_version_result = $saveVersionResult
	save_system_diff_empty = ($saveSystemDiff.Count -eq 0)
	save_schema_diff_empty = ($saveSchemaDiff.Count -eq 0)
	report_path = "reports/m16/M16_T01_CARD_MANIFEST_REPORT.md"
	receipt_path = "reports/m16/M16_T01_CARD_MANIFEST_RECEIPT.json"
	recommendation_for_codex_review = "YES"
	allow_m16_t02 = "WAIT_FOR_CODEX_PASS"
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8

Write-Host "M16_T01_CARD_MANIFEST_RESULT=$result"
Write-Host "M16_T01_MANIFEST_RESULT=$manifestResult"
Write-Host "M16_T01_PLACEHOLDER_DETERMINISM_RESULT=$placeholderResult"
Write-Host "M16_T01_FALLBACK_RESULT=$fallbackResult"
Write-Host "M16_T01_ZERO_SAVE_IMPACT_RESULT=$zeroSaveImpact"
Write-Host "M16_T01_SCREENSHOT_VALIDATOR_RESULT=$visualValidatorResult"
Write-Host "M13_RESULT=$m13Result"
Write-Host "M14_T01_RESULT=$m14T01Result"
Write-Host "M14_T02_RESULT=$m14T02Result"
Write-Host "M14_T03_RESULT=$m14T03Result"
Write-Host "M14_T04_RESULT=$m14T04Result"
Write-Host "M15_T01_RESULT=$m15T01Result"
Write-Host "M15_T02_RESULT=$m15T02Result"
Write-Host "M15_T03_RESULT=$m15T03Result"
Write-Host "FIRST_LOOP_DURATION=$firstLoopDuration"
Write-Host "M15_T02_FIRST_LOOP_DURATION=$m15CareLoopDuration"
Write-Host "FORBIDDEN_TOUCHED=$($forbiddenTouched.Count)"
Write-Host "GODOT_STATIC_PARSE_RESULT=$staticResult"
Write-Host "M16_T01_REGRESSION_EXIT_CODE=$($regression.exit_code)"
if (-not $regression.passed) {
	Write-Host "M16_T01_REGRESSION_DIAGNOSTIC_START"
	(($regressionText -split "`r?`n") | Select-Object -First 40) | ForEach-Object { Write-Host $_ }
	Write-Host "M16_T01_REGRESSION_DIAGNOSTIC_END"
}
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
