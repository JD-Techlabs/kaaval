class_name ShopScreen
extends BaseScreen
## Shop (spec §9, §10): featured starter pack, gems, chests with visible odds,
## heroes, skins, passes, restore purchases. Every price shown on a purchase
## button comes from the store (Play-localised), never from a hard-coded string.

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _timer_labels: Array[Dictionary] = []


func _init() -> void:
	title_text = "Shop"


func _ready() -> void:
	_rng.randomize()
	super._ready()
	Analytics.log_event("shop_open")
	BillingService.prices_updated.connect(refresh)
	BillingService.purchase_succeeded.connect(_on_purchase_succeeded)
	BillingService.purchase_failed.connect(_on_purchase_failed)
	BillingService.purchase_pending.connect(func(_id: String) -> void:
		UiKit.message(self, "Payment pending", "Your purchase will arrive as soon as the payment clears."))
	BillingService.restore_finished.connect(_on_restore_finished)
	var ticker: Timer = Timer.new()
	ticker.wait_time = 1.0
	ticker.autostart = true
	ticker.timeout.connect(_tick)
	add_child(ticker)


static func failure_text(reason: String) -> String:
	match reason:
		"already_owned":
			return "You already own this. Try Restore purchases."
		"network":
			return "Could not reach the store. Check your connection and try again."
		"unavailable":
			return "The store is not available on this device right now."
	return "Something went wrong. You have not been charged."


func _on_purchase_succeeded(product_id: String) -> void:
	AudioManager.play("purchase")
	UiKit.message(self, "Thank you!", "%s added." % str(GameData.product(product_id).get("title", "Purchase")))
	refresh()


func _on_purchase_failed(_product_id: String, reason: String) -> void:
	if reason != "cancelled":
		UiKit.message(self, "Purchase failed", failure_text(reason))


var _restore_requested: bool = false


func _on_restore_finished(restored: int) -> void:
	if _restore_requested:
		_restore_requested = false
		UiKit.message(self, "Restore purchases", "%d purchase(s) restored." % restored if restored > 0 else "Nothing new to restore.")


func build() -> void:
	_timer_labels.clear()
	if BillingService.using_test_store:
		content.add_child(UiKit.label("Test store: these prices are examples and no real money is charged. Real prices come from Google Play.",
			UiKit.FONT_SMALL, UiKit.DAWN, true))
	_featured()
	section("Gems")
	_products("gems")
	section("Supplies")
	_potions()
	section("Chests")
	_free_chest()
	_guardian_chest()
	section("Heroes")
	_heroes()
	section("Skins")
	_skins()
	section("Passes")
	_products("pass")
	content.add_child(UiKit.button("Restore purchases", func() -> void:
		_restore_requested = true
		BillingService.restore(), "secondary"))


func _buy_button(product_id: String) -> Button:
	if BillingService.is_owned(product_id):
		var owned: Button = UiKit.button("Owned", Callable(), "secondary")
		owned.disabled = true
		return owned
	var price: String = BillingService.price(product_id)
	var buy: Button = UiKit.button(price if not price.is_empty() else "…", func() -> void:
		BillingService.purchase(product_id), "good")
	buy.custom_minimum_size = Vector2(250.0, UiKit.TOUCH)
	buy.disabled = price.is_empty() or not BillingService.is_available()
	return buy


func _products(section_id: String) -> void:
	var products: Array = GameData.json("products")["products"]
	for product: Dictionary in products:
		if str(product["section"]) == section_id:
			row(str(product["title"]), str(product["desc"]), _buy_button(str(product["id"])),
				UiKit.ICON_DIR + "gem.svg" if section_id == "gems" else "")


func _featured() -> void:
	if not RemoteConfig.flag("starter_pack_enabled") or BillingService.is_owned("starter_pack"):
		return
	section("Featured")
	var product: Dictionary = GameData.product("starter_pack")
	var card: PanelContainer = row(str(product["title"]), str(product["desc"]), _buy_button("starter_pack"))
	card.add_theme_stylebox_override("panel", UiKit.box(UiKit.PANEL, 22, UiKit.GOLD))
	var shown_at: float = float(GameState.p["starter_pack_shown_at"])
	var window: float = GameData.num("economy", "starter_pack_countdown_hours") * 3600.0
	if shown_at > 0.0 and GameState.now() < shown_at + window:
		var countdown: Label = UiKit.label("", UiKit.FONT_SMALL, UiKit.DAWN)
		content.add_child(countdown)
		_timer_labels.append({"label": countdown, "kind": "starter", "until": shown_at + window})
	_tick()


func _heroes() -> void:
	for hero: HeroData in GameData.heroes():
		if hero.product_id.is_empty():
			continue
		var right: Control = _buy_button(hero.product_id)
		if GameState.has_hero(hero.id):
			right = UiKit.button("Owned", Callable(), "secondary")
			(right as Button).disabled = true
		row("%s, %s" % [hero.display_name, hero.title], hero.description, right, hero.texture)


