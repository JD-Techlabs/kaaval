extends Node
## Screen transitions with a short fade.

signal screen_changed(screen: String)

const SCREENS: Dictionary = {
	"splash": "res://scenes/main.tscn",
	"home": "res://scenes/home/home.tscn",
	"run": "res://scenes/run/run.tscn",
	"heroes": "res://scenes/ui/heroes.tscn",
	"shop": "res://scenes/ui/shop.tscn",
	"missions": "res://scenes/ui/missions.tscn",
	"settings": "res://scenes/ui/settings.tscn",
}
const FADE_SECONDS: float = 0.12

var current: String = "splash"
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.04, 0.08, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func goto(screen: String) -> void:
	if _busy or not SCREENS.has(screen):
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, FADE_SECONDS)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(str(SCREENS[screen]))
	current = screen
	screen_changed.emit(screen)
	tween = create_tween()
	tween.tween_property(_fade, "color:a", 0.0, FADE_SECONDS)
	await tween.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
