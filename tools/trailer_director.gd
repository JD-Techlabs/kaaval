extends Node
## Plays a fixed script of scenes for the Play Store preview video while
## Godot's Movie Maker records it. Run it with tools/make_trailer.ps1.
## Uses the throwaway demo profile from ScreenshotTool (`-- --demo-profile`);
## the real save is never touched. Tool only: tools/* is not exported.

const CAPTION_FADE: float = 0.35
const CARD_FADE: float = 0.5
## How long level-up cards stay on screen: long in the "new power" shot, short elsewhere.
const CHOICE_SHOWN: float = 1.6
const CHOICE_QUICK: float = 0.3
## Caption heights: below the level-up cards in a night, over the village map at home.
const CAPTION_Y_RUN: float = 1560.0
const CAPTION_Y_HOME: float = 1000.0
const SKIP_STEP: float = 0.05
const HERO: String = "hero_muthu"

var _run: RunManager
var _time: float = 0.0
var _skipping: bool = false
var _choice_delay: float = CHOICE_QUICK
var _levelups: int = 0
var _layer: CanvasLayer
var _caption_box: PanelContainer
var _caption: Label
var _card: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	Main.screenshot_mode = true
	_setup.call_deferred()


## Deferred: the root cannot take new children while it is adding this scene.
func _setup() -> void:
	var tool_node: ScreenshotTool = ScreenshotTool.new()
	tool_node.name = "ScreenshotTool"
	get_tree().root.add_child(tool_node)
	# Scene changes free the current scene; hand that role to a placeholder so
	# this director (and its captions) lives through every scene change.
	var placeholder: Node = Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	_build_overlay()
	_sequence()


func _process(delta: float) -> void:
	_time += delta
	if _run == null or not is_instance_valid(_run) or _skipping:
		return
	if _run.mode == RunManager.Mode.PAUSED:
		(_run.get_parent().get_node("Ui") as RunUi)._resume()
	elif _run.mode == RunManager.Mode.PLAYING:
		_run.input_dir = _autopilot(_time)


# --- the script -----------------------------------------------------------

func _sequence() -> void:
	await get_tree().process_frame
	GameState.p["selected_hero"] = HERO
	GameState.p["age"] = "age_founders"
	_show_card(true)
	SceneRouter.goto("home")
	await _wait(3.0)

	await _enter_run(95.0)
	_hide_card()
	_say("Survive the night")
	await _wait(4.0)
	_choice_delay = CHOICE_SHOWN
	# Top the XP bar up so the next ember picked up brings the level-up cards.
	_run.state.xp = XpSystem.xp_to_next(_run.state.level) - 0.5
	await _wait_for_levelup(5.0)
	_say("Pick a new power every level")
	await _wait(3.0)
	_choice_delay = CHOICE_QUICK
	_skip_to(230.0)
	_say("Hold the line against the swarm")
	await _wait(5.5)
	_skip_to(303.0)
	_say("Face the bosses of the dark")
	await _wait(6.0)

	_run = null
	GameState.p["age"] = "age_learning"
	SceneRouter.goto("home")
	await SceneRouter.screen_changed
	await get_tree().process_frame
	await get_tree().process_frame
	_say("Rebuild your village", CAPTION_Y_HOME)
	await _wait(0.6)
	_scroll_village(700, 4.5)
	await _wait(5.0)
	var panel: VBoxContainer = AgePanel.open(get_tree().current_scene, Callable())
	_say("Lead it through seven ages", CAPTION_Y_HOME)
	await _wait(3.5)
	UiKit.close_modal(panel)

	GameState.p["age"] = "age_circuits"
	await _enter_run(235.0)
	# Late-age guns clear the screen fast: bring a crowd in for the strikes to hit.
	_surround()
	_time_strikes([1.2, 3.2])
	_say("From slings to jets and missiles")
	await _wait(3.5)
	_surround()
	await _wait(4.0)

	_hide_caption()
	_show_card(false)
	await _wait(4.5)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func _enter_run(skip: float) -> void:
	SceneRouter.goto("run")
	await SceneRouter.screen_changed
	# change_scene_to_file swaps the scene at the end of the frame.
	while get_tree().current_scene == null or not get_tree().current_scene.has_node("Run"):
		await get_tree().process_frame
	_run = get_tree().current_scene.get_node("Run") as RunManager
	_run.player.invulnerable = true
	_run.levelup_requested.connect(_on_levelup)
	_run.chest_opened.connect(_on_chest)
	_skip_to(skip)


# --- playing the night ----------------------------------------------------

## Waits (up to `limit` seconds) until the next level-up cards appear.
func _wait_for_levelup(limit: float) -> void:
	var seen: int = _levelups
	var start: float = _time
	while _levelups == seen and _time - start < limit:
		await get_tree().process_frame


## Rings of creatures closing in on the hero from just off screen.
func _surround() -> void:
	var center: Vector2 = _run.player.position
	_run.enemies.spawn_around(GameData.enemy("e_crawler"), center, 36, 650.0)
	_run.enemies.spawn_around(GameData.enemy("e_beetle"), center, 18, 820.0)
	_run.enemies.spawn_around(GameData.enemy("e_golem"), center, 10, 980.0)


## Makes the hero's called-in strikes fire after these delays, so they land on camera.
func _time_strikes(delays: Array[float]) -> void:
	var entries: Array[Dictionary] = _run.strikes._strikes
	for i: int in mini(entries.size(), delays.size()):
		entries[i]["left"] = delays[i]


