class_name NightPicker
extends PanelContainer
## Home screen card for choosing a night: arrows step through every night,
## locked ones included so the player sees what is ahead. Shows the goal, the
## bosses and the best time. `changed` fires when the shown night changes.

signal changed

## Index into NightLogic.nights() of the night on show.
var index: int = 0
## True inside another card (home "tonight" card): no frame of its own.
var embedded: bool = false
var _title: Label
var _goal: Label
var _detail: Label
var _prev: Button
var _next: Button


func _ready() -> void:
	if embedded:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 22, UiKit.AMBER.darkened(0.4), 16))
	var row: HBoxContainer = UiKit.hbox(12)
	add_child(row)
	_prev = UiKit.button("‹", _step.bind(-1), "secondary")
	_prev.custom_minimum_size = Vector2(UiKit.TOUCH, UiKit.TOUCH)
	_prev.add_theme_font_size_override("font_size", UiKit.FONT_BIG)
	row.add_child(_prev)
	var text: VBoxContainer = UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	_title = _centred(text, UiKit.FONT, UiKit.GOLD)
	_goal = _centred(text, UiKit.FONT_SMALL, UiKit.TEXT)
	_detail = _centred(text, 26, UiKit.MUTED)
	_next = UiKit.button("›", _step.bind(1), "secondary")
	_next.custom_minimum_size = Vector2(UiKit.TOUCH, UiKit.TOUCH)
	_next.add_theme_font_size_override("font_size", UiKit.FONT_BIG)
	row.add_child(_next)
	index = maxi(NightLogic.number(NightLogic.selected().id) - 1, 0)
	refresh()


static func _centred(parent: Control, font_size: int, color: Color) -> Label:
	var node: Label = UiKit.label("", font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(node)
	return node


func shown() -> WaveData:
	return NightLogic.nights()[index]


func is_playable() -> bool:
	return NightLogic.is_unlocked(shown().id)


func _step(direction: int) -> void:
	index = clampi(index + direction, 0, NightLogic.nights().size() - 1)
	if NightLogic.select(shown().id):
		GameState.save()
	refresh()
	changed.emit()


func refresh() -> void:
	var count: int = NightLogic.nights().size()
	var wave: WaveData = shown()
	_prev.disabled = index <= 0
	_next.disabled = index >= count - 1
	_title.text = "Night %d of %d · %s" % [index + 1, count, wave.display_name]
	if not is_playable():
		var before: WaveData = NightLogic.nights()[index - 1]
		_goal.text = "Locked: reach dawn in Night %d (%s) to unlock" % [index, before.display_name]
		_detail.text = wave.tagline
		return
	var best: float = NightLogic.best_time(wave.id)
	var record: String = "Cleared!" if NightLogic.won(wave.id) else ("Best %s" % NightLogic.clock(best) if best > 0.0 else "Not tried yet")
	_goal.text = "Goal: survive until dawn (%s) · %s" % [NightLogic.clock(wave.duration), record]
	_detail.text = "Bosses: %s" % NightLogic.boss_schedule(wave)
