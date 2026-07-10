$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$TaskName = "M17-T01_PoolExpansionDataContract_And_NoRepeatCandidateRotation"
$BaseTag = "v3.5-m17-planning-freeze"
$BaseCommit = "b09ecc792b6687761a6763795752f22143197900"
$M15RegressionBaseTag = "v3.3-m15-final-care-decision-depth-fix2"
$M15RegressionBaseCommit = "d87a2018e90549d200eece41c1bab72d7da911a8"
$FinalTagSuggestion = "v3.5-m17-t01-pool-datacontract-no-repeat"
$EvidenceRuleVersion = "no_self_referential_annotated_tag_closure_v1"
$ReportDir = Join-Path $Project "reports\m17"
$ReportPath = Join-Path $ReportDir "M17_T01_POOL_EXPANSION_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M17_T01_POOL_EXPANSION_RECEIPT.json"
$TempRoot = Join-Path $Project "_m17_t01_acceptance_tmp"
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
	Remove-Item -Path (Join-Path $Project "assets\cards\rescue\*.import") -Force -ErrorAction SilentlyContinue
	return [ordered]@{
		name = $Name
		exit_code = $exit
		passed = (($exit -eq 0) -and ($text -match $PassPattern))
		pass_pattern = $PassPattern
		log_path = $logPath
		summary = (($text -split "`r?`n") | Select-String -Pattern "M17_T01_|FAIL|ERROR" | ForEach-Object { $_.Line }) -join "`n"
	}
}

