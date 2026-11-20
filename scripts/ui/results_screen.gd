class_name ResultsScreen
extends RefCounted
## End-of-night results (spec §10). Continue is the only place a run's
## rewards are committed to the profile.


static func open(parent: Node, summary: Dictionary) -> void:
	var victory: bool = bool(summary["victory"])
	var content: VBoxContainer = UiKit.modal(parent, "DAWN!" if victory else "Night falls...")
	var sub: Label = UiKit.label("The village is safe." if victory else "The village still gained from your watch.",
		UiKit.FONT_SMALL, UiKit.DAWN if victory else UiKit.MUTED, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(sub)
	var coins: Array[int] = [RunCommit.coins_for(summary)]
	var timber: int = RunCommit.timber_for(summary)
	var seconds: int = int(float(summary["time"]))
	@warning_ignore("integer_division")
	_line(content, "Time survived", "%d:%02d" % [seconds / 60, seconds % 60])
	_line(content, "Creatures defeated", UiKit.number(int(summary["kills"])))
	_line(content, "Level reached", str(int(summary["level"])))
	var coin_value: Label = _line(content, "Coins", UiKit.number(coins[0]))
	_line(content, "Timber", str(timber))
	var gifts: int = int(summary.get("gifts", 0))
	if gifts > 0:
		_line(content, "Hero gifts", "+%d" % gifts)
		var hint: Label = UiKit.label("Open them on the Heroes screen.", UiKit.FONT_SMALL, UiKit.MUTED)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(hint)
	if int(summary.get("potions_used", 0)) > 0:
		_line(content, "Potions used", str(int(summary["potions_used"])))

	var double: Button = UiKit.button("", Callable(), "good")
	double.text = "Double coins (Ad-Free Pass)" if AdsService.has_ad_free_pass() else "Double coins (watch ad)"
	double.disabled = not AdsService.is_ready() or coins[0] <= 0
	double.pressed.connect(func() -> void:
		double.disabled = true
		AdsService.show_rewarded("results_double", func(rewarded: bool) -> void:
			if rewarded:
				coins[0] *= int(GameData.num("economy", "ad_double_mult"))
				coin_value.text = UiKit.number(coins[0])
				double.text = "Coins doubled!"
				AudioManager.play("purchase")
			else:
				double.disabled = false))
	content.add_child(double)
	content.add_child(UiKit.button("Continue", func() -> void:
		RunCommit.commit(summary, coins[0])
		SceneRouter.goto("home")))


static func _line(content: VBoxContainer, title: String, value: String) -> Label:
	var row: HBoxContainer = UiKit.hbox()
	row.custom_minimum_size = Vector2(780.0, 0.0)
	var left: Label = UiKit.label(title, UiKit.FONT, UiKit.MUTED)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var right: Label = UiKit.label(value, UiKit.FONT, UiKit.GOLD)
	row.add_child(right)
	content.add_child(row)
	return right
