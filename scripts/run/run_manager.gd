class_name RunManager
extends Node2D
## One night. Builds the world, steps every system in a fixed order from
## advance(), and owns the run's flow (level-ups, bosses, death, dawn).
## Never writes to GameState: the results screen commits the summary.

signal levelup_requested(cards: Array[Dictionary])
signal chest_opened(lines: Array[Dictionary])
signal revive_offered
signal run_ended(summary: Dictionary)
signal boss_changed(boss: Enemy)
signal banner_requested(text: String)
signal build_changed
signal hint_requested(index: int)
signal notice_requested(text: String)

enum Mode { PLAYING, CHOOSING, CHEST, PAUSED, REVIVE, ENDED }

var state: RunState = RunState.new()
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wave: WaveData
var age: AgeData
var hero: HeroData
var mode: Mode = Mode.PLAYING
## Set by the joystick each frame.
var input_dir: Vector2 = Vector2.ZERO
var weapon_nodes: Dictionary = {}

var player: Player
var enemies: EnemyManager
var projectiles: ProjectilePool
var embers: EmberField
var hazards: Hazards
var potions: Potions
var fx: Fx
var strikes: StrikeCaller
var numbers: DamageNumbers
var darkness: Darkness
var camera: Camera2D
## Screen size in UI pixels, and the part of the world the camera shows (screen / zoom).
var screen_size: Vector2 = Vector2(1080, 1920)
var view_size: Vector2 = Vector2(1080, 1920)
var zoom: float = 1.0

var _spawner: Spawner
var _events: RunEvents
var _pending_levels: int = 0
var _died: bool = false
var _bounds: Rect2
var _shake: float = 0.0
var _combo: int = 0
var _combo_timer: float = 0.0
var _dawn_started: bool = false
var _hints_on: bool = false
var _hint_step: int = 0


func _ready() -> void:
	rng.randomize()
	hero = GameData.hero(str(GameState.p["selected_hero"]))
	wave = NightLogic.selected()
	age = AgeLogic.current()
	_build_world()
	state.hero_id = hero.id
	state.night_id = wave.id
	state.age_id = age.id
	state.weapon_slots = player.stats.weapon_slots
	state.passive_slots = player.stats.passive_slots
	state.rerolls_left = int(GameData.num("run", "free_rerolls"))
	for building: BuildingData in GameData.buildings():
		state.rerolls_left += building.rerolls_at(GameState.building_level(building.id))
	apply_card({"kind": "weapon", "id": hero.starting_weapon, "level": 1})
	strikes.setup(self, WeaponLine.strikes(hero.id, age.id))
	_hints_on = not bool(GameState.p["hints_done"])
	AudioManager.play_music("music_night")
	Analytics.log_event("run_start", {"hero": hero.id, "night": wave.id})
	_request_hint(1)


func _build_world() -> void:
	var map: MapView = MapView.new()
	add_child(map)
	map.setup(wave)
	embers = EmberField.new()
	add_child(embers)
	hazards = Hazards.new()
	hazards.run = self
	add_child(hazards)
	potions = Potions.new()
	potions.run = self
	add_child(potions)
	potions.collected.connect(_on_potion_collected)
	enemies = EnemyManager.new()
	add_child(enemies)
	enemies.setup(self, wave.map_size)
	enemies.enemy_died.connect(_on_enemy_died)
	enemies.boss_spawned.connect(_on_boss_spawned)
	enemies.boss_died.connect(_on_boss_died)
	player = Player.new()
	add_child(player)
	var skin: Dictionary = GameState.selected_skin(hero.id)
	player.setup(hero, Color(str(skin.get("tint", "#ffffff"))), _compute_stats())
	player.position = wave.map_size * 0.5
	player.died.connect(func() -> void: _died = true)
	player.hurt.connect(_on_player_hurt)
	projectiles = ProjectilePool.new()
	projectiles.run = self
	add_child(projectiles)
	strikes = StrikeCaller.new()
	add_child(strikes)
	fx = Fx.new()
	add_child(fx)
	numbers = DamageNumbers.new()
	add_child(numbers)
	camera = Camera2D.new()
	add_child(camera)
	camera.position = player.position
	zoom = GameData.num("run", "camera_zoom")
	camera.zoom = Vector2(zoom, zoom)
	camera.make_current()
	_set_screen_size(screen_size)
	darkness = Darkness.new()
	add_child(darkness)
	_spawner = Spawner.new(wave)
	_events = RunEvents.new(self)
	_warm_up()
	var inset: float = GameData.num("run", "wall_inset")
	_bounds = Rect2(Vector2(inset, inset), wave.map_size - Vector2(inset, inset) * 2.0)


