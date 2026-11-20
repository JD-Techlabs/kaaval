class_name HomeScreen
extends Control
## Home / Village (spec §10): village view, currencies, Start Night, hero
## portrait and the bottom navigation.

const NAV: Array[Array] = [["Village", "home"], ["Heroes", "heroes"], ["Shop", "shop"], ["Missions", "missions"], ["Settings", "settings"]]

var _village: VillageView
var _currency_holder: Control
var _hero_row: HBoxContainer
var _panel: VBoxContainer
var _panel_id: String = ""
var _nav_buttons: Dictionary = {}


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiKit.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = UiKit.vbox(18)
	UiKit.safe_area(self).add_child(column)
	_currency_holder = Control.new()
	_currency_holder.custom_minimum_size = Vector2(0.0, 100.0)
	column.add_child(_currency_holder)
	var title: Label = UiKit.label("KAAVAL · Guardians of Dawn", UiKit.FONT, UiKit.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var tip: Label = UiKit.label("Tap a building to build or upgrade it. A green arrow means you can afford it.", UiKit.FONT_SMALL, UiKit.MUTED, true)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tip)
	_village = VillageView.new()
	_village.building_selected.connect(_open_panel)
	column.add_child(_village)
	_hero_row = UiKit.hbox()
	column.add_child(_hero_row)
	var start: Button = UiKit.button("START NIGHT", func() -> void: SceneRouter.goto("run"))
	start.custom_minimum_size = Vector2(0.0, 190.0)
	start.add_theme_font_size_override("font_size", UiKit.FONT_BIG)
	column.add_child(start)
	var nav: HBoxContainer = UiKit.hbox(8)
	column.add_child(nav)
	for entry: Array in NAV:
		var screen: String = entry[1]
		var kind: String = "primary" if screen == "home" else "secondary"
		var button: Button = UiKit.button(str(entry[0]), _goto.bind(screen), kind)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 30)
		nav.add_child(button)
		_nav_buttons[screen] = button

	var ticker: Timer = Timer.new()
	ticker.wait_time = 1.0
	ticker.autostart = true
	ticker.timeout.connect(_tick)
	add_child(ticker)
	GameState.changed.connect(_refresh)
	AudioManager.play_music("music_night")
	VillageLogic.complete_due()
	DailyLogic.ensure_today()
	_refresh()
	_maybe_offer_starter_pack()


func _goto(screen: String) -> void:
	if screen != "home":
		SceneRouter.goto(screen)


func _tick() -> void:
	if not VillageLogic.complete_due().is_empty():
		AudioManager.play("levelup")
	_village.queue_redraw()
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
	var portrait: TextureRect = UiKit.icon(hero.texture, 130.0)
	portrait.modulate = Color(str(GameState.selected_skin(hero.id).get("tint", "#ffffff")))
	_hero_row.add_child(portrait)
	var text: VBoxContainer = UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label("%s, %s" % [hero.display_name, hero.title], UiKit.FONT))
	text.add_child(UiKit.label("Village level %d" % VillageLogic.total_level(), UiKit.FONT_SMALL, UiKit.MUTED))
	_hero_row.add_child(text)
	_hero_row.add_child(UiKit.button("Change", func() -> void: SceneRouter.goto("heroes"), "secondary"))
	(_nav_buttons["missions"] as Button).text = "Missions •" if DailyLogic.anything_claimable() else "Missions"
	(_nav_buttons["heroes"] as Button).text = "Heroes •" if GiftLogic.count() > 0 else "Heroes"
	(_nav_buttons["shop"] as Button).text = "Shop •" if ChestLogic.free_remaining() <= 0.0 else "Shop"
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
