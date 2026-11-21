class_name HeroesScreen
extends BaseScreen
## Hero select (spec §10): hero cards, stats, skin picker, unlock button,
## plus Hero Gifts and hero-piece progress.

const GIFT_ICON: String = "res://assets/sprites/gift.svg"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	title_text = "Heroes"


func _ready() -> void:
	_rng.randomize()
	super._ready()
	BillingService.purchase_succeeded.connect(func(_id: String) -> void: refresh())
	BillingService.purchase_failed.connect(_on_purchase_failed)
	BillingService.prices_updated.connect(refresh)


func _on_purchase_failed(_product_id: String, reason: String) -> void:
	if reason != "cancelled":
		UiKit.message(self, "Purchase failed", ShopScreen.failure_text(reason))


func build() -> void:
	_gift_card()
	for hero: HeroData in GameData.heroes():
		_hero_card(hero)


func _gift_card() -> void:
	var levels: PackedStringArray = PackedStringArray()
	for level: int in GiftLogic.run_levels():
		levels.append(str(level))
	var buttons: VBoxContainer = UiKit.vbox(10)
	var open: Button = UiKit.button("Open", _open_gift, "good")
	open.custom_minimum_size = Vector2(260.0, UiKit.TOUCH)
	open.disabled = GiftLogic.count() <= 0
	buttons.add_child(open)
	var odds: Button = UiKit.button("Drop odds", func() -> void:
		UiKit.message(self, "Hero Gift odds", ChestLogic.odds_text(GiftLogic.CHEST_ID) + "\n\n" + GiftLogic.odds_note()), "secondary")
	odds.add_theme_font_size_override("font_size", 28)
	buttons.add_child(odds)
	var card: PanelContainer = row("Hero Gifts  (you have %d)" % GiftLogic.count(),
		"Reach level %s in a night to earn a gift. Most hold coins or supplies; a few hold hero pieces." % ", ".join(levels),
		buttons, GIFT_ICON)
	if GiftLogic.count() > 0:
		card.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 22, UiKit.GOLD))


func _open_gift() -> void:
	var result: Dictionary = GiftLogic.open(_rng)
	if result.is_empty():
		return
	var unlocked: bool = bool(result["unlocked"])
	AudioManager.play("levelup" if unlocked else "chest")
	var text: String = "You received %s." % str(result["text"])
	if unlocked:
		text += "\n\n%s has joined the watch!" % GameData.hero(str(result["hero"])).display_name
	UiKit.message(self, "Hero unlocked!" if unlocked else "Gift opened!", text)


