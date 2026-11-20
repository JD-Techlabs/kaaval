class_name ProjectilePool
extends Node2D
## Pools and simulates all player projectiles (budget: spec §13).

const MAX_PROJECTILES: int = 200
const SPIRAL_REHIT_SECONDS: float = 0.5
const RETURN_CATCH_DISTANCE: float = 40.0

var run: RunManager
var active: Array[Projectile] = []
var _pool: Array[Projectile] = []


func count() -> int:
	return active.size()


func fire(tex: Texture2D, pos: Vector2, velocity: Vector2, damage: float, pierce: int, radius: float, life: float) -> Projectile:
	var projectile: Projectile
	if active.size() >= MAX_PROJECTILES:
		projectile = active.pop_front()
	elif _pool.is_empty():
		projectile = Projectile.new()
		add_child(projectile)
	else:
		projectile = _pool.pop_back()
	projectile.reset(tex, pos, velocity, damage, pierce, radius, life)
	active.append(projectile)
	return projectile


func step(delta: float) -> void:
	for i: int in range(active.size() - 1, -1, -1):
		var projectile: Projectile = active[i]
		_move(projectile, delta)
		if projectile.active:
			_hit(projectile)
		if not projectile.active:
			projectile.visible = false
			active.remove_at(i)
			_pool.append(projectile)


func _move(p: Projectile, delta: float) -> void:
	p.life -= delta
	if p.life <= 0.0:
		p.active = false
		return
	match p.kind:
		Projectile.Kind.STRAIGHT:
			p.position += p.velocity * delta
		Projectile.Kind.BOOMERANG:
			var speed: float = p.velocity.length()
			if p.returning:
				var to_hero: Vector2 = run.player.position - p.position
				if to_hero.length() < RETURN_CATCH_DISTANCE:
					p.active = false
					return
				p.velocity = to_hero.normalized() * speed
			else:
				p.range_left -= speed * delta
				if p.range_left <= 0.0:
					p.returning = true
					p.hit.clear()
			p.position += p.velocity * delta
		Projectile.Kind.SPIRAL:
			p.angle += p.turn_speed * delta
			p.distance += p.out_speed * delta
			p.position = run.player.position + Vector2.from_angle(p.angle) * p.distance
			p.rehit_timer += delta
			if p.rehit_timer >= SPIRAL_REHIT_SECONDS:
				p.rehit_timer = 0.0
				p.hit.clear()
	if p.spin != 0.0:
		p.rotation += p.spin * delta


func _hit(p: Projectile) -> void:
	for enemy: Enemy in run.enemies.query_circle(p.position, p.hit_radius):
		var key: int = enemy.get_instance_id()
		if p.hit.has(key):
			continue
		p.hit[key] = true
		if p.explode_radius > 0.0:
			run.fx.ring(p.position, p.explode_radius, Color(1.0, 0.6, 0.2))
			AudioManager.play("explode")
			for other: Enemy in run.enemies.query_circle(p.position, p.explode_radius):
				run.enemies.damage(other, p.damage)
		else:
			run.enemies.damage(enemy, p.damage)
		p.pierce -= 1
		if p.pierce <= 0:
			p.active = false
			return
