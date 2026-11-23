class_name RunUi
extends CanvasLayer
## Everything drawn over a run: joystick, HUD and the modals (level-up, chest,
## pause, revive, results). Talks to RunManager through its signals/methods.

var run: RunManager
var hud: Hud
var _pause_modal: VBoxContainer
var _revive_modal: VBoxContainer
var _revive_left: float = 0.0
var _revive_label: Label


func _ready() -> void:
	layer = 2
	var joystick: Joystick = Joystick.new()
	joystick.run = run
	add_child(joystick)
	hud = Hud.new()
	hud.run = run
	add_child(hud)
	hud.pause_pressed.connect(open_pause)
	run.levelup_requested.connect(_on_levelup)
	run.chest_opened.connect(func(lines: Array[Dictionary]) -> void: LevelupModal.open_chest(self, run, lines))
	run.revive_offered.connect(_open_revive)
	run.run_ended.connect(func(summary: Dictionary) -> void: ResultsScreen.open(self, summary))


## System events (focus lost, app backgrounded, back gesture) arrive while Godot
## is passing the notification down the tree, and nodes cannot gain children
## then ("Parent node is busy setting up children"). Opening the pause menu
## directly used to fail silently while the night was already paused, leaving
## the game stuck; so handle them on the next idle frame instead.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			open_pause.call_deferred()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back.call_deferred()


func _on_back() -> void:
	if _pause_modal != null:
		_resume()
	else:
		open_pause()


func _process(delta: float) -> void:
	if _revive_modal != null:
		_revive_left -= delta
		_revive_label.text = str(maxi(ceili(_revive_left), 0))
		if _revive_left <= 0.0:
			_close_revive()
			run.give_up()


func _on_levelup(cards: Array[Dictionary]) -> void:
	AudioManager.play("levelup")
	AudioManager.haptic()
	run.fx.burst(run.player.position, UiKit.GOLD, 30, 420.0, 9.0, 0.6)
	LevelupModal.open_levelup(self, run, cards)


# --- pause ----------------------------------------------------------------

func open_pause() -> void:
	if run.mode != RunManager.Mode.PLAYING or _pause_modal != null:
		return
	run.set_paused(true)
	_pause_modal = UiKit.modal(self, "Paused")
	var build: HFlowContainer = HFlowContainer.new()
	for id: String in run.state.weapons.keys():
		var tag: String = "EVO" if run.state.evolved.has(id) else str(int(run.state.weapons[id]))
		build.add_child(Hud.build_icon(WeaponLine.weapon_for(id).icon, tag, 130.0))
	for id: String in run.state.passives.keys():
		build.add_child(Hud.build_icon(GameData.passive(id).icon, str(int(run.state.passives[id])), 130.0))
	_pause_modal.add_child(build)
	_pause_modal.add_child(UiKit.button("Resume", _resume))
	_pause_modal.add_child(UiKit.button("Settings", func() -> void:
		var content: VBoxContainer = UiKit.modal(self, "Settings")
		SettingsScreen.add_controls(content)
		content.add_child(UiKit.button("Done", func() -> void:
			GameState.save()
			UiKit.close_modal(content))), "secondary"))
	_pause_modal.add_child(UiKit.button("Quit night", func() -> void:
		UiKit.confirm(self, "Quit?", "The night ends here. You keep what you have earned so far.", "Quit", func() -> void:
			UiKit.close_modal(_pause_modal)
			_pause_modal = null
			run.give_up()), "danger"))


func _resume() -> void:
	if _pause_modal != null:
		UiKit.close_modal(_pause_modal)
		_pause_modal = null
	run.numbers.enabled = bool(GameState.setting("damage_numbers"))
	run.set_paused(false)


# --- revive (spec §9.3) ---------------------------------------------------

func _open_revive() -> void:
	_revive_modal = UiKit.modal(self, "Fallen!")
	_revive_left = GameData.num("run", "revive_countdown")
	_revive_label = UiKit.label("", UiKit.FONT_HUGE, UiKit.AMBER)
	_revive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_revive_modal.add_child(_revive_label)
	var note: Label = UiKit.label("The Lamp Tower can raise you once tonight.", UiKit.FONT_SMALL, UiKit.MUTED, true)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_revive_modal.add_child(note)
	var ad_text: String = "Revive (Ad-Free Pass)" if AdsService.has_ad_free_pass() else "Watch ad to revive"
	var ad: Button = UiKit.button(ad_text, func() -> void:
		_revive_left = INF
		AdsService.show_rewarded("revive", func(rewarded: bool) -> void:
			if rewarded:
				_close_revive()
				run.revive()
			else:
				_revive_left = GameData.num("run", "revive_countdown")), "good")
	ad.disabled = not AdsService.is_ready()
	_revive_modal.add_child(ad)
	var cost: int = Economy.revive_gems()
	var gems: Button = UiKit.button("Revive for %d gems" % cost, func() -> void:
		if GameState.spend("gems", cost):
			GameState.save()
			_close_revive()
			run.revive())
	gems.disabled = GameState.amount("gems") < cost
	_revive_modal.add_child(gems)
	_revive_modal.add_child(UiKit.button("Give up", func() -> void:
		_close_revive()
		run.give_up(), "secondary"))


func _close_revive() -> void:
	if _revive_modal != null:
		UiKit.close_modal(_revive_modal)
		_revive_modal = null
