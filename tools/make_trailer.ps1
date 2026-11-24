# Records the Google Play preview video (portrait 1080x1920, 30 fps, with game
# music and sound) to build\trailer\kavaryn_trailer.avi using Godot's Movie Maker.
# The scenes, captions and timing are scripted in tools\trailer_director.gd and
# play on a throwaway demo profile; your own save is not touched.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\make_trailer.ps1
# Then upload the .avi to YouTube (Public or Unlisted, ads off) and paste the
# link into Play Console -> Main store listing -> Video.

param(
    [string]$Godot = ".tools\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Out = "build\trailer\kavaryn_trailer.avi"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null

# Movie Maker records the window, and Windows shrinks the window to fit the
# screen. With "viewport" stretch from startup Godot renders at the full
# 1080x1920 design size and records that instead. override.cfg applies these
# settings to this run only; it is deleted again below.
$override = @"
[display]

window/stretch/mode="viewport"

[editor]

movie_writer/mjpeg_quality=0.9
"@
Set-Content -Path override.cfg -Value $override -Encoding ascii
try {
    Write-Host "Recording (takes a minute or two; a game window opens)..."
    & $Godot --path . --fixed-fps 30 --write-movie $Out res://tools/trailer.tscn -- --demo-profile
} finally {
    Remove-Item override.cfg -ErrorAction SilentlyContinue
}
$size = [math]::Round((Get-Item $Out).Length / 1MB)
Write-Host "Done: $Out ($size MB)"
