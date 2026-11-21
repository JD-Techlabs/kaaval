class_name AgePanel
extends RefCounted
## The village's age: resources held, what the next age needs, and Advance.

const ROW_WIDTH: float = 780.0


## One line for the home screen button.
static func summary_text() -> String:
	var age: AgeData = AgeLogic.current()
	var text: String = "%s · %d/%d" % [age.display_name, AgeLogic.number(age.id), AgeLogic.ages().size()]
	if AgeLogic.next_age() != null:
		text += "  ▸ Ready to advance!" if AgeLogic.blocker().is_empty() else "  ▸ Next age"
	return text


static func open(parent: Node, on_close: Callable) -> VBoxContainer:
	var age: AgeData = AgeLogic.current()
	var content: VBoxContainer = UiKit.modal(parent, age.display_name)
	content.custom_minimum_size = Vector2(840.0, 0.0)
	_centered(content, "Age %d of %d · buildings up to level %d" % [AgeLogic.number(age.id), AgeLogic.ages().size(), age.building_cap],
		UiKit.FONT_SMALL, UiKit.AMBER)
	_centered(content, age.tagline, UiKit.FONT_SMALL, UiKit.MUTED)
	content.add_child(_resource_strip(age.resources))

	var next: AgeData = AgeLogic.next_age()
	if next == null:
		_centered(content, "The village has reached its final age.", UiKit.FONT, UiKit.GOLD)
	else:
		_centered(content, "Next: " + next.display_name, UiKit.FONT, UiKit.GOOD)
		_centered(content, _unlocks_text(age, next), UiKit.FONT_SMALL, UiKit.MUTED)
		for id: String in next.required_buildings.keys():
			var need: int = int(next.required_buildings[id])
			var have: int = GameState.building_level(id)
			_row(content, "%s Lv %d" % [GameData.building(id).display_name, need], "%d/%d" % [mini(have, need), need], have >= need)
		for kind: String in next.advance_cost.keys():
			var cost: int = int(next.advance_cost[kind])
			var held: int = GameState.amount(kind)
			_row(content, "%s %s" % [UiKit.number(cost), UiKit.resource_name(kind)], "%s/%s" % [UiKit.number(mini(held, cost)), UiKit.number(cost)], held >= cost)
		var blocker: String = AgeLogic.blocker()
		var advance: Button = UiKit.button("Advance to " + next.display_name, func() -> void:
			if AgeLogic.advance():
				AudioManager.play("levelup")
				UiKit.close_modal(content)
				_closed(on_close), "good")
		if not blocker.is_empty():
			advance.disabled = true
			advance.text = blocker
		content.add_child(advance)
	content.add_child(UiKit.button("Close", func() -> void:
		UiKit.close_modal(content)
		_closed(on_close), "secondary"))
	return content


## "opens stone · buildings up to level 4"
static func _unlocks_text(age: AgeData, next: AgeData) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for kind: String in next.resources:
		if not age.resources.has(kind):
			parts.append("opens " + UiKit.resource_name(kind))
	parts.append("buildings up to level %d" % next.building_cap)
	return " · ".join(parts)


static func _resource_strip(kinds: Array[String]) -> HFlowContainer:
	var flow: HFlowContainer = HFlowContainer.new()
	flow.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)
	flow.add_theme_constant_override("h_separation", 18)
	for kind: String in kinds:
		var chip: HBoxContainer = UiKit.hbox(8)
		chip.add_child(UiKit.icon(UiKit.resource_icon(kind), 52.0))
		chip.add_child(UiKit.label(UiKit.number(GameState.amount(kind)), UiKit.FONT_SMALL))
		flow.add_child(chip)
	return flow


static func _row(content: VBoxContainer, title: String, value: String, done: bool) -> void:
	var row: HBoxContainer = UiKit.hbox()
	row.custom_minimum_size = Vector2(ROW_WIDTH, 0.0)
	var left: Label = UiKit.label(("✓ " if done else "• ") + title, UiKit.FONT_SMALL, UiKit.TEXT)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	row.add_child(UiKit.label(value, UiKit.FONT_SMALL, UiKit.GOOD if done else UiKit.DANGER))
	content.add_child(row)


static func _centered(content: VBoxContainer, text: String, font_size: int, color: Color) -> Label:
	var node: Label = UiKit.label(text, font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(node)
	return node


static func _closed(on_close: Callable) -> void:
	if on_close.is_valid():
		on_close.call()
