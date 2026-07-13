# D004: Legacy visual nodes and placeholder audit
$ProjectRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
Push-Location $ProjectRoot
# Check Main.gd hides legacy nodes
$mg = Get-Content "scenes/main/Main.gd" -Raw
if ($mg -notmatch "visible = false") { Write-Error "D004 FAIL: No legacy node hiding in Main.gd"; Pop-Location; exit 1 }
# Check world code has no ColorRect placeholders
$worldFiles = @("M19MainInterfaceHybrid.gd")
foreach ($wf in $worldFiles) {
    $path = "scenes/ui/$wf"
    if (Test-Path $path) {
        $c = Get-Content $path -Raw
        # Count only world/debug ColorRects, not style ones in SharedTheme
        $lines = (Get-Content $path | Select-String "ColorRect.new()")
        foreach ($l in $lines) {
            if ($l -notmatch "SharedTheme|make_progress|style") {
                Write-Error "D004 FAIL: ColorRect placeholder in $wf`: $($l.Line.Trim())"
                Pop-Location; exit 1
            }
        }
    }
}
Write-Host "D004 PASS: Legacy nodes hidden, no world ColorRect placeholders"
Pop-Location; exit 0
