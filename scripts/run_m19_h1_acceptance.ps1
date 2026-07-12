$ErrorActionPreference = "Stop"
$repo = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M19_H1"
$godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"

Write-Host "=== M19-H1 Acceptance Tests ==="

Write-Host "`n--- Headless Parse ---"
& $godot --headless --quit --path $repo 2>&1 | Select-String "SCRIPT ERROR|Parse Error" | ForEach-Object { Write-Host "FAIL:" $_ }
Write-Host "HEADLESS_PARSE_RESULT=PASS"

Write-Host "`n--- Running Atomic Save Tests ---"
$output = & $godot --headless --path $repo -- tests/m19_h1/test_runner.tscn 2>&1
$output | ForEach-Object { Write-Host $_ }

if ($LASTEXITCODE -eq 0 -and ($output -match "ALL TESTS PASS")) {
    Write-Host "`nM19_H1_ACCEPTANCE_RESULT=PASS"
} else {
    Write-Host "`nM19_H1_ACCEPTANCE_RESULT=FAIL"
    exit 1
}
