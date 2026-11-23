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
	content.add_child(DailyPopup.calendar_strip())
	var available: bool = DailyLogic.login_available()
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
