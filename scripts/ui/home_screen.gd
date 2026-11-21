class_name HomeScreen
extends Control
## Home / Village (spec §10): currencies, age bar, the village map (most of
## the screen), a "tonight" card (hero + night picker), Start Night and the
## bottom navigation bar.

## The how-to tip shows only until the village reaches this total level.
const TIP_UNTIL_LEVEL: int = 3

var _village: VillageView
var _currency_holder: Control
var _hero_row: HBoxContainer
var _tip: Label
var _nav_holder: MarginContainer
var _age_button: Button
var _collect_button: Button
var _nights: NightPicker
var _start: Button
var _panel: VBoxContainer
var _panel_id: String = ""


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiKit.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = UiKit.vbox(14)
	UiKit.safe_area(self, 22).add_child(column)
	_currency_holder = Control.new()
	_currency_holder.custom_minimum_size = Vector2(0.0, 96.0)
	column.add_child(_currency_holder)
	var age_row: HBoxContainer = UiKit.hbox(12)
	column.add_child(age_row)
	_age_button = UiKit.button("", func() -> void: AgePanel.open(self, Callable()), "secondary")
	_age_button.add_theme_font_size_override("font_size", UiKit.FONT_SMALL)
	_age_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_age_button.custom_minimum_size = Vector2(0.0, 104.0)
	age_row.add_child(_age_button)
	_collect_button = UiKit.button("Collect", _collect_all, "good")
	_collect_button.add_theme_font_size_override("font_size", UiKit.FONT_SMALL)
	_collect_button.custom_minimum_size = Vector2(0.0, 104.0)
	age_row.add_child(_collect_button)
	_tip = UiKit.label("Tap a building to build or upgrade it. Scroll down for more land.", 28, UiKit.MUTED, true)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_tip)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	column.add_child(scroll)
	_village = VillageView.new()
	_village.building_selected.connect(_open_panel)
	_village.land_selected.connect(func(id: String) -> void: LandPanel.open(self, id))
	scroll.add_child(_village)
	scroll.resized.connect(func() -> void: _village.set_visible_height(scroll.size.y))
	# Tonight: who you play and which night, in one card.
	var tonight: PanelContainer = UiKit.panel(UiKit.PANEL, UiKit.AMBER.darkened(0.45))
	column.add_child(tonight)
	var tonight_column: VBoxContainer = UiKit.vbox(10)
	tonight.add_child(tonight_column)
	_hero_row = UiKit.hbox(16)
	tonight_column.add_child(_hero_row)
	var divider: ColorRect = ColorRect.new()
	divider.color = UiKit.PANEL_LIGHT
	divider.custom_minimum_size = Vector2(0.0, 3.0)
	tonight_column.add_child(divider)
	_nights = NightPicker.new()
	_nights.embedded = true
	_nights.changed.connect(_update_start)
	tonight_column.add_child(_nights)
	_start = UiKit.button("START NIGHT", _start_night)
	_start.custom_minimum_size = Vector2(0.0, 140.0)
	_start.add_theme_font_size_override("font_size", UiKit.FONT_BIG)
	_start.add_theme_font_override("font", UiKit.font(UiKit.WEIGHT_HEADING))
	column.add_child(_start)
	_nav_holder = MarginContainer.new()
	column.add_child(_nav_holder)

	var ticker: Timer = Timer.new()
	ticker.wait_time = 1.0
	ticker.autostart = true
	ticker.timeout.connect(_tick)
	add_child(ticker)
	GameState.changed.connect(_refresh)
	AudioManager.play_music("music_night")
	VillageLogic.complete_due()
	ProductionLogic.sync_clocks()
	DailyLogic.ensure_today()
	_refresh()
	_maybe_offer_starter_pack()


## First press shows How to play (with Skip); after that, straight into the night.
func _start_night() -> void:
	if not _nights.is_playable():
		return
	if HowToPlay.seen():
		SceneRouter.goto("run")
	else:
		HowToPlay.open(self, func() -> void: SceneRouter.goto("run"))


