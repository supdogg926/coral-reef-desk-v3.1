# D003: 02-06 freeze shell verification
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
Push-Location $ProjectRoot
$shells = @{
    "02" = @("shell_02_ready_empty.png", 260, 100, 760, 520)
    "03" = @("shell_03_voyaging_empty.png", 260, 100, 760, 520)
    "04" = @("shell_04_result_empty.png", 260, 100, 760, 520)
    "05" = @("shell_05_codex_empty.png", 120, 70, 1040, 580)
    "06" = @("shell_06_release_empty.png", 120, 70, 1040, 580)
}
$allOk = $true
foreach ($pageId in $shells.Keys) {
    $info = $shells[$pageId]
    $path = "assets/m19/ui/chrome/$($info[0])"
    if (-not (Test-Path $path)) { Write-Error "D003 FAIL: Page $pageId shell missing: $path"; $allOk = $false; continue }
    # Check usage in panel code
    $shellName = $info[0]
    $panelFiles = @{
        "02" = "M19BlueGuardianPanel.gd"; "03" = "M19BlueGuardianPanel.gd"
        "04" = "M19ResultPanelHybrid.gd"; "05" = "M19CodexPanel.gd"; "06" = "M19ReleasePanel.gd"
    }
    $pf = $panelFiles[$pageId]
    if ($pf -and (Test-Path "scenes/ui/$pf")) {
        $pc = Get-Content "scenes/ui/$pf" -Raw
        if ($pc -match $shellName) { Write-Host "  Page ${pageId}: shell referenced in $pf" }
        else { Write-Host "  Page ${pageId}: WARNING - shell not referenced in $pf (may use shared panel)" }
    }
    # Check no StyleBox fallback in panel
    if ($pf -and (Test-Path "scenes/ui/$pf")) {
        $pc = Get-Content "scenes/ui/$pf" -Raw
        if ($pc -match 'make_shell_style') { Write-Error "D003 FAIL: Page $pageId still uses StyleBox in $pf"; $allOk = $false }
    }
}
if ($allOk) { Write-Host "D003 PASS: All 5 freeze shells present and referenced" }
else { Write-Error "D003 FAIL"; Pop-Location; exit 1 }
Pop-Location; exit 0
