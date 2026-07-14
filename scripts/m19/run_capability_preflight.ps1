param(
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Write-Host "==> M19 Capability Preflight"

$capPath = Join-Path $RepoRoot "reports\m19\acceptance\CAPABILITIES.json"
if (-not (Test-Path $capPath)) {
  Write-Error "CAPABILITIES.json not found at $capPath"
  exit 1
}

$caps = Get-Content $capPath -Raw | ConvertFrom-Json

$required = @('correct_worktree','git_push','godot_gui_capture','gui_input_automation','runtime_scene_tree_snapshot','asset_sha256_validation','real_ci_access')
foreach ($n in $required) {
  if ($caps.$n -ne $true) {
    Write-Error "CAPABILITY_NOT_VERIFIED [$n]"
    exit 1
  }
  Write-Host "  [PASS] $n = $($caps.$n)"
}

# Verify commit_sha matches current HEAD
Push-Location $RepoRoot
try {
  $head = (git rev-parse HEAD).Trim()
  if ($caps.commit_sha -ne $head) {
    Write-Host "  [WARN] CAPABILITIES commit_sha=$($caps.commit_sha) HEAD=$head — updating"
    $caps.commit_sha = $head
    $caps.verified_at = (Get-Date).ToString('o')
    $caps | ConvertTo-Json -Depth 5 | Set-Content $capPath -Encoding UTF8
  }
} finally { Pop-Location }

Write-Host "==> Preflight PASS"
exit 0
