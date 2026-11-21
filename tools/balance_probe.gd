extends Node
## Balance probe: plays nights headlessly with a plain bot and prints how long
## it survives, plus simulation cost and how much the crowd overlaps.
##   godot --headless --path . res://tools/balance_probe.tscn -- --seeds=6 --village=0 --hero=hero_muthu [--night=paddy_fields] [--age=age_steel]
## Uses a throwaway profile; the real save is never read or written.

const STEP: float = 0.05
const PROBE_SAVE: String = "user://probe_save.json"

func _ready() -> void:
	var seeds: int = 6
	var village: int = 0
	var hero: String = "hero_muthu"
	var night: String = ""
	var age: String = "age_founders"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="):
			seeds = int(arg.trim_prefix("--seeds="))
		elif arg.begins_with("--village="):
			village = int(arg.trim_prefix("--village="))
		elif arg.begins_with("--hero="):
			hero = arg.trim_prefix("--hero=")
		elif arg.begins_with("--night="):
			night = arg.trim_prefix("--night=")
		elif arg.begins_with("--age="):
			age = arg.trim_prefix("--age=")
	SaveManager.path = PROBE_SAVE
	GameState.reset_profile()
	var profile: Dictionary = GameState.p
	profile["hints_done"] = true
	profile["selected_hero"] = hero
	profile["age"] = age
	if not night.is_empty():
		# Unlock every night up to the one asked for.
		for wave: WaveData in GameData.waves():
			profile["selected_night"] = wave.id
			if wave.id == night:
				break
			(profile["nights"] as Dictionary)[wave.id] = {"won": true, "best_time": wave.duration}
	(profile["heroes"] as Array).append(hero)
	for building: BuildingData in GameData.buildings():
		(profile["buildings"] as Dictionary)[building.id] = village
	var times: Array[float] = []
	for index: int in seeds:
		times.append(_night(index + 1))
	times.sort()
	var total: float = 0.0
	for value: float in times:
		total += value
	print("RESULT age=%s night=%s hero=%s village=%d seeds=%d  min=%s median=%s max=%s mean=%s" % [age, NightLogic.selected().id, hero, village, seeds,
		_clock(times[0]), _clock(times[times.size() / 2]), _clock(times[times.size() - 1]), _clock(total / float(seeds))])
	get_tree().quit()


func _night(seed_value: int) -> float:
	var run: RunManager = RunManager.new()
	add_child(run)
	run.set_process(false)
	run.rng.seed = seed_value * 7919
	var overlap_sum: float = 0.0
	var overlap_samples: int = 0
	var steps: int = 0
	var potions: Array[int] = [0]
	run.potions.collected.connect(func(_amount: float) -> void: potions[0] += 1)
	var started: int = Time.get_ticks_usec()
	while run.mode != RunManager.Mode.ENDED and run.mode != RunManager.Mode.REVIVE:
		match run.mode:
			RunManager.Mode.CHOOSING:
				run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
			RunManager.Mode.CHEST:
				run.close_chest()
			_:
				run.input_dir = _bot(run)
				run.advance(STEP)
				steps += 1
				if steps % 100 == 0 and run.enemies.count() >= 20:
					overlap_sum += _overlap(run)
					overlap_samples += 1
	var cost: float = float(Time.get_ticks_usec() - started) / 1000.0 / float(maxi(steps, 1))
	var time: float = run.state.time
	print("  seed %d: %s  level %d  kills %d  potions %d (+%d left)  step %.2f ms  overlap %.0f%%" % [seed_value, _clock(time),
		run.state.level, run.state.kills, potions[0], run.potions.count(), cost, overlap_sum / float(maxi(overlap_samples, 1)) * 100.0])
	run.free()
	return time


## Share of creatures whose centre sits inside half the combined radius of another.
static func _overlap(run: RunManager) -> float:
	var active: Array[Enemy] = run.enemies.active
	var stacked: int = 0
	for a: Enemy in active:
		for b: Enemy in active:
			if a != b and a.position.distance_to(b.position) < (a.radius + b.radius) * 0.5:
				stacked += 1
				break
	return float(stacked) / float(active.size())


## A plain player: fetch a potion when badly hurt, else the nearest ember, else drift.
static func _bot(run: RunManager) -> Vector2:
	var player: Player = run.player
	if player.hp < player.stats.max_hp * 0.5:
		var best: Vector2 = Vector2.INF
		for potion: Vector2 in run.potions.positions():
			if best == Vector2.INF or potion.distance_to(player.position) < best.distance_to(player.position):
				best = potion
		if best != Vector2.INF and best.distance_to(player.position) < 900.0:
			return (best - player.position).normalized()
	var ember: Vector2 = run.embers.nearest(player.position, 700.0)
	if ember != Vector2.INF and ember.distance_to(player.position) > 20.0:
		return (ember - player.position).normalized()
	return Vector2.from_angle(run.state.time * 0.4)


static func _clock(seconds: float) -> String:
	@warning_ignore("integer_division")
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
