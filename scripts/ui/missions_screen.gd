class_name MissionsScreen
extends BaseScreen
## Missions (spec §8.5, §10): login calendar, daily missions, achievements.


func _init() -> void:
	title_text = "Missions"


func build() -> void:
	_calendar()
	section("Daily missions")
	var list: Array = DailyLogic.missions()
	for i: int in list.size():
		_mission(i, list[i])
	content.add_child(UiKit.label("New missions at midnight.", UiKit.FONT_SMALL, UiKit.MUTED))
	section("Achievements")
	for def: Dictionary in DailyLogic.achievements():
		_achievement(def)


func _calendar() -> void:
	section("Daily login")
	var days: HBoxContainer = UiKit.hbox(8)
	content.add_child(days)
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
		var icon_name: String = {"coins": "coin", "timber": "timber", "gems": "gem"}[kind]
		column.add_child(UiKit.icon(UiKit.ICON_DIR + icon_name + ".svg", 56.0))
		var value: Label = UiKit.label("✓" if claimed else str(int(rewards[kind])), 26, UiKit.GOOD if claimed else UiKit.TEXT)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		days.add_child(cell)
	var claim: Button = UiKit.button("Claim today's reward" if available else "Come back tomorrow", func() -> void:
		var rewards: Dictionary = DailyLogic.claim_login()
		if not rewards.is_empty():
			AudioManager.play("purchase")
			UiKit.message(self, "Daily reward", "You received %s." % UiKit.rewards_text(rewards)), "good")
	claim.disabled = not available
	content.add_child(claim)


func _mission(index: int, entry: Dictionary) -> void:
	var def: Dictionary = DailyLogic.mission_def(str(entry["id"]))
	var target: int = int(def["target"])
	var progress: int = mini(int(entry["progress"]), target)
	var reward: String = "%d coins + %d gems" % [int(def["coins"]), int(GameData.num("economy", "mission_reward_gems"))]
	var right: Button
	if bool(entry["claimed"]):
		right = UiKit.button("Done", Callable(), "secondary")
		right.disabled = true
	else:
		right = UiKit.button("Claim", func() -> void:
			if DailyLogic.claim_mission(index):
				AudioManager.play("purchase"), "good")
		right.disabled = not DailyLogic.mission_complete(entry)
	right.custom_minimum_size = Vector2(200.0, UiKit.TOUCH)
	row(str(def["text"]), "%s / %s  ·  %s" % [UiKit.number(progress), UiKit.number(target), reward], right)


func _achievement(def: Dictionary) -> void:
	var id: String = str(def["id"])
	var target: int = int(def["target"])
	var progress: int = mini(GameState.stat(str(def["stat"])), target)
	var right: Button
	if DailyLogic.achievement_claimed(id):
		right = UiKit.button("Done", Callable(), "secondary")
		right.disabled = true
	else:
		right = UiKit.button("%d gems" % int(def["gems"]), func() -> void:
			if DailyLogic.claim_achievement(id):
				AudioManager.play("purchase"), "good")
		right.disabled = not DailyLogic.achievement_done(def)
	right.custom_minimum_size = Vector2(200.0, UiKit.TOUCH)
	row(str(def["text"]), "%s / %s" % [UiKit.number(progress), UiKit.number(target)], right)
