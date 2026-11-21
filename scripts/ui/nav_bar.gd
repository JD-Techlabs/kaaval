class_name NavBar
extends RefCounted
## The bottom navigation bar shown on the home screen and every menu screen,
## so moving between screens is always within thumb reach.

## Bottom navigation: [label, screen, icon]. Shared by the home screen and every menu screen.
const NAV: Array[Array] = [["Village", "home", "nav_village"], ["Heroes", "heroes", "nav_heroes"],
	["Shop", "shop", "nav_shop"], ["Missions", "missions", "nav_missions"], ["Settings", "settings", "nav_settings"]]
const NAV_HEIGHT: float = 150.0
const NAV_ICON: int = 56


## Bottom navigation bar with icons; `current` is highlighted. `badges` marks
## screens with something waiting ({screen: true}). Thumb-reachable on a phone.
static func build(current: String, badges: Dictionary = {}) -> PanelContainer:
	var bar_panel: PanelContainer = PanelContainer.new()
	bar_panel.add_theme_stylebox_override("panel", UiKit.box(Color("141a33"), 26, UiKit.PANEL_LIGHT, 8))
	var row: HBoxContainer = UiKit.hbox(6)
	bar_panel.add_child(row)
	for entry: Array in NAV:
		var screen: String = entry[1]
		var active: bool = screen == current
		var item: Button = Button.new()
		item.text = str(entry[0]) + (" •" if bool(badges.get(screen, false)) else "")
		item.icon = load(UiKit.ICON_DIR + str(entry[2]) + ".svg") as Texture2D
		item.expand_icon = true
		item.add_theme_constant_override("icon_max_width", NAV_ICON)
		item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		item.custom_minimum_size = Vector2(0.0, NAV_HEIGHT)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.focus_mode = Control.FOCUS_NONE
		item.name = screen
		item.add_theme_font_size_override("font_size", 28)
		var fill: Color = UiKit.AMBER if active else Color(0, 0, 0, 0)
		var text_color: Color = UiKit.DARK_TEXT if active else UiKit.MUTED
		for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			item.add_theme_stylebox_override(state, UiKit.box(fill if state != "pressed" else UiKit.PANEL_LIGHT, 20, Color.TRANSPARENT, 10))
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			item.add_theme_color_override(state, text_color)
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			item.add_theme_color_override(state, UiKit.DARK_TEXT if active else UiKit.MUTED)
		if not active:
			item.pressed.connect(func() -> void:
				AudioManager.play("click")
				SceneRouter.goto(screen))
		row.add_child(item)
	return bar_panel


## Screens with something waiting: missions to claim, hero gifts, a free chest.
static func badges() -> Dictionary:
	return {"missions": DailyLogic.anything_claimable(), "heroes": GiftLogic.count() > 0,
		"shop": ChestLogic.free_remaining() <= 0.0}