func _update_start() -> void:
	var playable: bool = _nights.is_playable()
	_start.disabled = not playable
	_start.text = "START NIGHT %d" % (_nights.index + 1) if playable else "LOCKED"


func _collect_all() -> void:
	var got: Dictionary = ProductionLogic.collect_all()
	if not got.is_empty():
		AudioManager.play("purchase")
		UiKit.message(self, "Collected", "You collected %s." % UiKit.rewards_text(got))


func _update_collect() -> void:
	var ready: int = ProductionLogic.total_ready()
	_collect_button.visible = ready > 0
	_collect_button.text = "Collect +%s" % UiKit.number(ready)


func _tick() -> void:
	if not VillageLogic.complete_due().is_empty():
		AudioManager.play("levelup")
	_village.queue_redraw()
	_update_collect()
	if _panel != null and is_instance_valid(_panel):
		BuildingPanel.update_timer(_panel, _panel_id)


func _refresh() -> void:
	for child: Node in _currency_holder.get_children():
		child.queue_free()
	var bar: HBoxContainer = UiKit.currency_bar()
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_currency_holder.add_child(bar)
	for child: Node in _hero_row.get_children():
		child.queue_free()
	var hero: HeroData = GameData.hero(str(GameState.p["selected_hero"]))
	var portrait: TextureRect = UiKit.icon(hero.texture_for(AgeLogic.current()), 112.0)
	portrait.modulate = Color(str(GameState.selected_skin(hero.id).get("tint", "#ffffff")))
	_hero_row.add_child(portrait)
	var text: VBoxContainer = UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_child(UiKit.label(hero.display_name, UiKit.FONT, UiKit.TEXT))
	var weapon: String = WeaponLine.weapon_for(hero.starting_weapon, hero.id).display_name
	text.add_child(UiKit.label("%s · %s" % [weapon, hero.bonus_text().trim_suffix(" from nights")], 28, UiKit.MUTED, true))
	_hero_row.add_child(text)
	var change: Button = UiKit.button("Change", func() -> void: SceneRouter.goto("heroes"), "secondary")
	change.add_theme_font_size_override("font_size", UiKit.FONT_SMALL)
	change.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hero_row.add_child(change)
	_tip.visible = VillageLogic.total_level() < TIP_UNTIL_LEVEL
	_age_button.text = AgePanel.summary_text()
	_update_collect()
	for child: Node in _nav_holder.get_children():
		child.queue_free()
	_nav_holder.add_child(NavBar.build("home", NavBar.badges()))
	_nights.refresh()
	_update_start()
	_village.queue_redraw()
	if _panel != null and is_instance_valid(_panel):
		UiKit.close_modal(_panel)
		_open_panel(_panel_id)


func _open_panel(id: String) -> void:
	_panel_id = id
	_panel = BuildingPanel.open(self, id, func() -> void: _panel = null)


## Shown once, right after the player's first run (spec §9.2). No fake urgency:
## the 72 h countdown starts here and never resets.
func _maybe_offer_starter_pack() -> void:
	if int(GameState.p["runs_played"]) < 1 or float(GameState.p["starter_pack_shown_at"]) > 0.0:
		return
	if BillingService.is_owned("starter_pack") or not RemoteConfig.flag("starter_pack_enabled"):
		return
	GameState.p["starter_pack_shown_at"] = GameState.now()
	GameState.save()
	var product: Dictionary = GameData.product("starter_pack")
	var content: VBoxContainer = UiKit.modal(self, str(product["title"]))
	var desc: Label = UiKit.label(str(product["desc"]), UiKit.FONT, UiKit.TEXT, true)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(desc)
	content.add_child(UiKit.button("See in shop", func() -> void:
		UiKit.close_modal(content)
		SceneRouter.goto("shop")))
	content.add_child(UiKit.button("Not now", func() -> void: UiKit.close_modal(content), "secondary"))