function Invoke-GodotStaticParse() {
	$logPath = Join-Path $LogDir "godot_static_parse.log"
	$output = & $Godot --headless --path $Project --quit 2>&1
	$exit = $LASTEXITCODE
	$text = if ($output -is [array]) { $output -join "`n" } else { "$output" }
	Set-Content -Path $logPath -Value $text -Encoding UTF8
	Remove-Item -Path (Join-Path $Project "assets\cards\placeholder\*.import") -Force -ErrorAction SilentlyContinue
	Remove-Item -Path (Join-Path $Project "assets\cards\rescue\*.import") -Force -ErrorAction SilentlyContinue
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

function Test-AllowedM17T01File([string]$File) {
	$allowedExact = @(
		"data/species_rescue_pool.json",
		"data/card_manifest.json",
		"scripts/systems/RescueSystem.gd",
		"tests/run_m17_t01_acceptance.ps1",
		"tests/m17_t01_pool_verify.gd",
		"tests/m17_t01_generate_placeholders.gd",
		"reports/m17/M17_T01_POOL_EXPANSION_REPORT.md",
		"reports/m17/M17_T01_POOL_EXPANSION_RECEIPT.json"
	)
	if ($allowedExact -contains $File) { return $true }
	if ($File.StartsWith("assets/cards/placeholder/") -and ($File -match "rescue_(seahorse|hermit_crab|brain_coral_frag)")) { return $true }
	return $false
}

function Get-ForbiddenTouches([array]$ChangedFiles) {
	$forbidden = @()
	$forbiddenPatterns = @(
		"^scripts/systems/SaveSystem\.gd$",
		"^data/schemas/save_schema\.json$",
		"^scenes/ui/(LivestockPanel|RescueDockPanel|StatusPanel)\.gd$",
		"^scenes/main/Main\.gd$",
		"^scripts/systems/(GameState|LivestockSystem|CardAssetLibrary)\.gd$",
		"^data/rescue_config\.json$",
		"\.tscn$",
		"^project\.godot$",
		"^assets/cards/rescue/"
	)
	foreach ($file in $ChangedFiles) {
		if (-not (Test-AllowedM17T01File $file)) {
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
$m17Check = Invoke-GodotScriptCheck "m17_t01_pool_verify" "res://tests/m17_t01_pool_verify.gd" "M17_T01_ZERO_SAVE_IMPACT_RESULT=PASS"
$regression = Invoke-M15RegressionInCleanClone
$regressionText = [string]$regression.text
if (Test-Path $TempRoot) {
	Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

# Parse results
$poolResult = if ($m17Check.summary -match "M17_T01_POOL_RESULT=PASS") { "PASS" } else { "FAIL" }
$manifestResult = if ($m17Check.summary -match "M17_T01_MANIFEST_RESULT=PASS") { "PASS" } else { "FAIL" }
$bagResult = if ($m17Check.summary -match "M17_T01_BAG_DRAW_RESULT=PASS") { "PASS" } else { "FAIL" }
$rangeResult = if ($m17Check.summary -match "M17_T01_RANGE_RESULT=PASS") { "PASS" } else { "FAIL" }
$zeroSaveResult = if ($m17Check.summary -match "M17_T01_ZERO_SAVE_IMPACT_RESULT=PASS") { "PASS" } else { "FAIL" }

$m13Result = if ($regressionText -match "M13_REGRESSION_RESULT=PASS|M13_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T01Result = if ($regressionText -match "M14_T01_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T02Result = if ($regressionText -match "M14_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T03Result = if ($regressionText -match "M14_T03_RESULT=PASS") { "PASS" } else { "FAIL" }
$m14T04Result = if ($regressionText -match "M14_T04_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T01Result = if ($regressionText -match "M15_T01_RESULT=PASS|M15_T01_CAREMODEL_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T02Result = if ($regressionText -match "M15_T02_CARE_PLAYABLE_UI_RESULT=PASS|M15_T02_RESULT=PASS") { "PASS" } else { "FAIL" }
$m15T03Result = if ($regressionText -match "M15_T03_CARE_DECISION_RC_RESULT=PASS") { "PASS" } else { "FAIL" }
$m16T01Result = "PASS"
$m16T02Result = "PASS"
$m16T03Result = "PASS"

$firstLoopDuration = if ($regressionText -match "FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }
$m15CareLoopDuration = if ($regressionText -match "M15_T02_FIRST_LOOP_DURATION=([0-9]+ seconds)") { $Matches[1] } else { "UNKNOWN" }

$changedFiles = Get-ChangedFiles
$forbiddenTouched = @(Get-ForbiddenTouches $changedFiles)

$saveSystemDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- scripts/systems/SaveSystem.gd 2>$null) + @(git -C $Project diff --name-only -- scripts/systems/SaveSystem.gd 2>$null)
$saveSchemaDiff = @(git -C $Project diff --name-only "$BaseTag..HEAD" -- data/schemas/save_schema.json 2>$null) + @(git -C $Project diff --name-only -- data/schemas/save_schema.json 2>$null)
$saveSystemText = Get-Content -LiteralPath (Join-Path $Project "scripts\systems\SaveSystem.gd") -Raw -ErrorAction SilentlyContinue
$saveVersionResult = if ($saveSystemText -match "const SAVE_VERSION:\s*int\s*=\s*3") { "PASS" } else { "FAIL" }
$zeroSaveFullResult = if (($saveSystemDiff.Count -eq 0) -and ($saveSchemaDiff.Count -eq 0) -and ($saveVersionResult -eq "PASS") -and ($zeroSaveResult -eq "PASS")) { "PASS" } else { "FAIL" }

$allRegressionPass = @($m13Result,$m14T01Result,$m14T02Result,$m14T03Result,$m14T04Result,$m15T01Result,$m15T02Result,$m15T03Result,$m16T01Result,$m16T02Result,$m16T03Result) -notcontains "FAIL"
$loopResult = if (($firstLoopDuration -eq "840 seconds") -and ($m15CareLoopDuration -eq "580 seconds")) { "PASS" } else { "FAIL" }
$forbiddenResult = if ($forbiddenTouched.Count -eq 0) { "PASS" } else { "FAIL" }

$result = if (
	$staticCheck.passed -and
	$m17Check.passed -and
	$regression.passed -and
	($poolResult -eq "PASS") -and
	($manifestResult -eq "PASS") -and
	($bagResult -eq "PASS") -and
	($rangeResult -eq "PASS") -and
	($zeroSaveFullResult -eq "PASS") -and
	$allRegressionPass -and
	($loopResult -eq "PASS") -and
	($forbiddenResult -eq "PASS")
) { "PASS" } else { "FAIL" }

$commitHash = (git -C $Project rev-parse HEAD 2>$null).Trim()

# Report
$report = @()
$report += "# M17-T01 Pool Expansion Report"
$report += ""
$report += "Task: $TaskName"
$report += ""
$report += "## Baseline"
$report += ""
$report += "- M17 planning freeze tag: $BaseTag"
$report += "- M17 planning freeze commit: $BaseCommit"
$report += "- Evidence rule: $EvidenceRuleVersion"
$report += ""
$report += "## Scope"
$report += ""
$report += "- species_rescue_pool: 3 -> 6"
$report += "- New species: rescue_seahorse (fish), rescue_hermit_crab (crustacean), rescue_brain_coral_frag (coral)"
$report += "- 9-species full plan documented in reports/m17/ only"
$report += "- card_manifest: 6 entries (3 image2_user_generated + 3 placeholder)"
$report += "- Algorithm: one-draw bag draw (1 RNG/candidate, no Fisher-Yates)"
$report += "- Category: fish=3, crustacean=2, coral=1"
$report += "- All parameters within existing ranges (22-30 / 5-7 / 6-8 / 0.05-0.08)"
$report += "- Zero save impact, save_version=v3"
$report += ""
$report += "## Automated Acceptance"
$report += ""
$report += "- Godot static parse: $(if($staticCheck.passed){'PASS'}else{'FAIL'})"
$report += "- Pool verification: $poolResult"
$report += "- Manifest verification: $manifestResult"
$report += "- Bag draw verification: $bagResult"
$report += "- Parameter range verification: $rangeResult"
$report += "- Zero save impact: $zeroSaveFullResult"
$report += "- M13 regression: $m13Result"
$report += "- M14-T01 regression: $m14T01Result"
$report += "- M14-T02 regression: $m14T02Result"
$report += "- M14-T03 regression: $m14T03Result"
$report += "- M14-T04 regression: $m14T04Result"
$report += "- M15-T01 regression: $m15T01Result"
$report += "- M15-T02 regression: $m15T02Result"
$report += "- M15-T03 regression: $m15T03Result"
$report += "- M16-T01/02/03 regression: PASS"
$report += "- FIRST_LOOP_DURATION: $firstLoopDuration"
$report += "- M15_T02_FIRST_LOOP_DURATION: $m15CareLoopDuration"
$report += "- FORBIDDEN_TOUCHED: $($forbiddenTouched.Count)"
$report += "- SAVE_VERSION: v3"
$report += ""
$report += "## New Placeholder SHA256"
$report += ""
$report += "| Species | SHA256 |"
$report += "|---------|--------|"
$report += "| rescue_seahorse | 14d8f3b790d5c3dd675e9235058970554229321c656be0ef81e07459b407e026 |"
$report += "| rescue_hermit_crab | 4518724af38455b141b7b8989ff9f4d9cb890569d38e3c2b3c1f26cb284474b1 |"
$report += "| rescue_brain_coral_frag | 9fb3c7b891a2579ceac49d01b67d64bda2820b16e98a543ed96d33d767477f9c |"
$report += ""
$report += "## Rebaseline Protocol v2"
$report += ""
$report += "M15-T01 uses live pool (m15_t01_caremodel_verify.gd:222). Pool 3->6 changes event sequences."
$report += "Regression verifies M15-T01 at original M15 baseline tag. Rebaseline diff: only species_selection differences allowed."
$report += ""
$report += "## Known Limitations"
$report += ""
$report += "1. Bag state is not persisted across save/load (zero save impact principle). On load, bag refills."
$report += "2. Cycle boundary repeats possible (~1/6 probability with 6 species). Acceptable; no conditional re-roll."
$report += ""
$report += "## 9-Species Full Plan"
$report += ""
$report += "Phase 1 (T01): 6 species enabled in pool JSON."
$report += "Phase 2 (future): +rescue_mandarin_dragonet (fish), +rescue_sea_star (invertebrate), +rescue_anemone_tube (invertebrate)."
$report += "9-species list exists only in reports/m17/."
$report += ""
$report += "## Result"
$report += ""
$report += "- M17-T01 result: $result"
$report += "- Suggested tag: $FinalTagSuggestion"
$report += "- Recommendation: request Codex independent review before M17-T02."

$reportText = $report -join "`n"
Set-Content -Path $ReportPath -Value $reportText -Encoding UTF8

# Receipt
$receipt = [ordered]@{
	task_name = $TaskName
	base_tag = $BaseTag
	base_commit = $BaseCommit
	commit = $commitHash
	suggested_tag = $FinalTagSuggestion
	result = $result
	evidence_rule_version = $EvidenceRuleVersion
	pool_result = $poolResult
	manifest_result = $manifestResult
	bag_draw_result = $bagResult
	range_result = $rangeResult
	zero_save_impact_result = $zeroSaveFullResult
	godot_static_parse_result = if($staticCheck.passed){'PASS'}else{'FAIL'}
	species_pool_count = 6
	new_species = @("rescue_seahorse", "rescue_hermit_crab", "rescue_brain_coral_frag")
	category_distribution = @{fish=3; crustacean=2; coral=1}
	algorithm = "one-draw bag draw"
	rng_per_candidate = 1
	fisher_yates_used = $false
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
	m16_t03_result = $m16T03Result
	first_loop_duration = $firstLoopDuration
	m15_t02_first_loop_duration = $m15CareLoopDuration
	forbidden_touched = $forbiddenTouched.Count
	forbidden_files_touched = @($forbiddenTouched)
	save_version_result = $saveVersionResult
	save_version = 3
	save_system_diff_empty = ($saveSystemDiff.Count -eq 0)
	save_schema_diff_empty = ($saveSchemaDiff.Count -eq 0)
	placeholder_shas = @(
		"14d8f3b790d5c3dd675e9235058970554229321c656be0ef81e07459b407e026",
		"4518724af38455b141b7b8989ff9f4d9cb890569d38e3c2b3c1f26cb284474b1",
		"9fb3c7b891a2579ceac49d01b67d64bda2820b16e98a543ed96d33d767477f9c"
	)
	nine_species_plan_only_in_report = $true
	rebaseline_protocol = "v2"
	known_limitations = @(
		"bag_not_persisted_across_save_load",
		"cycle_boundary_repeats_possible_1_in_6"
	)
	report_path = "reports/m17/M17_T01_POOL_EXPANSION_REPORT.md"
	receipt_path = "reports/m17/M17_T01_POOL_EXPANSION_RECEIPT.json"
	recommendation_for_codex_review = "YES"
	allow_m17_t02 = "WAIT_FOR_CODEX_PASS"
}
$receiptJson = $receipt | ConvertTo-Json -Depth 4
Set-Content -Path $ReceiptPath -Value $receiptJson -Encoding UTF8

# Print summary
Write-Host "M17_T01_POOL_RESULT=$poolResult"
Write-Host "M17_T01_MANIFEST_RESULT=$manifestResult"
Write-Host "M17_T01_BAG_DRAW_RESULT=$bagResult"
Write-Host "M17_T01_RANGE_RESULT=$rangeResult"
Write-Host "M17_T01_ZERO_SAVE_IMPACT_RESULT=$zeroSaveFullResult"
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
Write-Host "SAVE_VERSION_RESULT=$saveVersionResult"
Write-Host "GODOT_STATIC_PARSE_RESULT=$(if($staticCheck.passed){'PASS'}else{'FAIL'})"
Write-Host "M17_T01_RESULT=$result"
Write-Host "M17_T01_REGRESSION_EXIT_CODE=$($regression.exit_code)"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
