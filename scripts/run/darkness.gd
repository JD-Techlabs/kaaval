class_name Darkness
extends CanvasLayer
## Night overlay with a light circle around the hero, the dawn brightening
## (13:00 -> 15:00) and the Eclipse Beast's blackout.

const SHADER: Shader = preload("res://assets/shaders/darkness.gdshader")
const BLEND_SPEED: float = 2.0
const DAWN_TINT: Color = Color(1.0, 0.62, 0.45)

var _rect: ColorRect
var _dawn_rect: ColorRect
var _material: ShaderMaterial
var _night_strength: float
var _base_radius: float
var _softness: float
var _eclipse_strength: float
var _eclipse_radius: float = 0.0
var _strength: float
var _radius: float


func _ready() -> void:
	layer = 1
	_night_strength = GameData.num("darkness", "night_strength")
	_base_radius = GameData.num("darkness", "light_radius")
	_softness = GameData.num("darkness", "light_softness")
	_eclipse_strength = GameData.num("darkness", "eclipse_strength")
	_strength = _night_strength
	_radius = _base_radius
	_dawn_rect = ColorRect.new()
	_dawn_rect.color = Color(DAWN_TINT, 0.0)
	_dawn_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dawn_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dawn_rect)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _material
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


## radius <= 0 ends the eclipse.
func set_eclipse(radius: float) -> void:
	_eclipse_radius = radius


## 0 = full night, 1 = full dawn.
static func dawn_progress(time: float, dawn_start: float, duration: float) -> float:
	return clampf((time - dawn_start) / maxf(duration - dawn_start, 0.001), 0.0, 1.0)


func step(delta: float, hero_screen_pos: Vector2, dawn: float) -> void:
	var target_strength: float = _night_strength * (1.0 - dawn)
	var target_radius: float = _base_radius
	if _eclipse_radius > 0.0:
		target_strength = _eclipse_strength
		target_radius = _eclipse_radius
	var blend: float = minf(BLEND_SPEED * delta, 1.0)
	_strength = lerpf(_strength, target_strength, blend)
	_radius = lerpf(_radius, target_radius, blend)
	_dawn_rect.color.a = dawn * 0.16 if _eclipse_radius <= 0.0 else 0.0
	_material.set_shader_parameter("rect_size", _rect.size)
	_material.set_shader_parameter("light_pos", hero_screen_pos)
	_material.set_shader_parameter("radius", _radius)
	_material.set_shader_parameter("softness", minf(_softness, _radius * 0.7))
	_material.set_shader_parameter("strength", _strength)
