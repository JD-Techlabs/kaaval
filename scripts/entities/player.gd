class_name Player
extends Node2D
## The guardian. Moves from joystick input; weapons are child nodes.

signal died
signal hp_changed
signal hurt(amount: float)

var stats: PlayerStats
var hp: float = 0.0
var alive: bool = true
var iframes: float = 0.0
## Last non-zero movement direction (spear, whip).
var facing: Vector2 = Vector2.RIGHT
var facing_x: float = 1.0
var sprite: Sprite2D
## Debug/test switch: ignore all damage.
var invulnerable: bool = false

const BAR_SIZE: Vector2 = Vector2(84.0, 10.0)
const BAR_OFFSET_Y: float = 54.0

var _iframe_time: float


func setup(hero: HeroData, tint: Color, p_stats: PlayerStats) -> void:
	stats = p_stats
	hp = stats.max_hp
	_iframe_time = GameData.num("combat", "iframes")
	sprite = Sprite2D.new()
	sprite.texture = load(hero.texture) as Texture2D
	sprite.modulate = tint
	add_child(sprite)
	hp_changed.connect(queue_redraw)


## Small health bar under the hero, so HP is readable without looking away.
func _draw() -> void:
	var origin: Vector2 = Vector2(-BAR_SIZE.x * 0.5, BAR_OFFSET_Y)
	draw_rect(Rect2(origin - Vector2(2.0, 2.0), BAR_SIZE + Vector2(4.0, 4.0)), Color(0.04, 0.05, 0.1, 0.85))
	var ratio: float = clampf(hp / maxf(stats.max_hp, 1.0), 0.0, 1.0)
	var color: Color = Color("6fe08a") if ratio > 0.5 else (Color("ffb347") if ratio > 0.25 else Color("e2553d"))
	draw_rect(Rect2(origin, Vector2(BAR_SIZE.x * ratio, BAR_SIZE.y)), color)


func set_stats(p_stats: PlayerStats) -> void:
	var ratio: float = hp / maxf(stats.max_hp, 1.0)
	stats = p_stats
	hp = minf(stats.max_hp * ratio, stats.max_hp)
	hp_changed.emit()


func step(delta: float, input: Vector2, bounds: Rect2) -> void:
	if not alive:
		return
	if input.length_squared() > 0.0001:
		facing = input.normalized()
		if absf(input.x) > 0.05:
			facing_x = signf(input.x)
			sprite.flip_h = facing_x < 0.0
		position += input.limit_length(1.0) * stats.move_speed * delta
		position = position.clamp(bounds.position, bounds.end)
	if iframes > 0.0:
		iframes -= delta
		sprite.modulate.a = 0.45 if int(iframes * 20.0) % 2 == 0 else 1.0
		if iframes <= 0.0:
			sprite.modulate.a = 1.0
	if stats.hp_regen > 0.0 and hp < stats.max_hp:
		hp = minf(hp + stats.hp_regen * delta, stats.max_hp)
		hp_changed.emit()


## Returns true when damage was applied (not blocked by i-frames).
func take_damage(raw: float) -> bool:
	if not alive or iframes > 0.0 or invulnerable:
		return false
	var amount: float = stats.damage_taken(raw)
	hp -= amount
	iframes = _iframe_time
	hurt.emit(amount)
	hp_changed.emit()
	if hp <= 0.0:
		hp = 0.0
		alive = false
		died.emit()
	return true


func heal(amount: float) -> void:
	hp = minf(hp + amount, stats.max_hp)
	hp_changed.emit()


func revive(hp_fraction: float) -> void:
	alive = true
	hp = stats.max_hp * hp_fraction
	iframes = _iframe_time * 4.0
	hp_changed.emit()
