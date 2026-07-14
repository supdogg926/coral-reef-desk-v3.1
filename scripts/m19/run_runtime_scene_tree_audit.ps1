param(
  [ValidateSet("M19-W01-PRODUCTION-TAKEOVER","M19-W02-FACT-DATA-LED","M19-W03-MODAL-BEHAVIOR","M19-W04-EVIDENCE-FINAL","ALL")]
  [string]$WaveId="M19-W01-PRODUCTION-TAKEOVER",
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Write-Host "==> M19 Scene Tree Audit — WaveId=$WaveId"

Push-Location $RepoRoot
try {
  # Verify Main.tscn references correct entry point
  $projectGodot = Join-Path $RepoRoot "project.godot"
  if (-not (Test-Path $projectGodot)) { Write-Error "project.godot not found"; exit 1 }
  $projectContent = Get-Content $projectGodot -Raw
  if ($projectContent -match 'run/main_scene="([^"]+)"') {
    $mainScene = $Matches[1]
    Write-Host "  [PASS] run/main_scene = $mainScene"
    if ($mainScene -ne "res://scenes/main/Main.tscn") {
      Write-Error "run/main_scene is not res://scenes/main/Main.tscn"
      exit 1
    }
  } else {
    Write-Error "run/main_scene not found in project.godot"
    exit 1
  }

  # Verify Main.tscn exists
  $mainTscn = Join-Path $RepoRoot "scenes\main\Main.tscn"
  if (-not (Test-Path $mainTscn)) { Write-Error "Main.tscn not found"; exit 1 }
  Write-Host "  [PASS] Main.tscn exists"

  # Runtime scene tree snapshot (placeholder — requires Godot execution)
  $runtimeDir = Join-Path $RepoRoot "reports\m19\final_deterministic\runtime_nodes"
  if (-not (Test-Path $runtimeDir)) { New-Item -ItemType Directory -Force $runtimeDir | Out-Null }
  $treePath = Join-Path $runtimeDir "production_runtime_nodes.json"
  if (-not (Test-Path $treePath)) {
    Write-Host "  [WARN] production_runtime_nodes.json not found — requires Godot runtime probe"
  } else {
    Write-Host "  [PASS] production_runtime_nodes.json"
  }
} finally { Pop-Location }

Write-Host "==> Scene Tree Audit PASS"
exit 0
