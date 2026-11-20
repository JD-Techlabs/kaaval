class_name Joystick
extends Control
## Floating one-thumb joystick (spec §4.1): touch anywhere in the lower 70%
## of the screen and it appears under the finger. Release = stop.

const ACTIVE_FROM: float = 0.3
const BASE_RADIUS: float = 120.0
const DEADZONE: float = 0.12

var run: RunManager
var _touch: int = -1
var _origin: Vector2 = Vector2.ZERO
var _radius: float = BASE_RADIUS
var _base: TextureRect
var _knob: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radius = BASE_RADIUS * float(GameState.setting("joystick_size"))
	_base = _make("res://assets/sprites/joy_base.svg", _radius * 2.0)
	_knob = _make("res://assets/sprites/joy_knob.svg", _radius)


func _make(path: String, diameter: float) -> TextureRect:
	var node: TextureRect = UiKit.icon(path, diameter)
	node.size = Vector2(diameter, diameter)
	node.visible = false
	add_child(node)
	return node


func _input(event: InputEvent) -> void:
	if run.mode != RunManager.Mode.PLAYING:
		_release()
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and _touch == -1 and touch.position.y >= size.y * ACTIVE_FROM:
			_touch = touch.index
			_origin = touch.position
			_base.position = _origin - _base.size * 0.5
			_base.visible = true
			_knob.visible = true
			_move(touch.position)
		elif not touch.pressed and touch.index == _touch:
			_release()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _touch:
			_move(drag.position)


func _move(pos: Vector2) -> void:
	var offset: Vector2 = (pos - _origin).limit_length(_radius)
	_knob.position = _origin + offset - _knob.size * 0.5
	var value: Vector2 = offset / _radius
	run.input_dir = value if value.length() >= DEADZONE else Vector2.ZERO


func _release() -> void:
	if _touch == -1 and not _base.visible:
		return
	_touch = -1
	_base.visible = false
	_knob.visible = false
	run.input_dir = Vector2.ZERO
