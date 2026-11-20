class_name LevelupModal
extends RefCounted
## Level-up choice (3 cards + reroll) and the Boss Chest reveal.

const TAG_COLORS: Dictionary = {"NEW": UiKit.GOOD, "EVOLVE": UiKit.DAWN}


static func open_levelup(parent: Node, run: RunManager, cards: Array[Dictionary]) -> VBoxContainer:
	var content: VBoxContainer = UiKit.modal(parent, "Level %d!" % run.state.level)
	for card: Dictionary in cards:
		content.add_child(card_button(BossChest.describe_card(card), func() -> void:
			UiKit.close_modal(content)
			run.choose_card(card)))
	var rerolls: int = run.state.rerolls_left
	var reroll: Button = UiKit.button("Reroll (%d left)" % rerolls, func() -> void:
		UiKit.close_modal(content)
		run.reroll(), "secondary")
	reroll.disabled = rerolls <= 0
	content.add_child(reroll)
	return content


static func open_chest(parent: Node, run: RunManager, lines: Array[Dictionary]) -> VBoxContainer:
	var content: VBoxContainer = UiKit.modal(parent, "Boss Chest")
	for line: Dictionary in lines:
		var card: Button = card_button(line, Callable())
		card.disabled = true
		card.add_theme_stylebox_override("disabled", UiKit.box(UiKit.PANEL_LIGHT, 22, UiKit.GOLD))
		content.add_child(card)
	content.add_child(UiKit.button("Continue", func() -> void:
		UiKit.close_modal(content)
		run.close_chest()))
	return content


## info: {"title", "tag", "desc", "icon"}
static func card_button(info: Dictionary, on_press: Callable) -> Button:
	var card: Button = UiKit.button("", on_press, "secondary")
	card.custom_minimum_size = Vector2(820.0, 230.0)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var line: HBoxContainer = UiKit.hbox(24)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(line)
	line.add_child(UiKit.icon(str(info["icon"]), 150.0))
	var text: VBoxContainer = UiKit.vbox(6)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(text)
	var heading: HBoxContainer = UiKit.hbox(16)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(heading)
	heading.add_child(UiKit.label(str(info["title"]), UiKit.FONT, UiKit.TEXT))
	var tag: String = str(info["tag"])
	if not tag.is_empty():
		var tag_color: Color = TAG_COLORS.get(tag, UiKit.AMBER)
		heading.add_child(UiKit.label(tag, UiKit.FONT_SMALL, tag_color))
	var desc: Label = UiKit.label(str(info["desc"]), UiKit.FONT_SMALL, UiKit.MUTED, true)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(desc)
	return card
