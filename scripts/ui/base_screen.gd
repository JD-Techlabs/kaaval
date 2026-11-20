class_name BaseScreen
extends Control
## Common frame for menu screens: background, safe area, header with back
## button + currencies, and a scrolling content column. Subclasses fill
## `content` in build(); refresh() rebuilds after the profile changes.

var title_text: String = ""
var content: VBoxContainer
var _currency_holder: Control
var _refresh_queued: bool = false


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = UiKit.BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = UiKit.vbox(20)
	UiKit.safe_area(self).add_child(column)
	var header: HBoxContainer = UiKit.hbox()
	column.add_child(header)
	var back: Button = UiKit.button("‹", func() -> void: SceneRouter.goto("home"), "secondary")
	back.add_theme_font_size_override("font_size", UiKit.FONT_BIG)
	header.add_child(back)
	var title: Label = UiKit.label(title_text, UiKit.FONT_BIG, UiKit.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_currency_holder = Control.new()
	_currency_holder.custom_minimum_size = Vector2(0.0, 100.0)
	column.add_child(_currency_holder)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	content = UiKit.vbox(20)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	GameState.changed.connect(refresh)
	_rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		SceneRouter.goto("home")


## Rebuilds on the next idle frame (coalesces bursts of profile changes).
func refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_rebuild.call_deferred()


func _rebuild() -> void:
	_refresh_queued = false
	for child: Node in _currency_holder.get_children():
		child.queue_free()
	var bar: HBoxContainer = UiKit.currency_bar(SceneRouter.current != "shop")
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_currency_holder.add_child(bar)
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	build()
	_let_drags_scroll(content)


## Cards, buttons and bars swallow touches by default, which leaves almost
## nowhere to drag the list. Passing touches up lets a drag that starts on any
## of them scroll; a plain tap still presses the button.
static func _let_drags_scroll(node: Node) -> void:
	for child: Node in node.get_children():
		var control: Control = child as Control
		if control != null and control.mouse_filter == Control.MOUSE_FILTER_STOP:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		_let_drags_scroll(child)


## Override: add controls to `content`.
func build() -> void:
	pass


func section(text: String) -> void:
	content.add_child(UiKit.label(text, UiKit.FONT_BIG, UiKit.AMBER))


## A panel row with title + description on the left and one control on the right.
func row(title: String, desc: String, right: Control, icon_path: String = "") -> PanelContainer:
	var card: PanelContainer = UiKit.panel()
	var line: HBoxContainer = UiKit.hbox()
	card.add_child(line)
	if not icon_path.is_empty():
		line.add_child(UiKit.icon(icon_path, 96.0))
	var text: VBoxContainer = UiKit.vbox(6)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	text.add_child(UiKit.label(title, UiKit.FONT, UiKit.TEXT, true))
	if not desc.is_empty():
		text.add_child(UiKit.label(desc, UiKit.FONT_SMALL, UiKit.MUTED, true))
	if right != null:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(right)
	content.add_child(card)
	return card
