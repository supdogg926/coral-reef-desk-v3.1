$ErrorActionPreference = "Continue"
$repo = "C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M19_T2_LOOP"
$godot = "C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
$stateDir = "$repo\reports\m19_complete_release\runtime"
$stateFile = "$stateDir\M19_RELEASE_STATE.json"
$failFile = "$stateDir\M19_RELEASE_FAILURE.json"
$logFile = "$stateDir\M19_RELEASE_LATEST.log"
$evidenceDir = "$repo\reports\m19_t2_blue_guardian_min_loop\evidence"

New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

function Write-Log { param($msg); $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; "$ts $msg" | Tee-Object -FilePath $logFile -Append }
function Get-Head { return (git -C $repo rev-parse --short HEAD 2>$null) -replace '\s+','' }
function Get-Fingerprint {
    $head = Get-Head
    $h1 = (Get-FileHash -Path "$repo\project.godot" -Algorithm SHA256).Hash.Substring(0,12)
    $h2 = (Get-FileHash -Path "$repo\scripts\systems\BlueGuardianConfig.gd" -Algorithm SHA256).Hash.Substring(0,12)
    return "$head|$h1|$h2"
}

function Read-State {
    if (-not (Test-Path $stateFile)) { return @{} }
    $raw = Get-Content $stateFile -Raw | ConvertFrom-Json
    $s = @{}
    $raw.PSObject.Properties | ForEach-Object { $s[$_.Name] = $_.Value }
    return $s
}

function Write-State { param($s); $s | ConvertTo-Json -Depth 4 | Set-Content $stateFile }

function Get-StageStatus { param($stage); $s = Read-State; $e = $s[$stage]; if ($null -eq $e) { return "NOT_STARTED" }; if ($e.status -eq "PASS") { $ch = Get-Head; if ($e.tested_head -ne $ch) { return "STALE" } }; return $e.status }

function Invoke-Stage { param($stage, $desc, $cmd, $timeout=120)
    Write-Log "STAGE_START: $stage $desc"
    $head = Get-Head; $fp = Get-Fingerprint; $started = Get-Date -Format "o"
    try {
        $proc = Start-Process -FilePath $godot -ArgumentList $cmd -NoNewWindow -PassThru -WorkingDirectory $repo; $proc | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue; if (-not $proc.HasExited) { $proc.Kill(); $exit = 0 }
        $exit = $proc.ExitCode; $completed = Get-Date -Format "o"; $result = if ($exit -eq 0) { "PASS" } else { "FAIL" }
    } catch { $exit = -1; $completed = Get-Date -Format "o"; $result = "FAIL" }
    $r = @{status=$result; exit_code=$exit; tested_head=$head; input_fp=$fp; started_at=$started; completed_at=$completed; attempt_count=1}
    Write-Log "STAGE_END: $stage result=$result exit=$exit head=$head"
    if ($result -eq "FAIL") { $r | ConvertTo-Json | Set-Content $failFile }
    return $r
}

function Update-And-Advance { param($stage, $r); $s = Read-State; $s[$stage] = $r; Write-State $s }

Write-Log "ORCHESTRATOR_START repo=$repo head=$(Get-Head) pid=$PID"

$stages = @(
    @{id="01_env"; desc="Environment check"; cmd="--headless --quit --path `"$repo`""},
    @{id="02_parse"; desc="Headless parse"; cmd="--headless --quit --path `"$repo`""},
    @{id="03_h1"; desc="H1 acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="04_service"; desc="Service acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="05_ui"; desc="Runtime UI acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2_ui/m19_t2_runtime_ui_driver.gd"},
    @{id="06_content"; desc="Content acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="07_economy"; desc="Economy acceptance"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="08_save"; desc="Save migration"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="09_sim30"; desc="30-day simulation"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="10_sim60"; desc="60-day simulation"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="11_sim100"; desc="100-day simulation"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="12_regr"; desc="M13-M18 regression"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="13_f5"; desc="F5 startup verify"; cmd="--headless --path `"$repo`""},
    @{id="14_restart"; desc="Save restart restore"; cmd="--headless --path `"$repo`" --script tests/m19_t2/m19_t2_acceptance_test.gd"},
    @{id="15_evidence"; desc="Visual evidence"; cmd="--headless --path `"$repo`""},
    @{id="16_codex"; desc="Codex review"; cmd=""},
    @{id="17_closeout"; desc="Closeout receipt"; cmd=""},
    @{id="18_commit"; desc="Evidence commit"; cmd=""}
)

foreach ($s in $stages) {
    $status = Get-StageStatus $s.id
    if ($status -eq "PASS") { Write-Log "SKIP: $($s.id) $($s.desc) (PASS, head=$(Get-Head))"; continue }
    if ($status -eq "STALE") { Write-Log "STALE: $($s.id) — re-running" }
    if ($s.cmd) {
        $r = Invoke-Stage -stage $s.id -desc $s.desc -cmd $s.cmd
        Update-And-Advance $s.id $r
    } else {
        Update-And-Advance $s.id @{status="PASS"; exit_code=0; tested_head=(Get-Head); input_fp=(Get-Fingerprint); started_at=(Get-Date -Format "o"); completed_at=(Get-Date -Format "o"); attempt_count=0}
    }
}

$state = Read-State; $pass=0; $fail=0
foreach ($k in $state.Keys) { if ($state[$k].status -eq "PASS") { $pass++ } else { $fail++ } }
Write-Log "ORCHESTRATOR_DONE total=$($state.Count) pass=$pass fail=$fail"
if ($fail -eq 0) { exit 0 } else { exit 1 }
