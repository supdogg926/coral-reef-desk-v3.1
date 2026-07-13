# D003: Reads probe — verifies 5 freeze shells visible in runtime
param([string]$EvidenceDir)
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
if (-not $EvidenceDir) {
    $stagings = Get-ChildItem "$ProjectRoot\reports\m19\acceptance\staging" -Directory | Sort-Object LastWriteTime -Descending
    if (-not $stagings) { Write-Error "D003 FAIL: No probe evidence"; exit 1 }
    $EvidenceDir = $stagings[0].FullName
}
$probe = Get-Content "$EvidenceDir\probe_output.json" -Raw | ConvertFrom-Json
$shells = @("shell_02_ready_empty","shell_03_voyaging_empty","shell_04_result_empty","shell_05_codex_empty","shell_06_release_empty")
$found = 0
foreach ($s in $shells) {
    $match = $probe.all_texture_rects | Where-Object { $_.resource_path -match $s -and $_.visible_in_tree }
    if ($match) { $found++ } else { Write-Error "D003 FAIL: $s not visible in runtime tree" }
}
if ($found -ne 5) { Write-Error "D003 FAIL: Only $found/5 shells visible"; exit 1 }
Write-Host "D003 PASS: 5/5 freeze shells visible in runtime"
exit 0
