extends BaseWeapon
## Valari: thrown at the nearest creature, returns, hits on both passes.
## Twin Valari Storm: valaris spiral outward continuously.

const SPIN: float = 18.0
const PIERCE_ALL: int = 9999
const BOOMERANG_LIFE: float = 6.0

var _spiral_angle: float = 0.0


func fire() -> bool:
	var amount: int = int(stat("projectiles"))
	var origin: Vector2 = run.player.position
	var texture: Texture2D = tex("valari")
	if stat("spiral") > 0.0:
		_spiral_angle += 0.9
		for i: int in amount:
			var projectile: Projectile = run.projectiles.fire(texture, origin, Vector2.ZERO, damage(),
				PIERCE_ALL, area("radius"), stat("spiral_life"))
			projectile.kind = Projectile.Kind.SPIRAL
			projectile.angle = _spiral_angle + TAU * float(i) / float(amount)
			projectile.distance = 30.0
			projectile.turn_speed = stat("spiral_turn")
			projectile.out_speed = stat("spiral_out")
			projectile.spin = SPIN
		return true
	var targets: Array[Enemy] = run.enemies.nearest(origin, stat("range") * 1.6, amount)
	if targets.is_empty():
		return false
	for i: int in amount:
		var target: Enemy = targets[i % targets.size()]
		var direction: Vector2 = (target.position - origin).normalized().rotated(0.35 * float(i / maxi(targets.size(), 1)))
		var projectile: Projectile = run.projectiles.fire(texture, origin, direction * stat("speed"), damage(),
			PIERCE_ALL, area("radius"), BOOMERANG_LIFE)
		projectile.kind = Projectile.Kind.BOOMERANG
		projectile.range_left = stat("range")
		projectile.spin = SPIN
	AudioManager.play("whoosh", 1.0)
	return true
