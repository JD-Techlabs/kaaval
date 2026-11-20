class_name EnemyManager
extends Node2D
## Owns every creature: pooling, movement, the spatial grid, contact damage,
## damage/death. Other systems listen to its signals.

signal enemy_died(data: EnemyData, position: Vector2, carried_xp: float)
signal boss_spawned(boss: Enemy)
signal boss_died(boss: Enemy)

const FLASH_SHADER: Shader = preload("res://assets/shaders/hit_flash.gdshader")
## Grid queries are padded by this so large creatures in neighbouring cells are found.
const MAX_ENEMY_RADIUS: float = 48.0
## Minimum dark time between hit flashes, so creatures under constant fire stay readable.
const FLASH_GAP: float = 0.12

var run: RunManager
var grid: SpatialGrid
var active: Array[Enemy] = []
var bosses: Array[Enemy] = []
var target: Vector2 = Vector2.ZERO
var knockback_decay: float = 7.0
var despawn_distance: float = 2800.0
## Share of its speed a chaser keeps while another creature blocks its way.
var crowd_speed: float = 0.25
## Roster rank of ordinary creatures; the run raises it as the hero levels up.
var base_rank: int = 0

var _pool: Array[Enemy] = []
var _flash_material: ShaderMaterial
var _scratch: Array = []
var _frame: int = 0
var _contact_interval: float
var _flash_time: float
var _burn_tick: float
var _player_radius: float
var _separation_push: float
var _separation_overlap: float
var _separation_every: int
var _chase_stop: float


func setup(p_run: RunManager, map_size: Vector2) -> void:
	run = p_run
	grid = SpatialGrid.new(map_size, GameData.num("spawn", "cell_size"))
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = FLASH_SHADER
	_contact_interval = GameData.num("combat", "contact_interval")
	_flash_time = GameData.num("combat", "hit_flash")
	_burn_tick = GameData.num("combat", "burn_tick")
	_player_radius = GameData.num("combat", "player_radius")
	knockback_decay = GameData.num("combat", "knockback_decay")
	_separation_push = GameData.num("spawn", "separation_push")
	_separation_overlap = GameData.num("spawn", "separation_overlap")
	_chase_stop = GameData.num("combat", "chase_stop")
	crowd_speed = GameData.num("spawn", "crowd_speed")
	_separation_every = maxi(int(GameData.num("spawn", "separation_every")), 1)


func count() -> int:
	return active.size()


## Room left under the simultaneous-enemy cap (spec §7.2, remote config).
func room() -> int:
	return maxi(int(RemoteConfig.num("max_enemies")) - active.size(), 0)


## `rank` < 0 means the current base rank.
func spawn(data: EnemyData, pos: Vector2, rank: int = -1) -> Enemy:
	var enemy: Enemy
	if _pool.is_empty():
		enemy = Enemy.new()
		add_child(enemy)
	else:
		enemy = _pool.pop_back()
	enemy.reset(data, pos, run.hp_scale(), run.dmg_scale(), Roster.rank(rank if rank >= 0 else base_rank))
	active.append(enemy)
	return enemy


func spawn_boss(data: BossData, pos: Vector2) -> Enemy:
	var boss: Enemy = (load(data.script_path) as GDScript).new()
	add_child(boss)
	boss.reset(data, pos, 1.0, run.dmg_scale())
	boss.scale = Vector2.ONE
	boss.is_boss = true
	boss.z_index = 1
	active.append(boss)
	bosses.append(boss)
	boss_spawned.emit(boss)
	return boss


func spawn_around(data: EnemyData, center: Vector2, amount: int, distance: float) -> void:
	var allowed: int = mini(amount, room())
	for i: int in allowed:
		var angle: float = TAU * float(i) / float(allowed)
		spawn(data, run.clamp_to_map(center + Vector2.from_angle(angle) * distance))


func step(delta: float) -> void:
	_frame += 1
	target = run.player.position
	for i: int in range(active.size() - 1, -1, -1):
		if not active[i].alive:
			_retire(i)
	grid.clear()
	var player_alive: bool = run.player.alive
	for i: int in active.size():
		var enemy: Enemy = active[i]
		if not enemy.alive:
			continue
		enemy.step(delta, self)
		if not enemy.alive:
			continue
		_tick_effects(enemy, delta)
		if not enemy.alive:
			continue
		if not enemy.is_boss:
			grid.insert(enemy, enemy.position)
		var offset: Vector2 = enemy.position - target
		enemy.contact_timer -= delta
		if player_alive and enemy.contact_damage > 0.0 and enemy.contact_timer <= 0.0:
			var reach: float = enemy.radius + _player_radius
			if offset.length_squared() < reach * reach:
				enemy.contact_timer = _contact_interval
				run.player.take_damage(enemy.contact_damage)
		if data_is_chaser(enemy) and offset.length_squared() > despawn_distance * despawn_distance:
			enemy.position = run.random_ring_point()
	# Spread the crowd once the grid holds everyone, a share of the creatures per step.
	for i: int in active.size():
		var enemy: Enemy = active[i]
		if (i + _frame) % _separation_every == 0 and enemy.alive and not enemy.is_boss:
			_separate(enemy, delta * float(_separation_every))


## How close a chaser walks to the hero: a share of touching distance, so it still lands hits.
func chase_stop(enemy: Enemy) -> float:
	return (enemy.radius + _player_radius) * _chase_stop


