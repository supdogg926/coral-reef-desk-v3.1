# D002: 01 single full master verification
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
Push-Location $ProjectRoot
$hybrid = Get-Content "scenes/ui/M19MainInterfaceHybrid.gd" -Raw
# Must reference full master, must NOT have region crop dict
if ($hybrid -match "chrome_regions") { Write-Error "D002 FAIL: Region crop dict still in code"; Pop-Location; exit 1 }
if ($hybrid -notmatch "01_runtime_empty_master") { Write-Error "D002 FAIL: Full master path not found"; Pop-Location; exit 1 }
# Verify full master file exists
if (-not (Test-Path "assets/m19/ui/chrome/01_runtime_empty_master.png")) { Write-Error "D002 FAIL: Full master PNG missing"; Pop-Location; exit 1 }
# Verify NO region crops are individually referenced as production plates
$regionRefs = ($hybrid | Select-String "01_main_tank.png|01_sump.png|01_gauge_belt.png|01_knob_panel.png|01_device_grid.png|01_sidebar.png" -AllMatches).Matches.Count
if ($regionRefs -gt 0) { Write-Error "D002 FAIL: $regionRefs region crop references found"; Pop-Location; exit 1 }
Write-Host "D002 PASS: Single full master, zero region crops"
Pop-Location; exit 0
