# Produces every Google Play graphic into docs\store\graphics:
#   icon_512.png, feature_graphic.png and five 9:16 phone screenshots.
# Screenshots use a throwaway demo profile; your own save is not touched.
# They are saved at 1080x1920 whatever the window size.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\store_graphics.ps1

param(
    [string]$Godot = ".tools\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Resolution = "486x864"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$out = "docs\store\graphics"
New-Item -ItemType Directory -Force $out | Out-Null
# Keep Godot from importing these PNGs into the game.
if (-not (Test-Path "$out\.gdignore")) { New-Item -ItemType File "$out\.gdignore" | Out-Null }

Write-Host "Icons..."
& $Godot --headless --path . -s tools/gen_icons.gd

Write-Host "Feature graphic..."
& $Godot --path . res://tools/feature_graphic.tscn -- --out=docs/store/graphics/feature_graphic.png

# name, screen, seconds of the night to skip first
$shots = @(
    @("screenshot_1_village", "home", 0),
    @("screenshot_2_night", "run", 95),
    @("screenshot_3_swarm", "run", 230),
    @("screenshot_4_boss", "run", 318),
    @("screenshot_5_missions", "missions", 0)
)
foreach ($shot in $shots) {
    $file = Join-Path (Resolve-Path $out) ($shot[0] + ".png")
    Write-Host "Screenshot $($shot[0])..."
    & $Godot --path . --resolution $Resolution -- --screenshot-mode --demo-profile "--goto=$($shot[1])" "--skip=$($shot[2])" --shot-delay=1.5 "--shot=$file"
}
Write-Host "Done: $out"
