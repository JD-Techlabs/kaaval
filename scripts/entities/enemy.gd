class_name Enemy
extends Sprite2D
## A pooled creature. No physics body: it moves itself and the EnemyManager
## resolves hits through the spatial grid.

var data: EnemyData
var hp: float = 0.0
var max_hp: float = 0.0
var radius: float = 0.0
var contact_damage: float = 0.0
var speed: float = 0.0
var alive: bool = false
var is_boss: bool = false
var contact_timer: float = 0.0
var flash_timer: float = 0.0
var knockback: Vector2 = Vector2.ZERO
## Set by the crowd pass: another creature is in the way, so advance slowly and queue.
var crowded: bool = false
## XP multiplier from the creature's rank.
var xp_mult: float = 1.0
## Line movers (crows).
var direction: Vector2 = Vector2.ZERO
var travel_left: float = 0.0
## weapon key -> run time of the last hit, for weapons with a per-enemy interval.
var hit_times: Dictionary = {}
var burn_time: float = 0.0
var burn_dps: float = 0.0
var burn_timer: float = 0.0
## Thief state.
var carried_xp: float = 0.0
var state_timer: float = 0.0
var retarget_timer: float = 0.0
var seek_target: Vector2 = Vector2.INF
var fleeing: bool = false


## `rank` is a Roster rank ({} = plain): stronger, bigger, tinted, worth more XP.
func reset(p_data: EnemyData, pos: Vector2, hp_scale: float, dmg_scale: float, rank: Dictionary = {}) -> void:
	data = p_data
	texture = load(data.texture) as Texture2D
	position = pos
	max_hp = data.hp * hp_scale * float(rank.get("hp", 1.0))
	hp = max_hp
	var size: float = float(rank.get("scale", 1.0))
	scale = Vector2(size, size)
	radius = data.radius * size
	contact_damage = data.contact_damage * dmg_scale * float(rank.get("damage", 1.0))
	speed = data.speed * float(rank.get("speed", 1.0))
	xp_mult = float(rank.get("xp", 1.0))
	alive = true
	visible = true
	material = null
	modulate = Color(str(rank.get("tint", "#ffffff")))
	contact_timer = 0.0
	flash_timer = -1.0
	knockback = Vector2.ZERO
	crowded = false
	direction = Vector2.ZERO
	travel_left = 0.0
	hit_times.clear()
	burn_time = 0.0
	carried_xp = 0.0
	state_timer = 0.0
	retarget_timer = 0.0
	seek_target = Vector2.INF
	fleeing = false


func step(delta: float, mgr: EnemyManager) -> void:
	match data.behaviour:
		"line":
			position += direction * speed * delta
			travel_left -= speed * delta
			if travel_left <= 0.0:
				mgr.despawn(self)
		"thief":
			_step_thief(delta, mgr)
		_:
			move_toward_point(mgr.target, delta * (mgr.crowd_speed if crowded else 1.0), mgr.chase_stop(self))
	apply_knockback(delta, mgr.knockback_decay)


## Walks toward a point and stops `stop` short of it (chasers halt at arm's length
## so a crowd forms a ring around the hero instead of one pile on top of them).
func move_toward_point(point: Vector2, delta: float, stop: float = 0.0) -> void:
	var offset: Vector2 = point - position
	var distance: float = offset.length()
	if distance > maxf(stop, 1.0):
		position += offset / distance * minf(speed * delta, distance - stop)
		flip_h = offset.x < 0.0


func apply_knockback(delta: float, decay: float) -> void:
	if knockback != Vector2.ZERO:
		position += knockback * delta
		knockback = knockback.lerp(Vector2.ZERO, minf(decay * delta, 1.0))
		if knockback.length_squared() < 4.0:
			knockback = Vector2.ZERO


func _step_thief(delta: float, mgr: EnemyManager) -> void:
	state_timer += delta
	if fleeing:
		var away: Vector2 = position - mgr.target
		move_toward_point(position + away.normalized() * 200.0, delta)
		if away.length() > mgr.despawn_distance:
			mgr.despawn(self)
		return
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = float(data.params.get("retarget", 0.5))
		seek_target = mgr.run.embers.nearest(position, float(data.params.get("seek_range", 900.0)))
	move_toward_point(seek_target if seek_target != Vector2.INF else mgr.target, delta)
	carried_xp += mgr.run.embers.steal(position, float(data.params.get("steal_radius", 80.0)))
	if state_timer >= float(data.params.get("flee_after", 7.0)):
		fleeing = true
