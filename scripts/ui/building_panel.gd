class_name BuildingPanel
extends RefCounted
## Building details: current bonus, next bonus, cost, upgrade / skip timer.


static func open(parent: Node, id: String, on_close: Callable) -> VBoxContainer:
	var data: BuildingData = GameData.building(id)
	var level: int = GameState.building_level(id)
	var content: VBoxContainer = UiKit.modal(parent, data.display_name)
	content.custom_minimum_size = Vector2(840.0, 0.0)
	var level_text: String = "Not built yet" if level == 0 else "Level %d / %d" % [level, data.max_level]
	_centered(content, level_text, UiKit.FONT, UiKit.AMBER)
	_centered(content, data.description, UiKit.FONT_SMALL, UiKit.MUTED)
	if level > 0:
		_centered(content, "Now: " + data.describe(level), UiKit.FONT, UiKit.TEXT)
	_production(content, data)
	var job: Dictionary = VillageLogic.job_for(id)
	if level < data.max_level:
		var target: int = level + 1
		_centered(content, "Next: " + data.describe(target), UiKit.FONT, UiKit.GOOD)
		if job.is_empty():
			var cost: String = "%s coins" % UiKit.number(Economy.building_coin_cost(target))
			var timber: int = Economy.building_timber_cost(target)
			if timber > 0:
				cost += " + %d timber" % timber
			var extra: Dictionary = Economy.building_resource_costs(data, target)
			for kind: String in extra.keys():
				cost += " + %s %s" % [UiKit.number(int(extra[kind])), UiKit.resource_name(kind)]
			var seconds: float = Economy.build_seconds(target, RemoteConfig.num("build_timer_multiplier"))
			var time_text: String = "instant" if seconds <= 0.0 else UiKit.duration(seconds)
			_centered(content, "Cost: %s  ·  Build time: %s" % [cost, time_text], UiKit.FONT_SMALL, UiKit.GOLD)
			var blocker: String = VillageLogic.blocker(id)
			var upgrade: Button = UiKit.button("Build" if level == 0 else "Upgrade", func() -> void:
				if VillageLogic.start(id):
					AudioManager.play("purchase"))
			if not blocker.is_empty():
				upgrade.disabled = true
				upgrade.text = blocker
			content.add_child(upgrade)
		else:
			var timer: Label = _centered(content, "", UiKit.FONT_BIG, UiKit.AMBER)
			timer.name = "Timer"
			var skip: Button = UiKit.button("", func() -> void:
				if VillageLogic.skip(id):
					AudioManager.play("purchase"), "good")
			skip.name = "Skip"
			content.add_child(skip)
			update_timer(content, id)
	else:
		_centered(content, "Fully upgraded", UiKit.FONT, UiKit.GOLD)
	content.add_child(UiKit.button("Close", func() -> void:
		UiKit.close_modal(content)
		on_close.call(), "secondary"))
	return content


## Stored output and Collect for buildings that make resources.
static func _production(content: VBoxContainer, data: BuildingData) -> void:
	if data.produces.is_empty() or GameState.building_level(data.id) <= 0:
		return
	var kind: String = UiKit.resource_name(data.produces)
	if not AgeLogic.open_resources().has(data.produces):
		var opens: String = ""
		for age: AgeData in AgeLogic.ages():
			if age.resources.has(data.produces):
				opens = age.display_name
				break
		_centered(content, "Starts making %s in the %s." % [kind, opens], UiKit.FONT_SMALL, UiKit.MUTED)
		return
	var ready: int = ProductionLogic.ready(data)
	_centered(content, "Stored: %s / %s %s" % [UiKit.number(ready), UiKit.number(ProductionLogic.capacity(data)), kind],
		UiKit.FONT_SMALL, UiKit.GOLD)
	var collect: Button = UiKit.button("Collect %s %s" % [UiKit.number(ready), kind], func() -> void:
		if ProductionLogic.collect(data) > 0:
			GameState.save()
			AudioManager.play("purchase"), "good")
	collect.disabled = ready <= 0
	content.add_child(collect)


## Refreshes the countdown and gem price while a build is running.
static func update_timer(content: VBoxContainer, id: String) -> void:
	var timer: Label = content.get_node_or_null("Timer") as Label
	var skip: Button = content.get_node_or_null("Skip") as Button
	if timer == null or skip == null:
		return
	var job: Dictionary = VillageLogic.job_for(id)
	timer.text = "Building… " + UiKit.duration(VillageLogic.remaining(job))
	var cost: int = VillageLogic.skip_cost(id)
	skip.text = "Finish now (%d gems)" % cost
	skip.disabled = GameState.amount("gems") < cost


static func _centered(content: VBoxContainer, text: String, font_size: int, color: Color) -> Label:
	var node: Label = UiKit.label(text, font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(node)
	return node
