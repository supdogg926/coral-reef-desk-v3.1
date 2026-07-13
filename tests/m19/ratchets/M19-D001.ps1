$p = "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M19_T2_LOOP"
$ms = (Get-Content "$p/project.godot" | Select-String "run/main_scene").ToString()
if ($ms -notmatch "Main.tscn") { Write-Error "D001 FAIL"; exit 1 }
Write-Host "D001 PASS"; exit 0
