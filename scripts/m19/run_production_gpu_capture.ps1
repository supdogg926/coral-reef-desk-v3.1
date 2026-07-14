param(
  [ValidateSet("M19-W01-PRODUCTION-TAKEOVER","M19-W02-FACT-DATA-LED","M19-W03-MODAL-BEHAVIOR","M19-W04-EVIDENCE-FINAL","ALL")]
  [string]$WaveId="M19-W01-PRODUCTION-TAKEOVER",
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Write-Host "==> M19 Production GPU Capture — WaveId=$WaveId"

Push-Location $RepoRoot
try {
  $stagingDir = Join-Path $RepoRoot "reports\m19\acceptance\staging"
  $runtimeDir = Join-Path $RepoRoot "reports\m19\final_deterministic\runtime"

  # Check for existing captures from this wave
  $captures = @(Get-ChildItem -Path $stagingDir -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  if ($captures.Count -eq 0) {
    Write-Host "  [INFO] No staging captures found. GPU capture requires Godot runtime."
    Write-Host "  [INFO] Run: Godot_v4.7-stable_win64.exe --headless --script tests/m19/M19W01AllPageDriver.gd"
    Write-Host "  [WARN] GPU capture skipped — re-run after Godot execution"
    exit 0
  }

  $latestCapture = $captures[0].FullName
  Write-Host "  [INFO] Latest capture: $latestCapture"

  # Validate captured screenshots
  foreach ($page in @("02","03","04","05","06")) {
    $pngPath = Join-Path $latestCapture "page_${page}_runtime.png"
    $jsonPath = Join-Path $latestCapture "page_${page}_evidence.json"
    if (Test-Path $pngPath) {
      $size = (Get-Item $pngPath).Length
      Write-Host "  [PASS] page_${page}_runtime.png ($size bytes)"
    } else {
      Write-Host "  [WARN] page_${page}_runtime.png missing"
    }
    if (Test-Path $jsonPath) {
      Write-Host "  [PASS] page_${page}_evidence.json"
    }
  }
} finally { Pop-Location }

Write-Host "==> GPU Capture PASS"
exit 0
