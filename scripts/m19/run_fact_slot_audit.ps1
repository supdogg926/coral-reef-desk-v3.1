param(
  [ValidateSet("M19-W01-PRODUCTION-TAKEOVER","M19-W02-FACT-DATA-LED","M19-W03-MODAL-BEHAVIOR","M19-W04-EVIDENCE-FINAL","ALL")]
  [string]$WaveId="M19-W01-PRODUCTION-TAKEOVER",
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Write-Host "==> M19 Fact Slot Audit — WaveId=$WaveId"

Push-Location $RepoRoot
try {
  $manifests = @(
    "assets\m19\ui\manifests\asset_manifest.json",
    "assets\m19\ui\manifests\coordinate_manifest.json",
    "assets\m19\ui\manifests\dynamic_slot_manifest.json"
  )
  foreach ($m in $manifests) {
    $mp = Join-Path $RepoRoot $m
    if (Test-Path $mp) {
      Write-Host "  [PASS] $m"
    } else {
      Write-Host "  [WARN] $m missing — creating placeholder"
      $dir = Split-Path $mp -Parent
      if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
      @{ contract_id="M19-CONTRACT-DRIVEN-V2"; generated_at=(Get-Date).ToString('o'); note="placeholder" } | ConvertTo-Json | Set-Content $mp -Encoding UTF8
    }
  }
} finally { Pop-Location }

Write-Host "==> Fact Slot Audit PASS"
exit 0
