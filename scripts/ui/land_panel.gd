class_name LandPanel
extends RefCounted
## Land for sale: what it holds, what it needs, and Buy.


static func open(parent: Node, id: String) -> VBoxContainer:
	var land: LandData = GameData.land(id)
	var content: VBoxContainer = UiKit.modal(parent, land.display_name)
	content.custom_minimum_size = Vector2(840.0, 0.0)
	_centered(content, land.description, UiKit.FONT_SMALL, UiKit.MUTED)
	var names: PackedStringArray = PackedStringArray()
	for data: BuildingData in LandLogic.buildings_on(id):
		names.append(data.display_name)
	_centered(content, "Room for: " + ", ".join(names), UiKit.FONT, UiKit.TEXT)
	_centered(content, "Price: %s coins · from the %s" % [UiKit.number(land.coin_cost), AgeLogic.age(land.required_age).display_name],
		UiKit.FONT_SMALL, UiKit.GOLD)
	var blocker: String = LandLogic.blocker(id)
	var buy: Button = UiKit.button("Buy for %s coins" % UiKit.number(land.coin_cost), func() -> void:
		if LandLogic.buy(id):
			AudioManager.play("purchase")
			UiKit.close_modal(content), "good")
	if not blocker.is_empty():
		buy.disabled = true
		buy.text = blocker
	content.add_child(buy)
	content.add_child(UiKit.button("Close", func() -> void: UiKit.close_modal(content), "secondary"))
	return content


static func _centered(content: VBoxContainer, text: String, font_size: int, color: Color) -> void:
	var node: Label = UiKit.label(text, font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(node)
