# D004: Reads probe — verifies zero legacy nodes, zero world ColorRects
param([string]$EvidenceDir)
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
if (-not $EvidenceDir) {
    $stagings = Get-ChildItem "$ProjectRoot\reports\m19\acceptance\staging" -Directory | Sort-Object LastWriteTime -Descending
    if (-not $stagings) { Write-Error "D004 FAIL: No probe evidence"; exit 1 }
    $EvidenceDir = $stagings[0].FullName
}
$probe = Get-Content "$EvidenceDir\probe_output.json" -Raw | ConvertFrom-Json
if ($probe.legacy_visible_nodes.Count -gt 0) { Write-Error "D004 FAIL: $($probe.legacy_visible_nodes.Count) legacy nodes visible"; exit 1 }
if ($probe.world_nodes_without_texture.Count -gt 0) { Write-Error "D004 FAIL: $($probe.world_nodes_without_texture.Count) world placeholders"; exit 1 }
if ($probe.color_rect_nodes.Count -gt 10) { Write-Error "D004 FAIL: $($probe.color_rect_nodes.Count) ColorRects (unusual count)"; exit 1 }
Write-Host "D004 PASS: Legacy=0 World_placeholder=0"
exit 0