## Loads everything a run can show up front, so nothing hitches mid-fight.
func _warm_up() -> void:
	for enemy: EnemyData in GameData.enemies():
		load(enemy.texture)
		if enemy is BossData:
			load((enemy as BossData).script_path)
	for weapon: WeaponData in GameData.weapons():
		load(weapon.script_path)
		load(weapon.icon)
	for passive: PassiveData in GameData.passives():
		load(passive.icon)
	for sprite: String in ["stone", "meteor", "flame", "spear", "valari", "chest", "tank", "jet", "shell", "missile"]:
		BaseWeapon.tex(sprite)
	var line_weapon: WeaponData = WeaponLine.weapon_for(hero.starting_weapon, hero.id, age.id)
	load(line_weapon.icon)
	if not line_weapon.sprite.is_empty():
		load(line_weapon.sprite)
	load(Potions.TEXTURE)


func _compute_stats() -> PlayerStats:
	return PlayerStats.compute(hero, GameState.building_levels(), state.passives)


func _process(delta: float) -> void:
	_set_screen_size(get_viewport_rect().size)
	if mode == Mode.PLAYING:
		advance(delta)


func _set_screen_size(size: Vector2) -> void:
	screen_size = size
	view_size = size / zoom
	enemies.despawn_distance = GameData.num("spawn", "despawn_screens") * maxf(view_size.x, view_size.y)


## World position -> position on screen in UI pixels.
func to_screen(world_pos: Vector2) -> Vector2:
	return screen_size * 0.5 + (world_pos - camera.position) * zoom


func chest_positions() -> Array[Vector2]:
	return _events.chest_positions()


## One simulation step. Public so tests can drive a run without rendering.
func advance(delta: float) -> void:
	state.time += delta
	var keys: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player.step(delta, input_dir if input_dir != Vector2.ZERO else keys, _bounds)
	for weapon: BaseWeapon in weapon_nodes.values():
		weapon.step(delta)
	strikes.step(delta)
	enemies.base_rank = Roster.base_rank(state.level)
	for request: Dictionary in _spawner.step(delta, state.time, rng):
		_events.execute(request)
	_events.step(delta)
	enemies.step(delta)
	projectiles.step(delta)
	hazards.step(delta)
	potions.step(delta)
	_collect(embers.step(delta, player.position, player.stats.pickup_radius), delta)
	fx.step(delta)
	numbers.step(delta)
	_update_view(delta)
	if mode != Mode.PLAYING:
		return
	if state.time >= wave.duration:
		_finish(true)
	elif _died:
		_died = false
		_on_player_died()
	elif _pending_levels > 0:
		mode = Mode.CHOOSING
		_request_hint(3)
		levelup_requested.emit(LevelupRoller.roll(state, rng))


func _update_view(delta: float) -> void:
	_shake = maxf(_shake - 60.0 * delta, 0.0)
	camera.position = player.position + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * _shake
	var dawn_start: float = GameData.num("run", "dawn_start")
	var dawn: float = Darkness.dawn_progress(state.time, dawn_start, wave.duration)
	darkness.step(delta, to_screen(player.position), dawn)
	if dawn > 0.0 and not _dawn_started:
		_dawn_started = true
		AudioManager.play_music("music_dawn")


# --- helpers used by weapons / enemies ------------------------------------

func hp_scale() -> float:
	return (1.0 + RemoteConfig.num("enemy_hp_scale_per_min") * state.time / 60.0) * wave.enemy_hp_mult * age.enemy_hp_mult


func dmg_scale() -> float:
	return (1.0 + RemoteConfig.num("enemy_dmg_scale_per_min") * state.time / 60.0) * early_damage_mult(state.time) 		* wave.enemy_dmg_mult * age.enemy_dmg_mult


## Coin multiplier for this night: village and hero bonuses times the night's own bonus.
func coin_mult() -> float:
	return player.stats.coin_mult * wave.coin_mult


