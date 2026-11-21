class_name Hud
extends Control
## Run HUD (spec §10): XP bar with the level on it, HP bar with the numbers on
## it, timer, the night's goal line, kill and coin chips, build icons, pause,
## potion button, boss bar, warning banner, the night's opening goal card and
## first-run hints. The developer overlay (FPS, entity
## counts) is off unless switched on in Settings in a debug build.

signal pause_pressed

const HINTS: Array[String] = [
	"Drag anywhere to move.\nYour weapons fire on their own.",
	"Walk over the glowing embers to gain XP.",
	"Level up! Pick one upgrade.",
]
const BANNER_SECONDS: float = 2.0
const HINT_SECONDS: float = 5.0
const NOTICE_SECONDS: float = 2.5
const DEBUG_REFRESH: float = 0.25
const CHIP_COLOR: Color = Color(0.04, 0.05, 0.1, 0.72)
const HEART_ICON: String = "res://assets/sprites/icons/heart.svg"
const KILL_ICON: String = "res://assets/sprites/e_wisp.svg"

var run: RunManager
var _xp: ProgressBar
var _hp: ProgressBar
var _level: Label
var _hp_text: Label
var _timer: Label
var _kills: Label
var _coins: Label
var _icons: HBoxContainer
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss: Enemy
var _banner: Label
var _goal: Label
var _intro: Label
var _hint: Label
var _debug: Label
var _debug_timer: float = 0.0
var _potion: Button


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pointers: EdgePointers = EdgePointers.new()
	pointers.run = run
	add_child(pointers)
	var column: VBoxContainer = UiKit.vbox(12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiKit.safe_area(self, 20).add_child(column)

	_xp = UiKit.bar(UiKit.EMBER, 46.0)
	column.add_child(_xp)
	_level = _bar_label(_xp)
	var top: HBoxContainer = UiKit.hbox()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var left: VBoxContainer = UiKit.vbox(8)
	left.custom_minimum_size = Vector2(430.0, 0.0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(left)
	var hp_row: HBoxContainer = UiKit.hbox(10)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(hp_row)
	hp_row.add_child(UiKit.icon(HEART_ICON, 50.0))
	_hp = UiKit.bar(UiKit.DANGER, 50.0)
	_hp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp)
	_hp_text = _bar_label(_hp)
	var chips: HBoxContainer = UiKit.hbox(12)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(chips)
	_kills = _chip(chips, KILL_ICON, UiKit.TEXT)
	_coins = _chip(chips, UiKit.ICON_DIR + "coin.svg", UiKit.GOLD)
	_timer = UiKit.label("0:00", UiKit.FONT_HUGE)
	_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_timer)
	top.add_child(_timer)
	var pause: Button = UiKit.button("II", func() -> void: pause_pressed.emit(), "secondary")
	pause.custom_minimum_size = Vector2(UiKit.TOUCH + 20.0, UiKit.TOUCH)
	var right: VBoxContainer = UiKit.vbox(12)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(right)
	right.add_child(pause)
	_potion = UiKit.button("", func() -> void: run.potions.drink(), "good")
	_potion.custom_minimum_size = Vector2(UiKit.TOUCH + 20.0, UiKit.TOUCH)
	_potion.icon = load(Potions.TEXTURE) as Texture2D
	_potion.expand_icon = true
	_potion.visible = false
	right.add_child(_potion)

	_goal = UiKit.label("", UiKit.FONT_SMALL, UiKit.GOLD)
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline(_goal)
	column.add_child(_goal)

	_icons = UiKit.hbox(8)
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_icons)

	_boss_box = UiKit.vbox(6)
	_boss_box.visible = false
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_boss_box)
	_boss_name = UiKit.label("", UiKit.FONT, UiKit.DAWN)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outline(_boss_name)
	_boss_box.add_child(_boss_name)
	_boss_bar = UiKit.bar(Color("b23ad6"), 36.0)
	_boss_box.add_child(_boss_bar)

	_banner = _floating_label(UiKit.FONT_BIG, UiKit.DANGER)
	column.add_child(_banner)
	_intro = _floating_label(UiKit.FONT_BIG, UiKit.GOLD)
	column.add_child(_intro)
	column.add_child(UiKit.spacer())
	_hint = _floating_label(UiKit.FONT, UiKit.TEXT)
	column.add_child(_hint)
	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, 420.0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gap)

	_debug = UiKit.label("", 26, UiKit.GOOD)
	_debug.visible = OS.is_debug_build() and bool(GameState.setting("debug_overlay")) and not Main.screenshot_mode
	_outline(_debug)
	gap.add_child(_debug)

	run.build_changed.connect(_rebuild_icons)
	run.boss_changed.connect(func(boss: Enemy) -> void: _boss = boss)
	run.banner_requested.connect(func(text: String) -> void: _flash(_banner, text, BANNER_SECONDS))
	run.hint_requested.connect(func(index: int) -> void: _flash(_hint, HINTS[index - 1], HINT_SECONDS))
	run.notice_requested.connect(func(text: String) -> void: _flash(_hint, text, NOTICE_SECONDS))
	_rebuild_icons()
	_flash(_intro, intro_text(run.wave), GameData.num("objective", "intro_seconds"))