func _skins() -> void:
	for skin: Dictionary in GameData.skins():
		if bool(skin.get("default", false)):
			continue
		var id: String = str(skin["id"])
		var hero: HeroData = GameData.hero(str(skin["hero"]))
		var right: Button
		if GameState.has_skin(id):
			right = UiKit.button("Owned", Callable(), "secondary")
			right.disabled = true
		elif skin.has("exclusive"):
			right = UiKit.button("Starter Pack", Callable(), "secondary")
			right.disabled = true
		else:
			var cost: int = int(skin["gems"])
			right = UiKit.button("%d gems" % cost, func() -> void:
				if RunCommit.buy_skin(id):
					AudioManager.play("purchase"))
			right.disabled = GameState.amount("gems") < cost or not GameState.has_hero(hero.id)
		var card: PanelContainer = row(str(skin["name"]), "Skin for %s" % hero.display_name, right, hero.texture)
		var portrait: TextureRect = card.get_child(0).get_child(0) as TextureRect
		portrait.modulate = Color(str(skin["tint"]))


## Life potions: bought with coins or gems, drunk from the HUD during a night.
func _potions() -> void:
	var buttons: VBoxContainer = UiKit.vbox(10)
	var one: Button = UiKit.button("%s coins" % UiKit.number(SupplyLogic.price_coins()), func() -> void:
		if SupplyLogic.buy_with_coins():
			AudioManager.play("purchase"))
	one.custom_minimum_size = Vector2(300.0, UiKit.TOUCH)
	one.disabled = GameState.amount("coins") < SupplyLogic.price_coins()
	buttons.add_child(one)
	var pack: Button = UiKit.button("%d for %d gems" % [SupplyLogic.pack_size(), SupplyLogic.pack_gems()], func() -> void:
		if SupplyLogic.buy_pack_with_gems():
			AudioManager.play("purchase"), "secondary")
	pack.disabled = GameState.amount("gems") < SupplyLogic.pack_gems()
	buttons.add_child(pack)
	row("Life Potion  (you have %d)" % GameState.amount("potions"),
		"Tap the potion button during a night to heal %d%% HP. Up to %d per night." % [
		roundi(GameData.num("potion", "carry_heal_pct") * 100.0), int(GameData.num("potion", "max_uses_per_run"))],
		buttons, Potions.TEXTURE)


# --- chests ---------------------------------------------------------------

func _free_chest() -> void:
	var buttons: VBoxContainer = UiKit.vbox(10)
	var open: Button = UiKit.button("Open", func() -> void: _show_drop(ChestLogic.open_free(_rng)), "good")
	open.custom_minimum_size = Vector2(300.0, UiKit.TOUCH)
	buttons.add_child(open)
	var left: int = ChestLogic.ad_opens_left()
	var extra_text: String = "Extra (%d left)" if AdsService.has_ad_free_pass() else "Extra: watch ad (%d)"
	var extra: Button = UiKit.button(extra_text % left, func() -> void:
		AdsService.show_rewarded("free_chest", func(rewarded: bool) -> void:
			if rewarded:
				_show_drop(ChestLogic.open_free_from_ad(_rng))), "secondary")
	extra.disabled = left <= 0 or not AdsService.is_ready()
	extra.add_theme_font_size_override("font_size", 28)
	buttons.add_child(extra)
	buttons.add_child(_odds_button("free_chest"))
	row("Free Chest", "Coins, timber and a chance of gems. Every %d hours." % int(RemoteConfig.num("free_chest_hours")),
		buttons, "res://assets/sprites/chest.svg")
	_timer_labels.append({"button": open, "kind": "free"})
	_tick()


func _guardian_chest() -> void:
	var price: int = ChestLogic.guardian_price()
	var buttons: VBoxContainer = UiKit.vbox(10)
	var buy: Button = UiKit.button("%d gems" % price, func() -> void: _show_drop(ChestLogic.buy_guardian(_rng)))
	buy.custom_minimum_size = Vector2(300.0, UiKit.TOUCH)
	buy.disabled = GameState.amount("gems") < price
	buttons.add_child(buy)
	buttons.add_child(_odds_button("guardian_chest"))
	row("Guardian Chest", "A big haul of coins and timber.", buttons, "res://assets/sprites/chest.svg")


## Drop odds, rendered from the same data the roll uses (spec §9.4).
func _odds_button(chest_id: String) -> Button:
	var button: Button = UiKit.button("Drop odds", func() -> void:
		UiKit.message(self, "%s odds" % str(ChestLogic.config(chest_id)["name"]), ChestLogic.odds_text(chest_id)), "secondary")
	button.add_theme_font_size_override("font_size", 28)
	return button


func _show_drop(drop: Dictionary) -> void:
	if drop.is_empty():
		return
	AudioManager.play("chest")
	UiKit.message(self, "Chest opened!", "You received %s." % str(drop["label"]))


func _tick() -> void:
	for entry: Dictionary in _timer_labels:
		match str(entry["kind"]):
			"free":
				var open: Button = entry["button"] as Button
				if not is_instance_valid(open):
					continue
				var remaining: float = ChestLogic.free_remaining()
				open.disabled = remaining > 0.0
				open.text = "Open" if remaining <= 0.0 else UiKit.duration(remaining)
			"starter":
				var countdown: Label = entry["label"] as Label
				if is_instance_valid(countdown):
					var left: float = float(entry["until"]) - GameState.now()
					countdown.text = "Featured for %s more" % UiKit.duration(left) if left > 0.0 else ""