func _hero_card(hero: HeroData) -> void:
	var owned: bool = GameState.has_hero(hero.id)
	var selected: bool = str(GameState.p["selected_hero"]) == hero.id
	var card: PanelContainer = UiKit.panel(UiKit.PANEL, UiKit.AMBER if selected else Color.TRANSPARENT)
	content.add_child(card)
	var column: VBoxContainer = UiKit.vbox(14)
	card.add_child(column)
	var top: HBoxContainer = UiKit.hbox(24)
	column.add_child(top)
	var portrait: TextureRect = UiKit.icon(hero.texture_for(AgeLogic.current()), 200.0)
	portrait.modulate = Color(str(GameState.selected_skin(hero.id).get("tint", "#ffffff")))
	if not owned:
		portrait.modulate = Color(0.25, 0.25, 0.3)
	top.add_child(portrait)
	var text: VBoxContainer = UiKit.vbox(6)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(text)
	text.add_child(UiKit.label("%s, %s" % [hero.display_name, hero.title], UiKit.FONT, UiKit.GOLD, true))
	text.add_child(UiKit.label(hero.tier, UiKit.FONT_SMALL, UiKit.DAWN if hero.tier == "Elite" else UiKit.GOOD))
	text.add_child(UiKit.label(hero.description, UiKit.FONT_SMALL, UiKit.TEXT, true))
	if not hero.bonus_text().is_empty():
		text.add_child(UiKit.label(hero.bonus_text(), UiKit.FONT_SMALL, UiKit.GOLD, true))
	var stats: PlayerStats = PlayerStats.compute(hero, GameState.building_levels(), {})
	text.add_child(UiKit.label("HP %d · Speed %d · Starts with %s" % [roundi(stats.max_hp), roundi(stats.move_speed),
		WeaponLine.weapon_for(hero.starting_weapon, hero.id).display_name], UiKit.FONT_SMALL, UiKit.MUTED, true))

	if owned:
		var pick: Button = UiKit.button("Selected" if selected else "Select", func() -> void:
			GameState.p["selected_hero"] = hero.id
			GameState.save()
			GameState.changed.emit(), "good" if selected else "primary")
		pick.disabled = selected
		column.add_child(pick)
		_skin_picker(column, hero)
	else:
		if hero.pieces_needed > 0:
			var have: int = GiftLogic.pieces(hero.id)
			column.add_child(UiKit.label("Pieces %d / %d  ·  found in Hero Gifts" % [have, hero.pieces_needed], UiKit.FONT_SMALL, UiKit.GOLD))
			var progress: ProgressBar = UiKit.bar(UiKit.GOLD, 26.0)
			progress.max_value = hero.pieces_needed
			progress.value = have
			column.add_child(progress)
		elif hero.unlock_coins <= 0:
			column.add_child(UiKit.label("Available only by purchase.", UiKit.FONT_SMALL, UiKit.MUTED))
		if hero.unlock_coins > 0:
			var coins: Button = UiKit.button("Unlock for %s coins" % UiKit.number(hero.unlock_coins), func() -> void:
				if RunCommit.unlock_hero_with_coins(hero.id):
					AudioManager.play("purchase"))
			coins.disabled = GameState.amount("coins") < hero.unlock_coins
			column.add_child(coins)
		if not hero.product_id.is_empty():
			var price: String = BillingService.price(hero.product_id)
			var buy: Button = UiKit.button("Unlock now  %s" % price, func() -> void:
				BillingService.purchase(hero.product_id), "good")
			buy.disabled = price.is_empty() or not BillingService.is_available()
			column.add_child(buy)


func _skin_picker(column: VBoxContainer, hero: HeroData) -> void:
	var current: String = str(GameState.selected_skin(hero.id).get("id", ""))
	column.add_child(UiKit.label("Skins", UiKit.FONT_SMALL, UiKit.MUTED))
	var skins: HFlowContainer = HFlowContainer.new()
	column.add_child(skins)
	for skin: Dictionary in GameData.skins():
		if str(skin["hero"]) != hero.id:
			continue
		var id: String = str(skin["id"])
		var name_text: String = str(skin["name"])
		var button: Button
		if GameState.has_skin(id):
			button = UiKit.button(name_text + (" ✓" if id == current else ""), func() -> void:
				(GameState.p["selected_skins"] as Dictionary)[hero.id] = id
				GameState.save()
				GameState.changed.emit(), "good" if id == current else "secondary")
		elif skin.has("exclusive"):
			button = UiKit.button(name_text + " (Starter Pack)", func() -> void: SceneRouter.goto("shop"), "secondary")
		else:
			var cost: int = int(skin["gems"])
			button = UiKit.button("%s  %d gems" % [name_text, cost], func() -> void:
				if RunCommit.buy_skin(id):
					AudioManager.play("purchase"))
			button.disabled = GameState.amount("gems") < cost
		var swatch: ColorRect = ColorRect.new()
		swatch.color = Color(str(skin["tint"]))
		swatch.custom_minimum_size = Vector2(20.0, 20.0)
		swatch.position = Vector2(12.0, 12.0)
		swatch.size = Vector2(26.0, 26.0)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(swatch)
		skins.add_child(button)