## The card shown as a night begins: which night, and what winning means.
static func intro_text(wave: WaveData) -> String:
	return "NIGHT %d · %s\nSurvive until dawn (%s)" % [NightLogic.number(wave.id), wave.display_name.to_upper(),
		NightLogic.clock(wave.duration)]


## Centred text drawn on top of a bar (level on the XP bar, numbers on the HP bar).
static func _bar_label(bar: ProgressBar) -> Label:
	var node: Label = UiKit.label("", UiKit.FONT_SMALL)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline(node)
	bar.add_child(node)
	return node


## A dark pill with an icon and a number, readable over any part of the map.
static func _chip(parent: Control, icon_path: String, color: Color) -> Label:
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.box(CHIP_COLOR, 24, Color.TRANSPARENT, 10))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pill)
	var row: HBoxContainer = UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	row.add_child(UiKit.icon(icon_path, 44.0))
	var text: Label = UiKit.label("0", UiKit.FONT_SMALL, color)
	row.add_child(text)
	return text


static func _outline(node: Label) -> void:
	node.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.12))
	node.add_theme_constant_override("outline_size", 10)


func _floating_label(font_size: int, color: Color) -> Label:
	var node: Label = UiKit.label("", font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.modulate.a = 0.0
	_outline(node)
	return node


func _flash(node: Label, text: String, seconds: float) -> void:
	node.text = text
	var tween: Tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, 0.2)
	tween.tween_interval(seconds)
	tween.tween_property(node, "modulate:a", 0.0, 0.4)


func _process(delta: float) -> void:
	var state: RunState = run.state
	var seconds: int = int(state.time)
	@warning_ignore("integer_division")
	_timer.text = "%d:%02d" % [seconds / 60, seconds % 60]
	_xp.max_value = XpSystem.xp_to_next(state.level)
	_xp.value = state.xp
	_hp.max_value = run.player.stats.max_hp
	_hp.value = run.player.hp
	_level.text = "LEVEL %d" % state.level
	_hp_text.text = "%d / %d" % [mini(ceili(run.player.hp), roundi(run.player.stats.max_hp)), roundi(run.player.stats.max_hp)]
	_kills.text = UiKit.number(state.kills)
	_coins.text = UiKit.number(Economy.run_coins(state.kills, state.time, false, run.coin_mult(),
		RemoteConfig.num("coin_multiplier"), state.bonus_coins))
	var carried: int = run.potions.carried_left()
	_potion.visible = carried > 0
	_potion.text = "×%d" % carried
	_potion.disabled = run.player.hp >= run.player.stats.max_hp
	var boss_alive: bool = is_instance_valid(_boss) and _boss.alive
	_boss_box.visible = boss_alive
	_goal.text = NightLogic.objective(run.wave, state.time, _boss.data.display_name if boss_alive else "")
	if boss_alive:
		_boss_name.text = _boss.data.display_name
		_boss_bar.max_value = _boss.max_hp
		_boss_bar.value = _boss.hp
	if _debug.visible:
		_debug_timer -= delta
		if _debug_timer <= 0.0:
			_debug_timer = DEBUG_REFRESH
			_debug.text = "FPS %d\nenemies %d\nprojectiles %d\nembers %d\nparticles %d" % [
				Engine.get_frames_per_second(), run.enemies.count(), run.projectiles.count(),
				run.embers.count(), run.fx.particle_count()]


func _rebuild_icons() -> void:
	for child: Node in _icons.get_children():
		child.queue_free()
	for id: String in run.state.weapons.keys():
		var tag: String = "EVO" if run.state.evolved.has(id) else str(int(run.state.weapons[id]))
		_icons.add_child(build_icon(WeaponLine.weapon_for(id).icon, tag))
	for id: String in run.state.passives.keys():
		_icons.add_child(build_icon(GameData.passive(id).icon, str(int(run.state.passives[id]))))


## Small icon with a level tag; reused by the pause menu.
static func build_icon(path: String, tag: String, size: float = 104.0) -> Control:
	var holder: Control = UiKit.icon(path, size)
	var text: Label = UiKit.label(tag, 30, UiKit.GOLD)
	_outline(text)
	text.position = Vector2(size - 19.0 * tag.length() - 4.0, size - 40.0)
	holder.add_child(text)
	return holder
