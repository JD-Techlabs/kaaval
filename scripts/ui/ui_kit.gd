class_name UiKit
extends RefCounted
## Shared palette, theme and small widget builders so every screen looks the
## same and meets the 48 dp touch-target rule (126 px at 1080 wide).

const BG: Color = Color("0e1326")
const PANEL: Color = Color("1a2140")
const PANEL_LIGHT: Color = Color("27315c")
const AMBER: Color = Color("ffb347")
const EMBER: Color = Color("ff8a2a")
const TEAL: Color = Color("3f8f8a")
const TEXT: Color = Color("f6eeda")
const MUTED: Color = Color("9aa3c0")
const DANGER: Color = Color("e2553d")
const GOOD: Color = Color("6fe08a")
const GOLD: Color = Color("ffd36b")
const DAWN: Color = Color("ff9e8a")
const DARK_TEXT: Color = Color("1b1408")

const TOUCH: float = 128.0
const FONT: int = 38
const FONT_SMALL: int = 30
const FONT_BIG: int = 56
const FONT_HUGE: int = 84
const ICON_DIR: String = "res://assets/sprites/icons/"

static var _theme: Theme


static func box(color: Color, radius: int = 22, border: Color = Color.TRANSPARENT, pad: int = 22) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(pad)
	if border.a > 0.0:
		style.set_border_width_all(4)
		style.border_color = border
	return style


static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = FONT
	_theme.set_color("font_color", "Label", TEXT)
	_theme.set_stylebox("normal", "Button", box(AMBER))
	_theme.set_stylebox("hover", "Button", box(AMBER.lightened(0.1)))
	_theme.set_stylebox("pressed", "Button", box(EMBER))
	_theme.set_stylebox("disabled", "Button", box(PANEL_LIGHT))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_theme.set_color(state, "Button", DARK_TEXT)
	_theme.set_color("font_disabled_color", "Button", MUTED)
	_theme.set_stylebox("panel", "PanelContainer", box(PANEL))
	_theme.set_stylebox("background", "ProgressBar", box(Color(0, 0, 0, 0.45), 12, Color.TRANSPARENT, 0))
	_theme.set_stylebox("fill", "ProgressBar", box(GOOD, 12, Color.TRANSPARENT, 0))
	_theme.set_stylebox("slider", "HSlider", box(PANEL_LIGHT, 10, Color.TRANSPARENT, 10))
	_theme.set_stylebox("grabber_area", "HSlider", box(AMBER, 10, Color.TRANSPARENT, 10))
	_theme.set_stylebox("grabber_area_highlight", "HSlider", box(AMBER, 10, Color.TRANSPARENT, 10))
	_theme.set_constant("separation", "VBoxContainer", 18)
	_theme.set_constant("separation", "HBoxContainer", 18)
	return _theme


static func label(text: String, size: int = FONT, color: Color = TEXT, wrap: bool = false) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


## kind: "primary" (amber), "secondary" (panel), "danger", "good"
static func button(text: String, on_press: Callable, kind: String = "primary") -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(TOUCH, TOUCH)
	node.focus_mode = Control.FOCUS_NONE
	var color: Color = AMBER
	var font: Color = DARK_TEXT
	match kind:
		"secondary":
			color = PANEL_LIGHT
			font = TEXT
		"danger":
			color = DANGER
			font = TEXT
		"good":
			color = GOOD
	if kind != "primary":
		node.add_theme_stylebox_override("normal", box(color))
		node.add_theme_stylebox_override("hover", box(color.lightened(0.08)))
		node.add_theme_stylebox_override("pressed", box(color.darkened(0.15)))
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			node.add_theme_color_override(state, font)
	if on_press.is_valid():
		node.pressed.connect(func() -> void:
			AudioManager.play("click")
			on_press.call())
	return node


static func panel(color: Color = PANEL, border: Color = Color.TRANSPARENT) -> PanelContainer:
	var node: PanelContainer = PanelContainer.new()
	node.add_theme_stylebox_override("panel", box(color, 22, border))
	return node


static func icon(path: String, size: float = 72.0) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.texture = load(path) as Texture2D
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(size, size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func vbox(separation: int = 18) -> VBoxContainer:
	var node: VBoxContainer = VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 18) -> HBoxContainer:
	var node: HBoxContainer = HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func spacer() -> Control:
	var node: Control = Control.new()
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func bar(color: Color, height: float = 34.0) -> ProgressBar:
	var node: ProgressBar = ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0.0, height)
	node.add_theme_stylebox_override("fill", box(color, 12, Color.TRANSPARENT, 0))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Full-rect container inset by the device safe area (notches, gesture bar).
