# MA1 R1: Cross-process save/reload orchestrator (3 rounds)
param([string]$GodotExe="C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe", [string]$RepoPath=".", [string]$Renderer="opengl3")

$ErrorActionPreference="Stop"
$EvidenceDir="reports/m19/ma1/r1/save_reload"
New-Item -ItemType Directory -Force $EvidenceDir | Out-Null

$GodotArgs = @("--path", $RepoPath, "--windowed", "--resolution", "1280x720",
    "--display-driver", "windows", "--rendering-driver", $Renderer, "--audio-driver", "Dummy")

function Run-Godot {
    param([string]$Script, [string]$Args, [int]$Timeout=60)
    $allArgs = $GodotArgs + @("--script", $Script)
    if ($Args) { $allArgs += "--"; $allArgs += $Args.Split(" ") }
    $p = Start-Process -FilePath $GodotExe -ArgumentList $allArgs -PassThru -NoNewWindow -Wait
    return $p.ExitCode
}

# Round 1: Normal state save/restore
Write-Host "=== ROUND 1: Normal State ==="
$r1 = Run-Godot -Script "tests/m19/ma1_r1_save_round.gd" -Args "--acceptance --round 1"
Write-Host "Round 1 exit: $r1"
Start-Sleep -Seconds 2

# Round 2: Mid-voyage save/restore
Write-Host "=== ROUND 2: Mid-Voyage ==="
$r2 = Run-Godot -Script "tests/m19/ma1_r1_save_round.gd" -Args "--acceptance --round 2"
Write-Host "Round 2 exit: $r2"
Start-Sleep -Seconds 2

# Round 3: Post-result save/restore
Write-Host "=== ROUND 3: Post-Result ==="
$r3 = Run-Godot -Script "tests/m19/ma1_r1_save_round.gd" -Args "--acceptance --round 3"
Write-Host "Round 3 exit: $r3"

$allPass = ($r1 -eq 0) -and ($r2 -eq 0) -and ($r3 -eq 0)
Write-Host "SAVE_RELOAD: $($allPass)"
exit $(if ($allPass) { 0 } else { 1 })
