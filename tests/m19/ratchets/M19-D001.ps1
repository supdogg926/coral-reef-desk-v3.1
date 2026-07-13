# D001: Production entry verification (relative paths, runtime checks)
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
Push-Location $ProjectRoot
$pg = Get-Content "project.godot" -Raw
if ($pg -notmatch "Main.tscn") { Write-Error "D001 FAIL: Main.tscn not run/main_scene"; Pop-Location; exit 1 }
# Verify branch
$branch = (git branch --show-current 2>&1).Trim()
if ($branch -notmatch "m19") { Write-Error "D001 FAIL: Not on M19 branch ($branch)"; Pop-Location; exit 1 }
# Verify hybrid scene file exists
if (-not (Test-Path "scenes/ui/M19MainInterfaceHybrid.gd")) { Write-Error "D001 FAIL: Hybrid script missing"; Pop-Location; exit 1 }
Write-Host "D001 PASS: Main.tscn entry, M19 branch, Hybrid present"
Pop-Location; exit 0
