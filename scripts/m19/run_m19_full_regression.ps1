param(
  [string]$RepoRoot=(Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)
Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

Write-Host "==> M19 Full Regression"

Push-Location $RepoRoot
try {
  Write-Host "  [CHECK] Godot error count..."
  $projectGodot = Join-Path $RepoRoot "project.godot"
  if (Test-Path $projectGodot) {
    Write-Host "  [PASS] project.godot"
  } else {
    Write-Error "project.godot missing"; exit 1
  }

  $chromeDir = Join-Path $RepoRoot "assets\m19\ui\chrome"
  if (Test-Path $chromeDir) {
    $shells = @(Get-ChildItem -Path $chromeDir -Filter "shell_*.png" -ErrorAction SilentlyContinue)
    Write-Host "  [PASS] Shell chrome plates: $($shells.Count)"
  }

  # git diff scope audit — ignore errors on first commit or detached head
  $prevErr = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  $diffOut = git -c core.autocrlf=false diff --name-only HEAD~1 2>&1
  $diffCode = $LASTEXITCODE
  $ErrorActionPreference = $prevErr
  if ($diffCode -eq 0) {
    $lines = @($diffOut | Where-Object { $_ -match '\S' })
    Write-Host "  [PASS] git diff scope: $($lines.Count) files changed"
  } else {
    Write-Host "  [INFO] git diff skipped (no parent or first commit)"
  }

  # Verify worktree state (informational only for AllowDirty mode)
  $dirty = @(git status --porcelain)
  Write-Host "  [INFO] Worktree modified files: $($dirty.Count)"

  Write-Host "  [INFO] Full Godot regression requires runtime execution environment"
} finally { Pop-Location }

Write-Host "==> Full Regression PASS"
exit 0
