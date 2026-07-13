# D002: Reads probe output — verifies single full master, zero region crops
param([string]$EvidenceDir)
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
if (-not $EvidenceDir) {
    $stagings = Get-ChildItem "$ProjectRoot\reports\m19\acceptance\staging" -Directory | Sort-Object LastWriteTime -Descending
    if (-not $stagings) { Write-Error "D002 FAIL: No probe evidence"; exit 1 }
    $EvidenceDir = $stagings[0].FullName
}
$probe = Get-Content "$EvidenceDir\probe_output.json" -Raw | ConvertFrom-Json
if ($probe.full_master_count -ne 1) { Write-Error "D002 FAIL: Full master count=$($probe.full_master_count), expected 1"; exit 1 }
# Check no region crops visible
$regionCrops = ($probe.all_texture_rects | Where-Object { $_.resource_path -match "01_main_tank|01_sump|01_gauge_belt|01_knob_panel|01_device_grid|01_sidebar" })
if ($regionCrops) { Write-Error "D002 FAIL: $($regionCrops.Count) region crops visible in runtime"; exit 1 }
Write-Host "D002 PASS: Full master=1, region crops=0"
exit 0
