class_name DamageNumbers
extends Node2D
## Pooled floating damage numbers (toggle in settings).

const POOL_SIZE: int = 48
const LIFE_SECONDS: float = 0.55
const RISE_SPEED: float = 90.0

var enabled: bool = true
var _labels: Array[Label] = []
var _life: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0


func _ready() -> void:
	enabled = bool(GameState.setting("damage_numbers"))
	_life.resize(POOL_SIZE)
	for i: int in POOL_SIZE:
		var label: Label = Label.new()
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
		label.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.18))
		label.add_theme_constant_override("outline_size", 8)
		label.visible = false
		add_child(label)
		_labels.append(label)
		_life[i] = 0.0


func show_number(pos: Vector2, amount: float) -> void:
	if not enabled:
		return
	var label: Label = _labels[_next]
	_life[_next] = LIFE_SECONDS
	_next = (_next + 1) % POOL_SIZE
	label.text = str(maxi(roundi(amount), 1))
	label.position = pos + Vector2(-18.0, -52.0)
	label.modulate.a = 1.0
	label.visible = true


func step(delta: float) -> void:
	for i: int in POOL_SIZE:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		var label: Label = _labels[i]
		if _life[i] <= 0.0:
			label.visible = false
		else:
			label.position.y -= RISE_SPEED * delta
			label.modulate.a = minf(_life[i] / (LIFE_SECONDS * 0.5), 1.0)
