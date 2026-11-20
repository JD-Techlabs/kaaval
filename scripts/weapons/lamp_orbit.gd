extends BaseWeapon
## Lamp Orbit / Ring of Dawn: flames circle the hero and hit on touch.

var _flames: Array[Sprite2D] = []
var _angle: float = 0.0


func refresh() -> void:
	var amount: int = int(stat("flames"))
	while _flames.size() < amount:
		var flame: Sprite2D = Sprite2D.new()
		flame.texture = tex("flame")
		add_child(flame)
		_flames.append(flame)
	while _flames.size() > amount:
		var extra: Sprite2D = _flames.pop_back()
		extra.queue_free()


func step(delta: float) -> void:
	_angle = fmod(_angle + stat("rot_speed") * delta, TAU)
	var orbit: float = area("radius")
	var reach: float = area("flame_radius")
	var interval: float = stat("hit_interval")
	var burn_time: float = stat("burn_time")
	var hit_damage: float = damage()
	for i: int in _flames.size():
		var offset: Vector2 = Vector2.from_angle(_angle + TAU * float(i) / float(_flames.size())) * orbit
		_flames[i].position = offset
		for enemy: Enemy in run.enemies.query_circle(run.player.position + offset, reach):
			if can_hit(enemy, interval):
				if burn_time > 0.0:
					enemy.burn_time = burn_time
					enemy.burn_dps = stat("burn_dps") * run.player.stats.damage_mult
				run.enemies.damage(enemy, hit_damage)
