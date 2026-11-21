class_name SettingsScreen
extends BaseScreen
## Settings (spec §10). add_controls() is shared with the in-run pause menu.


func _init() -> void:
	title_text = "Settings"


func build() -> void:
	add_controls(content)
	var app: Dictionary = GameData.json("app_config")
	var language: OptionButton = OptionButton.new()
	language.add_item("English")
	language.custom_minimum_size = Vector2(300.0, UiKit.TOUCH)
	row("Language", "More languages are planned.", language)
	row("Privacy policy", "", UiKit.button("Open", func() -> void: OS.shell_open(str(app["privacy_policy_url"])), "secondary"))
	if AdsService.privacy_options_required():
		row("Ad privacy choices", "", UiKit.button("Review", AdsService.show_privacy_options, "secondary"))
	row("Support", str(app["support_email"]), UiKit.button("Email", func() -> void:
		OS.shell_open("mailto:%s" % str(app["support_email"])), "secondary"))
	row("How to play", "The goal, controls, bosses and nights.", UiKit.button("Open", func() -> void:
		HowToPlay.open(self), "secondary"))
	row("Credits", "", UiKit.button("View", func() -> void:
		UiKit.message(self, "Credits", _credits_text()), "secondary"))
	content.add_child(UiKit.label("Version %s" % str(ProjectSettings.get_setting("application/config/version")),
		UiKit.FONT_SMALL, UiKit.MUTED))


func refresh() -> void:
	# Sliders write to GameState while being dragged; do not rebuild under the finger.
	pass


func _exit_tree() -> void:
	GameState.save()


static func _credits_text() -> String:
	var path: String = "res://CREDITS.md"
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path).replace("#", "").replace("|", " ").replace("---", "").strip_edges()
	return "KAAVAL: Guardians of Dawn"


## Music / SFX / haptics / damage numbers / joystick size controls.
static func add_controls(target: VBoxContainer) -> void:
	target.add_child(_slider("Music", "music_volume", 0.0, 1.0))
	target.add_child(_slider("Sound effects", "sfx_volume", 0.0, 1.0))
	target.add_child(_slider("Joystick size", "joystick_size", 0.7, 1.5))
	target.add_child(_toggle("Haptics", "haptics"))
	target.add_child(_toggle("Damage numbers", "damage_numbers"))
	# Developer overlay (FPS, entity counts): debug builds only, off by default.
	if OS.is_debug_build():
		target.add_child(_toggle("Developer overlay", "debug_overlay"))


static func _slider(title: String, key: String, low: float, high: float) -> Control:
	var line: HBoxContainer = UiKit.hbox()
	var text: Label = UiKit.label(title)
	text.custom_minimum_size = Vector2(330.0, 0.0)
	line.add_child(text)
	var slider: HSlider = HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.05
	slider.value = float(GameState.setting(key))
	slider.custom_minimum_size = Vector2(380.0, UiKit.TOUCH)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void: GameState.set_setting(key, value))
	line.add_child(slider)
	return line


static func _toggle(title: String, key: String) -> Control:
	var line: HBoxContainer = UiKit.hbox()
	var text: Label = UiKit.label(title)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	var states: Array[bool] = [bool(GameState.setting(key))]
	var toggle: Button = UiKit.button("On" if states[0] else "Off", Callable(), "good" if states[0] else "secondary")
	toggle.custom_minimum_size = Vector2(220.0, UiKit.TOUCH)
	toggle.pressed.connect(func() -> void:
		states[0] = not states[0]
		GameState.set_setting(key, states[0])
		toggle.text = "On" if states[0] else "Off"
		var color: Color = UiKit.GOOD if states[0] else UiKit.PANEL_LIGHT
		toggle.add_theme_stylebox_override("normal", UiKit.box(color))
		toggle.add_theme_stylebox_override("hover", UiKit.box(color))
		toggle.add_theme_color_override("font_color", UiKit.DARK_TEXT if states[0] else UiKit.TEXT)
		toggle.add_theme_color_override("font_hover_color", UiKit.DARK_TEXT if states[0] else UiKit.TEXT)
		AudioManager.play("click")
		if key == "haptics" and states[0]:
			AudioManager.haptic())
	line.add_child(toggle)
	return line
