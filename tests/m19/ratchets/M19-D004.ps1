$mg = Get-Content "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M19_T2_LOOP/scenes/main/Main.gd" -Raw
if ($mg -notmatch "visible = false") { Write-Error "D004 FAIL no_hide"; exit 1 }
$hg = Get-Content "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M19_T2_LOOP/scenes/ui/M19MainInterfaceHybrid.gd" -Raw
if ($hg -match "ColorRect.new()") { Write-Error "D004 FAIL ColorRect"; exit 1 }
Write-Host "D004 PASS"; exit 0
