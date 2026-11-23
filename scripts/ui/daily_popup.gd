class_name DailyPopup
extends RefCounted
## "Welcome back": the 7-day login calendar with today's Claim, and today's
## missions, shown on the home screen once a day (see Onboarding). The
## calendar strip is shared with the Missions screen.

const CELL_ICON: float = 56.0


## Seven day cells: claimed days ticked, the next claim outlined in gold.
static func calendar_strip() -> HBoxContainer:
	var days: HBoxContainer = UiKit.hbox(8)
	var next_index: int = DailyLogic.login_day_index()
	var available: bool = DailyLogic.login_available()
	var calendar: Array = DailyLogic.calendar()
	for i: int in calendar.size():
		var entry: Dictionary = calendar[i]
		var claimed: bool = i < next_index or (not available and next_index == 0)
		var is_next: bool = i == next_index and available
		var cell: PanelContainer = UiKit.panel(UiKit.PANEL_LIGHT if claimed else UiKit.PANEL, UiKit.GOLD if is_next else Color.TRANSPARENT)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var column: VBoxContainer = UiKit.vbox(4)
		cell.add_child(column)
		var day: Label = UiKit.label("Day %d" % int(entry["day"]), 24, UiKit.MUTED)
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(day)
		var rewards: Dictionary = entry["rewards"]
		var kind: String = str(rewards.keys()[0])
		column.add_child(UiKit.icon(UiKit.resource_icon(kind), CELL_ICON))
		var value: Label = UiKit.label("✓" if claimed else str(int(rewards[kind])), 26, UiKit.GOOD if claimed else UiKit.TEXT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		days.add_child(cell)
	return days


static func open(parent: Node) -> void:
	Onboarding.mark_daily_popup_shown()
	var content: VBoxContainer = UiKit.modal(parent, "Welcome back!")
	content.custom_minimum_size = Vector2(900.0, 0.0)
	_centered(content, "Daily reward · day %d of %d" % [DailyLogic.login_day_index() + 1, DailyLogic.calendar().size()], UiKit.FONT, UiKit.AMBER)
	content.add_child(calendar_strip())
	content.add_child(UiKit.button("Claim today's reward", func() -> void:
		var rewards: Dictionary = DailyLogic.claim_login()
		UiKit.close_modal(content)
		if not rewards.is_empty():
			AudioManager.play("purchase")
			UiKit.message(parent, "Daily reward", "You received %s." % UiKit.rewards_text(rewards)), "good"))
	_centered(content, "Today's missions", UiKit.FONT, UiKit.AMBER)
	for entry: Dictionary in DailyLogic.missions():
		var def: Dictionary = DailyLogic.mission_def(str(entry["id"]))
		var target: int = int(def["target"])
		var progress: int = mini(int(entry["progress"]), target)
		var line: HBoxContainer = UiKit.hbox()
		var text: Label = UiKit.label(("✓ " if DailyLogic.mission_complete(entry) else "• ") + str(def["text"]), UiKit.FONT_SMALL, UiKit.TEXT, true)
		line.add_child(text)
		line.add_child(UiKit.label("%s / %s" % [UiKit.number(progress), UiKit.number(target)], UiKit.FONT_SMALL, UiKit.MUTED))
		content.add_child(line)
	content.add_child(UiKit.button("Later", func() -> void: UiKit.close_modal(content), "secondary"))


static func _centered(content: VBoxContainer, text: String, font_size: int, color: Color) -> void:
	var node: Label = UiKit.label(text, font_size, color, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(node)