static func safe_area(parent: Control, extra: int = 28) -> MarginContainer:
	var node: MarginContainer = MarginContainer.new()
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var insets: Array[float] = [0.0, 0.0, 0.0, 0.0]
	if OS.has_feature("mobile"):
		var window: Vector2 = Vector2(DisplayServer.window_get_size())
		var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
		var view: Vector2 = parent.get_viewport_rect().size
		if window.x > 0.0 and window.y > 0.0:
			var scale: Vector2 = view / window
			insets = [safe.position.x * scale.x, safe.position.y * scale.y,
				maxf(window.x - safe.end.x, 0.0) * scale.x, maxf(window.y - safe.end.y, 0.0) * scale.y]
	node.add_theme_constant_override("margin_left", int(insets[0]) + extra)
	node.add_theme_constant_override("margin_top", int(insets[1]) + extra)
	node.add_theme_constant_override("margin_right", int(insets[2]) + extra)
	node.add_theme_constant_override("margin_bottom", int(insets[3]) + extra)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


## Dimmed full-screen modal. Returns the VBox to fill; free `.get_meta("root")` to close.
static func modal(parent: Node, title: String = "") -> VBoxContainer:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = theme()
	parent.add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var margin: MarginContainer = safe_area(root, 60)
	var center: VBoxContainer = vbox()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(center)
	var card: PanelContainer = panel(PANEL, AMBER.darkened(0.3))
	center.add_child(card)
	var content: VBoxContainer = vbox(22)
	card.add_child(content)
	if not title.is_empty():
		var heading: Label = label(title, FONT_BIG, GOLD)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(heading)
	content.set_meta("root", root)
	return content


static func close_modal(content: VBoxContainer) -> void:
	var root: Node = content.get_meta("root") as Node
	if is_instance_valid(root):
		root.queue_free()


const LONG_MESSAGE_CHARS: int = 600
const LONG_MESSAGE_LINES: int = 16
const LONG_MESSAGE_HEIGHT: float = 1150.0


## Simple message box with one button. Long text scrolls.
static func message(parent: Node, title: String, text: String, on_close: Callable = Callable()) -> void:
	var content: VBoxContainer = modal(parent, title)
	var body: Label = label(text, FONT, TEXT, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if text.length() > LONG_MESSAGE_CHARS or text.count("
") > LONG_MESSAGE_LINES:
		# Long text (credits, licences) scrolls inside the box so OK stays on screen.
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(0.0, LONG_MESSAGE_HEIGHT)
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		scroll.add_child(body)
		content.add_child(scroll)
	else:
		content.add_child(body)
	content.add_child(button("OK", func() -> void:
		close_modal(content)
		if on_close.is_valid():
			on_close.call()))


static func confirm(parent: Node, title: String, text: String, yes_text: String, on_yes: Callable) -> void:
	var content: VBoxContainer = modal(parent, title)
	var body: Label = label(text, FONT, TEXT, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(body)
	content.add_child(button(yes_text, func() -> void:
		close_modal(content)
		on_yes.call(), "danger"))
	content.add_child(button("Cancel", func() -> void: close_modal(content), "secondary"))


static func rewards_text(rewards: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for kind: String in ["coins", "timber", "gems", "potions"]:
		if rewards.has(kind):
			parts.append("%s %s" % [number(int(rewards[kind])), kind])
	return ", ".join(parts)


## 12345 -> "12,345"
static func number(value: int) -> String:
	var text: String = str(absi(value))
	var out: String = ""
	while text.length() > 3:
		out = "," + text.substr(text.length() - 3) + out
		text = text.substr(0, text.length() - 3)
	return ("-" if value < 0 else "") + text + out


## 3725 -> "1h 02m", 75 -> "1:15"
static func duration(seconds: float) -> String:
	var total: int = ceili(seconds)
	@warning_ignore("integer_division")
	var hours: int = total / 3600
	@warning_ignore("integer_division")
	var minutes: int = (total % 3600) / 60
	if hours > 0:
		return "%dh %02dm" % [hours, minutes]
	return "%d:%02d" % [minutes, total % 60]


## Coins / timber / gems strip; "+" opens the shop.
static func currency_bar(show_plus: bool = true) -> HBoxContainer:
	var row: HBoxContainer = hbox(14)
	for kind: String in ["coins", "timber", "gems"]:
		var chip: PanelContainer = panel(Color(0, 0, 0, 0.35))
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inner: HBoxContainer = hbox(10)
		chip.add_child(inner)
		inner.add_child(icon(ICON_DIR + {"coins": "coin", "timber": "timber", "gems": "gem"}[kind] + ".svg", 52.0))
		var value: Label = label(number(GameState.amount(kind)), FONT_SMALL)
		value.name = kind
		inner.add_child(value)
		row.add_child(chip)
	if show_plus:
		var plus: Button = button("+", func() -> void: SceneRouter.goto("shop"))
		plus.custom_minimum_size = Vector2(TOUCH, 96.0)
		row.add_child(plus)
	return row
