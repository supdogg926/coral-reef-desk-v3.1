$ErrorActionPreference = "Continue"
$Godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$Project = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Project "reports\m14"
$ReportPath = Join-Path $ReportDir "M14_T01_RESCUE_CORE_DATAMODEL_REPORT.md"
$ReceiptPath = Join-Path $ReportDir "M14_T01_RESCUE_CORE_DATAMODEL_RECEIPT.json"
$LogDir = Join-Path $ReportDir "logs"
New-Item -ItemType Directory -Force -Path $ReportDir,$LogDir | Out-Null

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
		summary = (($text -split "`r?`n") | Select-String -Pattern "RESULT=|PASS|FAIL|M13_30DAY|M14-T01" | Select-Object -Last 12 | ForEach-Object { $_.Line }) -join "`n"
	}
}

$tests = @()
$tests += Invoke-GodotCheck "m14_rescue_core" "tests/m14_rescue_core_verify.gd" "M14_T01_RESCUE_CORE_RESULT=PASS"
$tests += Invoke-GodotCheck "m13_smoke_regression" "tests/smoke_test.gd" "SMOKE_TEST_RESULT=PASS"
$tests += Invoke-GodotCheck "m13_progression_regression" "tests/m13_30day_progression_sim_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_economy_balance_regression" "tests/m13_economy_balance_30day_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_unlock_capacity_regression" "tests/m13_unlock_capacity_30day_verify.gd" "PASS"
$tests += Invoke-GodotCheck "m13_save_load_regression" "tests/m13_save_load_30day_verify.gd" "PASS"

$forbiddenTouched = @()
$baseTag = "v3.1-m13-30day-progression-economy"
$baseDiffFiles = @(git -C $Project diff --name-only $baseTag..HEAD)
$changed = @($baseDiffFiles)
$statusLines = @(git -C $Project status --short)
foreach ($line in $statusLines) {
	if ($line.Length -ge 4) {
		$path = $line.Substring(3)
		if ($changed -notcontains $path) {
			$changed += $path
		}
	}
}
foreach ($f in $changed) {
	if ($f -match "\.tscn$" -or $f -match "^scenes/ui/" -or $f -match "species_master\.json$") {
		$forbiddenTouched += $f
	}
}
$rescuePass = (@($tests | Where-Object { $_.name -eq "m14_rescue_core" -and $_.passed }).Count -eq 1)
$m13Pass = (@($tests | Where-Object { $_.name -like "m13_*" -and -not $_.passed }).Count -eq 0)
$allTestsPass = (@($tests | Where-Object { -not $_.passed }).Count -eq 0)
$result = if ($allTestsPass -and $forbiddenTouched.Count -eq 0) { "PASS" } else { "FAIL" }
$commitHash = (git -C $Project rev-parse HEAD 2>$null) -replace "\s+", ""
$branch = (git -C $Project branch --show-current 2>$null) -replace "\s+", ""

$report = @()
$report += "# M14-T01 RescueCore DataModel And HeadlessSim Report"
$report += ""
$report += "Overall Status: **$result**"
$report += ""
$report += "- Branch: $branch"
$report += "- Base tag: $baseTag"
$report += "- Commit at validation: $commitHash"
$report += "- Project: $Project"
$report += ""
$report += "## Scope"
$report += ""
$report += "Implemented data/model/headless rescue loop only. No UI, .tscn, art, ocean, injury branching, breeding, care actions, reputation shop, or multi-slot rescue behavior was added."
$report += ""
$report += "## Actual Structure Notes"
$report += ""
$report += "- Godot systems live under scripts/systems/."
$report += "- Data lives under data/."
$report += "- M13 regression scripts live under tests/."
$report += "- The existing tests/run_m13_acceptance.ps1 has a hard-coded original project path, so this M14 runner invokes the M13 Godot scripts directly against this worktree."
$report += "- SaveSystem.gd was modified because M14-T01 explicitly requires save schema migration and rescue fields."
$report += ""
$report += "## Test Results"
$report += ""
$report += "| Test | Passed | Exit | Log |"
$report += "|---|---:|---:|---|"
foreach ($t in $tests) {
	$report += "| $($t.name) | $($t.passed) | $($t.exit_code) | $($t.log_path) |"
}
$report += ""
$report += "## Forbidden Files Touched"
$report += ""
if ($forbiddenTouched.Count -eq 0) {
	$report += "- None."
} else {
	foreach ($f in $forbiddenTouched) { $report += "- $f" }
}
$report += ""
$report += "## Modified Files"
$report += ""
foreach ($f in $changed) { $report += "- $f" }
$report += ""
$report += "## Known Limitations"
$report += ""
$report += "- `injury_type` is stored only as a reserved field; no injury branching exists."
$report += "- The rescue slot is logic-only and has no UI representation."
$report += "- Reputation only accumulates; no reputation spending/shop exists."
$report += ""
$report += "## Acceptance Summary"
$report += ""
$report += "- M13 regression result: $($(if ($m13Pass) { "PASS" } else { "FAIL" }))"
$report += "- Rescue sim result: $($(if ($rescuePass) { "PASS" } else { "FAIL" }))"
$report += "- Save migration result: $($(if ($rescuePass) { "PASS" } else { "FAIL" }))"
$report += "- M14_T01_RESCUE_CORE_DATAMODEL_RESULT=$result"
Set-Content -Path $ReportPath -Value ($report -join "`n") -Encoding UTF8

$receipt = [ordered]@{
	task_name = "M14-T01_RescueCore_DataModel_And_HeadlessSim"
	branch = $branch
	base_tag = $baseTag
	commit_hash = $commitHash
	result = $result
	tests_run = @($tests | ForEach-Object { $_.name })
	tests_passed = @($tests | Where-Object { $_.passed } | ForEach-Object { $_.name })
	m13_regression_result = if ($m13Pass) { "PASS" } else { "FAIL" }
	rescue_sim_result = if ($rescuePass) { "PASS" } else { "FAIL" }
	save_migration_result = if ($rescuePass) { "PASS" } else { "FAIL" }
	modified_files = $changed
	forbidden_files_touched = $forbiddenTouched
	report_path = $ReportPath
	receipt_path = $ReceiptPath
	tag = "v3.2-m14-t01-rescue-datamodel"
	known_limitations = @(
		"injury_type is reserved only",
		"logic/headless only; no UI or scene work",
		"single rescue slot only",
		"reputation accumulation only"
	)
	test_details = $tests
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -Path $ReceiptPath -Encoding UTF8

Write-Host "M14_T01_RESCUE_CORE_DATAMODEL_RESULT=$result"
Write-Host "Report: $ReportPath"
Write-Host "Receipt: $ReceiptPath"
exit $(if ($result -eq "PASS") { 0 } else { 1 })