## Creatures hit softer at the start of a night and reach full strength once the ramp ends.
static func early_damage_mult(time: float) -> float:
	var ramp: float = GameData.num("run", "early_ramp_seconds")
	return lerpf(GameData.num("run", "early_damage_mult"), 1.0, clampf(time / maxf(ramp, 1.0), 0.0, 1.0))


func view_rect() -> Rect2:
	return Rect2(player.position - view_size * 0.5, view_size)


func clamp_to_map(pos: Vector2) -> Vector2:
	return pos.clamp(Vector2.ZERO, wave.map_size)


## A point just outside the camera view (spec §7.2), kept on the map.
func random_ring_point() -> Vector2:
	var rect: Rect2 = view_rect().grow(GameData.num("spawn", "ring_margin"))
	var view: Rect2 = view_rect()
	var point: Vector2 = rect.position
	for attempt: int in 6:
		var along: float = rng.randf() * (rect.size.x + rect.size.y) * 2.0
		if along < rect.size.x:
			point = rect.position + Vector2(along, 0.0)
		elif along < rect.size.x + rect.size.y:
			point = rect.position + Vector2(rect.size.x, along - rect.size.x)
		elif along < rect.size.x * 2.0 + rect.size.y:
			point = rect.position + Vector2(along - rect.size.x - rect.size.y, rect.size.y)
		else:
			point = rect.position + Vector2(0.0, along - rect.size.x * 2.0 - rect.size.y)
		point = clamp_to_map(point)
		if not view.has_point(point):
			break
	return point


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func on_enemy_hit(enemy: Enemy) -> void:
	AudioManager.play("hit", rng.randf_range(0.9, 1.15))
	fx.burst(enemy.position, Color(1.0, 0.95, 0.8), 2, 160.0, 5.0, 0.2)


# --- build ----------------------------------------------------------------

func apply_card(card: Dictionary) -> void:
	match str(card["kind"]):
		"weapon":
			LevelupRoller.apply(state, card)
			_sync_weapon(str(card["id"]))
		"passive":
			LevelupRoller.apply(state, card)
			player.set_stats(_compute_stats())
		"coins":
			state.bonus_coins += int(GameData.num("run", "fallback_coins"))
		"heal":
			player.heal(player.stats.max_hp * GameData.num("run", "fallback_heal_pct"))
	build_changed.emit()


func _sync_weapon(id: String) -> void:
	var weapon: BaseWeapon = weapon_nodes.get(id) as BaseWeapon
	if weapon == null:
		var data: WeaponData = WeaponLine.weapon_for(id, hero.id, age.id)
		weapon = (load(data.script_path) as GDScript).new()
		player.add_child(weapon)
		weapon.setup(self, data)
		weapon_nodes[id] = weapon
	weapon.set_level(int(state.weapons[id]))


func apply_evolution(evo: EvolutionData) -> void:
	state.evolved[evo.weapon_id] = evo.id
	state.evolutions_made += 1
	(weapon_nodes[evo.weapon_id] as BaseWeapon).evolve(evo)
	Analytics.log_event("evolution", {"id": evo.id})
	build_changed.emit()


# --- flow -----------------------------------------------------------------

func _collect(xp: float, delta: float) -> void:
	_combo_timer -= delta
	if xp <= 0.0:
		return
	if _combo_timer <= 0.0:
		_combo = 0
	_combo += embers.collected_count
	_combo_timer = GameData.num("embers", "combo_window")
	var pitch: float = minf(1.0 + _combo * GameData.num("embers", "combo_pitch_step"), GameData.num("embers", "combo_pitch_max"))
	AudioManager.play("ember", pitch)
	fx.burst(player.position, Color(1.0, 0.7, 0.3), 3, 140.0, 5.0, 0.25)
	_pending_levels += XpSystem.add_xp(state, xp * player.stats.xp_mult * RemoteConfig.num("xp_multiplier"))


func choose_card(card: Dictionary) -> void:
	if mode != Mode.CHOOSING:
		return
	apply_card(card)
	Analytics.log_event("level_up", {"level": state.level, "choice_id": str(card["id"])})
	_pending_levels -= 1
	if _pending_levels > 0:
		levelup_requested.emit(LevelupRoller.roll(state, rng))
	else:
		mode = Mode.PLAYING
		var notice: String = Roster.announcement(state.level)
		if not notice.is_empty():
			notice_requested.emit(notice)


func reroll() -> void:
	if mode == Mode.CHOOSING and state.rerolls_left > 0:
		state.rerolls_left -= 1
		levelup_requested.emit(LevelupRoller.roll(state, rng))


