extends BaseWeapon
## War Drum: a shockwave around the hero that damages and knocks back.

const WAVE_COLOR: Color = Color(0.95, 0.8, 0.5)


func fire() -> bool:
	var origin: Vector2 = run.player.position
	var radius: float = area("area")
	var hit_damage: float = damage()
	var force: float = stat("knockback")
	for enemy: Enemy in run.enemies.query_circle(origin, radius):
		run.enemies.damage(enemy, hit_damage, (enemy.position - origin).normalized() * force)
	run.fx.ring(origin, radius, WAVE_COLOR, 0.35)
	AudioManager.play("drum")
	return true
