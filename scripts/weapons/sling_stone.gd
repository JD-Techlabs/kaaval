extends BaseWeapon
## Sling Stone / Meteor Sling: stones at the nearest creatures.

const SPREAD_RADIANS: float = 0.16
const SPIN: float = 10.0


func fire() -> bool:
	var amount: int = int(stat("projectiles"))
	var origin: Vector2 = run.player.position
	var targets: Array[Enemy] = run.enemies.nearest(origin, stat("range"), amount)
	if targets.is_empty():
		return false
	var texture: Texture2D = tex("meteor" if evolution != null else "stone")
	for i: int in amount:
		var target: Enemy = targets[i % targets.size()]
		var direction: Vector2 = (target.position - origin).normalized()
		if i >= targets.size():
			direction = direction.rotated(SPREAD_RADIANS * float(i - targets.size() + 1))
		var projectile: Projectile = run.projectiles.fire(texture, origin, direction * stat("speed"),
			damage(), int(stat("pierce")), stat("radius"), stat("life"))
		projectile.explode_radius = area("explode_radius")
		projectile.spin = SPIN
	AudioManager.play("whoosh", 1.2)
	return true