func open_chest() -> void:
	mode = Mode.CHEST
	AudioManager.play("chest")
	chest_opened.emit(BossChest.open(self))


func close_chest() -> void:
	if mode == Mode.CHEST:
		mode = Mode.PLAYING


func set_paused(paused: bool) -> void:
	if paused and mode == Mode.PLAYING:
		mode = Mode.PAUSED
	elif not paused and mode == Mode.PAUSED:
		mode = Mode.PLAYING


func can_revive() -> bool:
	if state.revive_used:
		return false
	for building: BuildingData in GameData.buildings():
		if building.revive_unlock_level > 0 and GameState.building_level(building.id) >= building.revive_unlock_level:
			return true
	return false


func revive() -> void:
	if mode != Mode.REVIVE:
		return
	state.revive_used = true
	player.revive(GameData.num("run", "revive_hp_pct"))
	enemies.clear_around(player.position, GameData.num("run", "revive_clear_radius"))
	hazards.clear()
	fx.ring(player.position, GameData.num("run", "revive_clear_radius"), Color(1.0, 0.85, 0.5), 0.5)
	mode = Mode.PLAYING


func give_up() -> void:
	if mode == Mode.REVIVE or mode == Mode.PAUSED:
		_finish(false)


func _on_player_died() -> void:
	AudioManager.play("defeat")
	if can_revive():
		mode = Mode.REVIVE
		revive_offered.emit()
	else:
		_finish(false)


func _finish(victory: bool) -> void:
	if mode == Mode.ENDED:
		return
	mode = Mode.ENDED
	state.victory = victory
	if victory:
		state.time = wave.duration
		for boss: Enemy in enemies.bosses.duplicate():
			fx.burst(boss.position, Color(1.0, 0.85, 0.5), 40, 500.0, 12.0, 0.9)
			enemies.despawn(boss)
		AudioManager.play("levelup", 0.8)
	Analytics.log_event("run_end", {"result": "dawn" if victory else "defeat", "time": roundi(state.time),
		"kills": state.kills, "level": state.level, "coins": state.bonus_coins})
	var summary: Dictionary = state.summary()
	summary["coin_mult"] = coin_mult()
	run_ended.emit(summary)


func _on_enemy_died(data: EnemyData, pos: Vector2, carried_xp: float) -> void:
	state.add_kill(data.id)
	embers.add(pos, data.xp + carried_xp)
	state.bonus_coins += int(data.params.get("bonus_coins", 0))
	fx.burst(pos, Color(0.75, 0.7, 1.0), 6)
	potions.on_enemy_died(pos)
	_request_hint(2)


func _on_boss_spawned(boss: Enemy) -> void:
	darkness.set_eclipse(float(boss.data.params.get("light_radius", 0.0)))
	boss_changed.emit(boss)


func _on_boss_died(boss: Enemy) -> void:
	var data: BossData = boss.data as BossData
	state.bosses_killed.append(data.id)
	state.boss_timber += data.timber
	darkness.set_eclipse(0.0)
	_events.drop_chest(boss.position)
	if GameData.num("potion", "boss_drops") > 0.0:
		potions.drop(boss.position + Vector2(GameData.num("potion", "boss_drop_offset"), 0.0))
	shake(GameData.num("run", "shake_boss"))
	fx.burst(boss.position, Color(1.0, 0.8, 0.4), 40, 520.0, 12.0, 0.8)
	AudioManager.play("explode", 0.6)
	AudioManager.haptic(60)
	Analytics.log_event("boss_killed", {"id": data.id, "time": roundi(state.time)})
	boss_changed.emit(null)


func _on_potion_collected(_amount: float) -> void:
	AudioManager.play("potion")
	fx.ring(player.position, GameData.num("potion", "pickup_radius") * 1.6, Color(0.44, 0.88, 0.54), 0.4)
	fx.burst(player.position, Color(0.44, 0.88, 0.54), 14, 220.0, 7.0, 0.5)


func _on_player_hurt(_amount: float) -> void:
	shake(GameData.num("run", "shake_hit"))
	AudioManager.play("hurt")


func _request_hint(index: int) -> void:
	if _hints_on and index == _hint_step + 1:
		_hint_step = index
		Analytics.log_event("tutorial_step", {"n": index})
		hint_requested.emit(index)