static func data_is_chaser(enemy: Enemy) -> bool:
	return enemy.data.behaviour == "chase"


func _tick_effects(enemy: Enemy, delta: float) -> void:
	if enemy.flash_timer > -FLASH_GAP:
		var was_lit: bool = enemy.flash_timer > 0.0
		enemy.flash_timer -= delta
		if was_lit and enemy.flash_timer <= 0.0:
			enemy.material = null
	if enemy.burn_time > 0.0:
		enemy.burn_time -= delta
		enemy.burn_timer -= delta
		if enemy.burn_timer <= 0.0:
			enemy.burn_timer = _burn_tick
			damage(enemy, enemy.burn_dps * _burn_tick)


## Crowd spreading: step back half of each overlap with the neighbours in this
## cell and the ones around it (capped per step), so packs fan out and can be counted.
func _separate(enemy: Enemy, delta: float) -> void:
	_scratch.clear()
	grid.query(enemy.position, enemy.radius + MAX_ENEMY_RADIUS, _scratch)
	var push: Vector2 = Vector2.ZERO
	var own_dist: float = enemy.position.distance_squared_to(target)
	var blocked: bool = false
	for other: Enemy in _scratch:
		if other == enemy or not other.alive:
			continue
		var offset: Vector2 = enemy.position - other.position
		var reach: float = (enemy.radius + other.radius) * _separation_overlap
		var dist_sq: float = offset.length_squared()
		if dist_sq >= reach * reach:
			continue
		blocked = blocked or other.position.distance_squared_to(target) < own_dist
		if dist_sq > 0.01:
			var dist: float = sqrt(dist_sq)
			push += offset / dist * (reach - dist) * 0.5
		else:
			push += Vector2.from_angle(float(_frame + enemy.get_index())) * reach * 0.5
	enemy.crowded = blocked
	if push != Vector2.ZERO:
		enemy.position += push.limit_length(_separation_push * delta)


func _retire(index: int) -> void:
	var enemy: Enemy = active[index]
	active[index] = active[active.size() - 1]
	active.pop_back()
	if enemy.is_boss:
		bosses.erase(enemy)
		enemy.queue_free()
	else:
		_pool.append(enemy)


func query_circle(center: Vector2, radius: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	_scratch.clear()
	grid.query(center, radius + MAX_ENEMY_RADIUS, _scratch)
	for enemy: Enemy in _scratch:
		if enemy.alive:
			var reach: float = radius + enemy.radius
			if enemy.position.distance_squared_to(center) <= reach * reach:
				out.append(enemy)
	for boss: Enemy in bosses:
		if boss.alive:
			var reach: float = radius + boss.radius
			if boss.position.distance_squared_to(center) <= reach * reach:
				out.append(boss)
	return out


## Up to `amount` closest living creatures within range, nearest first.
func nearest(pos: Vector2, max_range: float, amount: int = 1) -> Array[Enemy]:
	var found: Array[Enemy] = []
	var dists: Array[float] = []
	var limit: float = max_range * max_range
	for enemy: Enemy in active:
		if not enemy.alive:
			continue
		var dist: float = enemy.position.distance_squared_to(pos)
		if dist > limit:
			continue
		var at: int = dists.bsearch(dist)
		if at < amount:
			dists.insert(at, dist)
			found.insert(at, enemy)
			if found.size() > amount:
				found.pop_back()
				dists.pop_back()
	return found


func random_in_rect(rect: Rect2, rng: RandomNumberGenerator) -> Enemy:
	var candidates: Array[Enemy] = []
	for enemy: Enemy in active:
		if enemy.alive and rect.has_point(enemy.position):
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	return candidates[rng.randi() % candidates.size()]


## Returns true when the hit killed the creature.
func damage(enemy: Enemy, amount: float, knock: Vector2 = Vector2.ZERO) -> bool:
	if not enemy.alive or amount <= 0.0:
		return false
	enemy.hp -= amount
	if enemy.flash_timer <= -FLASH_GAP:
		enemy.flash_timer = _flash_time
		enemy.material = _flash_material
	if not enemy.is_boss:
		enemy.knockback += knock
	run.numbers.show_number(enemy.position, amount)
	run.on_enemy_hit(enemy)
	if enemy.hp <= 0.0:
		kill(enemy)
		return true
	return false


func kill(enemy: Enemy) -> void:
	if not enemy.alive:
		return
	enemy.alive = false
	enemy.visible = false
	var data: EnemyData = enemy.data
	if not data.split_id.is_empty():
		var child: EnemyData = GameData.enemy(data.split_id)
		for i: int in mini(data.split_count, room()):
			var offset: Vector2 = Vector2.from_angle(TAU * float(i) / float(data.split_count)) * enemy.radius
			spawn(child, enemy.position + offset)
	enemy_died.emit(data, enemy.position, enemy.carried_xp + data.xp * (enemy.xp_mult - 1.0))
	if enemy.is_boss:
		boss_died.emit(enemy)


## Removes a creature without counting it as a kill.
func despawn(enemy: Enemy) -> void:
	enemy.alive = false
	enemy.visible = false


## Kills every regular creature in a circle (used by revive).
func clear_around(center: Vector2, radius: float) -> void:
	for enemy: Enemy in query_circle(center, radius):
		if not enemy.is_boss:
			kill(enemy)