## Moves toward the nearest ember, otherwise walks a slow loop.
func _autopilot(t: float) -> Vector2:
	var ember: Vector2 = _run.embers.nearest(_run.player.position, 700.0)
	if ember == Vector2.INF:
		return Vector2.from_angle(t * 0.7)
	return (ember - _run.player.position).normalized()


## Simulates the night forward to `target` seconds without drawing, then
## clears any pop-ups that opened along the way.
func _skip_to(target: float) -> void:
	_skipping = true
	var t: float = 0.0
	while _run.state.time < target and _run.mode != RunManager.Mode.ENDED:
		if _run.mode == RunManager.Mode.CHOOSING:
			_run.choose_card(LevelupRoller.roll(_run.state, _run.rng)[0])
		elif _run.mode == RunManager.Mode.CHEST:
			_run.close_chest()
		else:
			_run.input_dir = _autopilot(t)
			_run.advance(SKIP_STEP)
			t += SKIP_STEP
	for child: Node in _run.get_parent().get_node("Ui").get_children():
		if not (child is Joystick or child is Hud):
			child.queue_free()
	while _run.mode == RunManager.Mode.CHOOSING:
		_run.choose_card(LevelupRoller.roll(_run.state, _run.rng)[0])
	_run.close_chest()
	_skipping = false


## Leaves the level-up cards on screen for a moment, then taps the first one.
func _on_levelup(_cards: Array[Dictionary]) -> void:
	if _skipping:
		return
	_levelups += 1
	await _wait(_choice_delay)
	var buttons: Array[Button] = _modal_buttons()
	if not buttons.is_empty():
		buttons[0].pressed.emit()


func _on_chest(_lines: Array[Dictionary]) -> void:
	if _skipping:
		return
	await _wait(_choice_delay)
	for button: Button in _modal_buttons():
		if button.text == "Continue":
			button.pressed.emit()


func _modal_buttons() -> Array[Button]:
	var out: Array[Button] = []
	if _run == null or not is_instance_valid(_run):
		return out
	var ui: Node = _run.get_parent().get_node("Ui")
	var modal: Node = ui.get_child(ui.get_child_count() - 1)
	if modal is Joystick or modal is Hud:
		return out
	for node: Node in modal.find_children("*", "Button", true, false):
		out.append(node as Button)
	return out


func _scroll_village(to: int, seconds: float) -> void:
	for node: Node in get_tree().current_scene.find_children("*", "ScrollContainer", true, false):
		create_tween().tween_property(node, "scroll_vertical", to, seconds).set_trans(Tween.TRANS_SINE)
		return


# --- captions and cards ---------------------------------------------------

func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 101
	add_child(_layer)
	_caption_box = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.12, 0.82)
	style.border_color = UiKit.GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(40)
	style.content_margin_left = 48.0
	style.content_margin_right = 48.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 26.0
	_caption_box.add_theme_stylebox_override("panel", style)
	_caption_box.position = Vector2(60.0, CAPTION_Y_RUN)
	_caption_box.custom_minimum_size = Vector2(960.0, 0.0)
	_caption_box.modulate.a = 0.0
	_layer.add_child(_caption_box)
	_caption = _label("", 64, UiKit.GOLD)
	_caption_box.add_child(_caption)


func _label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", UiKit.font(UiKit.WEIGHT_HEADING))
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 10)
	return label


func _say(text: String, y: float = CAPTION_Y_RUN) -> void:
	var tween: Tween = create_tween()
	if _caption_box.modulate.a > 0.0:
		tween.tween_property(_caption_box, "modulate:a", 0.0, CAPTION_FADE)
	tween.tween_callback(func() -> void:
		_caption.text = text
		_caption_box.position.y = y)
	tween.tween_property(_caption_box, "modulate:a", 1.0, CAPTION_FADE)


func _hide_caption() -> void:
	create_tween().tween_property(_caption_box, "modulate:a", 0.0, CAPTION_FADE)


## The opening card (title) or the closing card (title, slogan, call to action).
func _show_card(opening: bool) -> void:
	_card = ColorRect.new()
	(_card as ColorRect).color = UiKit.BG
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.modulate.a = 1.0 if opening else 0.0
	_layer.add_child(_card)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 28)
	_card.add_child(column)
	var hero: HeroData = GameData.hero(HERO)
	var picture: TextureRect = TextureRect.new()
	picture.texture = load(hero.texture_for(AgeLogic.current())) as Texture2D
	picture.custom_minimum_size = Vector2(0.0, 440.0)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(picture)
	column.add_child(_label("Kavaryn", 150, UiKit.GOLD))
	column.add_child(_label("Guardians of Dawn", 72, UiKit.AMBER))
	if opening:
		column.add_child(_label("Night is falling on the village...", 48, Color(0.85, 0.88, 1.0)))
	else:
		column.add_child(_label("Light the lamps. Hold the line.\nSee the dawn.", 56, Color(0.92, 0.94, 1.0)))
		column.add_child(_label("Free to play · Plays offline", 44, UiKit.AMBER))
		create_tween().tween_property(_card, "modulate:a", 1.0, CARD_FADE)


func _hide_card() -> void:
	var card: Control = _card
	var tween: Tween = create_tween()
	tween.tween_property(card, "modulate:a", 0.0, CARD_FADE)
	tween.tween_callback(card.queue_free)
