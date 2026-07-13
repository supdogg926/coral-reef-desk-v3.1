$c = Get-Content "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M19_T2_LOOP/scenes/ui/M19MainInterfaceHybrid.gd" -Raw
if ($c -match "chrome_regions") { Write-Error "D002 FAIL region_crops"; exit 1 }
if ($c -notmatch "01_runtime_empty_master") { Write-Error "D002 FAIL no_full_master"; exit 1 }
Write-Host "D002 PASS"; exit 0
