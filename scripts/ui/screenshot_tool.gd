class_name ScreenshotTool
extends Node
## Capture helper (spec Phase 7). F12 saves a PNG to user://screenshots.
## Command-line (after `--`), for scripted store captures:
##   --shot=<file.png>    save a screenshot after --shot-delay seconds, then quit
##   --shot-delay=<sec>   default 2
##   --skip=<sec>         fast-forward a run by this many seconds first
##   --demo-profile       use a throwaway mid-game profile (the real save is untouched)

const STEP: float = 0.05
const DEMO_SAVE: String = "user://demo_save.json"
const DEMO_LEVELS: Array[int] = [1, 2, 4, 5, 7, 8, 10]

var _shot_path: String = ""
var _delay: float = 2.0
var _skip: float = 0.0
var _counter: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.trim_prefix("--shot=")
		elif arg.begins_with("--shot-delay="):
			_delay = float(arg.trim_prefix("--shot-delay="))
		elif arg.begins_with("--skip="):
			_skip = float(arg.trim_prefix("--skip="))
		elif arg == "--demo-profile":
			_demo_profile()
	if not _shot_path.is_empty():
		# Render at the full 1080x1920 design size even in a small desktop window.
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	SceneRouter.screen_changed.connect(_on_screen_changed)


## A mid-game profile for captures: every building stage, some gifts, pieces and potions.
func _demo_profile() -> void:
	SaveManager.path = DEMO_SAVE
	GameState.reset_profile()
	var buildings: Array[BuildingData] = GameData.buildings()
	for i: int in buildings.size():
		(GameState.p["buildings"] as Dictionary)[buildings[i].id] = DEMO_LEVELS[i % DEMO_LEVELS.size()]
	GameState.p["hero_pieces"] = {"hero_gale": 6, "hero_banyan": 3}
	GameState.p["hints_done"] = true
	GameState.p["runs_played"] = 5
	GameState.p["starter_pack_shown_at"] = GameState.now()
	GameState.grant({"coins": 4200, "timber": 36, "gems": 180, "potions": 2, "gifts": 3})


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_F12:
		DirAccess.make_dir_recursive_absolute("user://screenshots")
		_counter += 1
		_save("user://screenshots/shot_%d_%d.png" % [int(Time.get_unix_time_from_system()), _counter])


func _on_screen_changed(_screen: String) -> void:
	if _shot_path.is_empty():
		return
	await get_tree().create_timer(0.4).timeout
	if _skip > 0.0:
		_fast_forward()
	await get_tree().create_timer(_delay).timeout
	_save(_shot_path)
	get_tree().quit()


## Simulates a run forward, auto-picking the first card on every level-up.
func _fast_forward() -> void:
	var scene: Node = get_tree().current_scene
	var run: RunManager = scene.get_node_or_null("Run") as RunManager if scene != null else null
	if run == null:
		return
	run.player.invulnerable = true
	run.levelup_requested.connect(func(cards: Array[Dictionary]) -> void: run.choose_card.call_deferred(cards[0]))
	run.chest_opened.connect(func(_lines: Array[Dictionary]) -> void: run.close_chest.call_deferred())
	var left: float = _skip
	while left > 0.0 and run.mode != RunManager.Mode.ENDED:
		if run.mode == RunManager.Mode.CHOOSING:
			run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
		elif run.mode == RunManager.Mode.CHEST:
			run.close_chest()
		else:
			var ember: Vector2 = run.embers.nearest(run.player.position, 700.0)
			run.input_dir = Vector2.from_angle(left * 0.7) if ember == Vector2.INF else (ember - run.player.position).normalized()
			run.advance(STEP)
			left -= STEP
	run.input_dir = Vector2.ZERO
	# Close the modals that piled up while skipping, and settle any pending choice.
	for child: Node in scene.get_node("Ui").get_children():
		if not (child is Joystick or child is Hud):
			child.queue_free()
	while run.mode == RunManager.Mode.CHOOSING:
		run.choose_card(LevelupRoller.roll(run.state, run.rng)[0])
	run.close_chest()


func _save(path: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var err: Error = image.save_png(path)
	print("screenshot ", path, " -> ", "ok" if err == OK else "error %d" % err)
