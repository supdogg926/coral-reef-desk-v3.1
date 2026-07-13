$sh = @("shell_02_ready_empty","shell_03_voyaging_empty","shell_04_result_empty","shell_05_codex_empty","shell_06_release_empty")
foreach ($s in $sh) {
  $fp = "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M19_T2_LOOP/assets/m19/ui/chrome/$s.png"
  if (-not (Test-Path $fp)) { Write-Error "D003 FAIL $s"; exit 1 }
}
Write-Host "D003 PASS"; exit 0
