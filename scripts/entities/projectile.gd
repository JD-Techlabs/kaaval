class_name Projectile
extends Sprite2D
## Pooled player projectile. Behaviour is chosen by `kind`.

enum Kind { STRAIGHT, BOOMERANG, SPIRAL }

var active: bool = false
var kind: Kind = Kind.STRAIGHT
var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var pierce: int = 1
var hit_radius: float = 12.0
var life: float = 1.0
var explode_radius: float = 0.0
var spin: float = 0.0
## enemy instance id -> true, so one pass hits each creature once.
var hit: Dictionary = {}
## Boomerang.
var range_left: float = 0.0
var returning: bool = false
## Spiral (polar around the hero).
var angle: float = 0.0
var distance: float = 0.0
var turn_speed: float = 0.0
var out_speed: float = 0.0
var rehit_timer: float = 0.0


func reset(tex: Texture2D, pos: Vector2, p_velocity: Vector2, p_damage: float, p_pierce: int, p_radius: float, p_life: float) -> void:
	texture = tex
	position = pos
	velocity = p_velocity
	damage = p_damage
	pierce = p_pierce
	hit_radius = p_radius
	life = p_life
	kind = Kind.STRAIGHT
	explode_radius = 0.0
	spin = 0.0
	returning = false
	range_left = 0.0
	rehit_timer = 0.0
	rotation = velocity.angle()
	scale = Vector2.ONE
	hit.clear()
	active = true
	visible = true
