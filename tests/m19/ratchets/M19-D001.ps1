# D001: Reads W01 Runtime Probe output — production entry verification
param([string]$EvidenceDir)
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
if (-not $EvidenceDir) {
    $stagings = Get-ChildItem "$ProjectRoot\reports\m19\acceptance\staging" -Directory | Sort-Object LastWriteTime -Descending
    if (-not $stagings) { Write-Error "D001 FAIL: No probe evidence found"; exit 1 }
    $EvidenceDir = $stagings[0].FullName
}
$probe = Get-Content "$EvidenceDir\probe_output.json" -Raw | ConvertFrom-Json
if ($probe.active_scene_path -notmatch "Main") { Write-Error "D001 FAIL: Active scene is not Main"; exit 1 }
if ($probe.hybrid_instances.Count -eq 0) { Write-Error "D001 FAIL: No Hybrid instances found"; exit 1 }
if ($probe.full_master_count -eq 0) { Write-Error "D001 FAIL: Full master not found in runtime"; exit 1 }
Write-Host "D001 PASS: Active=$($probe.active_scene_path) Hybrid=$($probe.hybrid_instances.Count) Master=$($probe.full_master_count)"
exit 0
