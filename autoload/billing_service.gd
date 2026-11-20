extends Node
## In-app purchases (spec §9.2, §9.6). Same API everywhere: the real Play
## Billing backend on Android, a mock store on desktop/editor.
## Flow: purchase -> grant -> consume (consumables) / acknowledge (one-time).

signal prices_updated
signal purchase_succeeded(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal purchase_pending(product_id: String)
signal restore_finished(restored: int)

const PLUGIN_SINGLETON: String = "GodotGooglePlayBilling"
## Debug Android builds wait this long for Play to send prices before using the test store.
const TEST_STORE_WAIT_SECONDS: float = 8.0

var backend: BillingBackend
var _prices: Dictionary = {}
## True when prices and purchases come from the built-in test store, not Google Play.
var using_test_store: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("android"):
		if Engine.has_singleton(PLUGIN_SINGLETON):
			set_backend(BillingAndroid.new())
			_maybe_fall_back_to_test_store()
		else:
			push_warning("BillingService: Play Billing plugin missing, store disabled")
			set_backend(BillingBackend.new())
	else:
		using_test_store = true
		set_backend(BillingMock.new())


## The test store may stand in for Play only in a debug build that got no prices from Play
## (app not in Play Console yet, emulator without Play). Release builds never use it.
static func should_use_test_store(is_debug_build: bool, has_play_prices: bool) -> bool:
	return is_debug_build and not has_play_prices


func _maybe_fall_back_to_test_store() -> void:
	if not OS.is_debug_build():
		return
	await get_tree().create_timer(TEST_STORE_WAIT_SECONDS).timeout
	if should_use_test_store(OS.is_debug_build(), not _prices.is_empty()):
		push_warning("BillingService: Play sent no prices; debug build is using the test store")
		using_test_store = true
		set_backend(BillingMock.new())


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and backend != null:
		backend.query_purchases()


## Swaps the store backend (tests inject a BillingMock with delay 0).
func set_backend(new_backend: BillingBackend) -> void:
	if backend != null:
		backend.queue_free()
	backend = new_backend
	_prices.clear()
	add_child(backend)
	backend.prices_loaded.connect(_on_prices_loaded)
	backend.purchases_updated.connect(_on_purchases_updated)
	backend.purchase_error.connect(_on_purchase_error)
	backend.start(product_ids())


func product_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	var products: Array = GameData.json("products").get("products", [])
	for product: Dictionary in products:
		ids.append(str(product["id"]))
	return ids


func is_available() -> bool:
	return backend.is_available()


## Play-localised price, or "" while it is not known yet.
func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


func is_owned(product_id: String) -> bool:
	return GameState.has_entitlement(product_id)


func purchase(product_id: String) -> void:
	Analytics.log_event("iap_start", {"sku": product_id})
	if _is_one_time(product_id) and is_owned(product_id):
		_on_purchase_error(product_id, "already_owned")
		return
	backend.purchase(product_id)


## Re-reads what Play says we own (also runs on launch and on resume).
func restore() -> void:
	backend.query_purchases()


func _is_one_time(product_id: String) -> bool:
	return str(GameData.product(product_id).get("type", "")) == "non_consumable"


func _on_prices_loaded(prices: Dictionary) -> void:
	_prices.merge(prices, true)
	prices_updated.emit()


func _on_purchase_error(product_id: String, reason: String) -> void:
	Analytics.log_event("iap_fail", {"sku": product_id, "reason": reason})
	purchase_failed.emit(product_id, reason)


func _on_purchases_updated(purchases: Array[Dictionary], is_restore: bool) -> void:
	var restored: int = 0
	for item: Dictionary in purchases:
		var product_id: String = str(item["product_id"])
		var token: String = str(item["token"])
		var product: Dictionary = GameData.product(product_id)
		if product.is_empty():
			continue
		if str(item["state"]) == "pending":
			purchase_pending.emit(product_id)
			continue
		if _is_one_time(product_id):
			if not is_owned(product_id):
				_grant(product)
				restored += 1
				_announce(product_id)
			if not bool(item["acknowledged"]):
				backend.acknowledge(token)
		else:
			var tokens: Array = GameState.p["processed_tokens"]
			if not tokens.has(token):
				_grant(product)
				tokens.append(token)
				while tokens.size() > int(GameData.num("economy", "max_processed_tokens")):
					tokens.pop_front()
				GameState.save()
				_announce(product_id)
			backend.consume(token)
	if is_restore:
		restore_finished.emit(restored)


func _announce(product_id: String) -> void:
	Analytics.log_event("iap_success", {"sku": product_id})
	purchase_succeeded.emit(product_id)


## Applies a product's contents to the profile and saves immediately.
func _grant(product: Dictionary) -> void:
	var grants: Dictionary = product.get("grants", {})
	GameState.grant(grants)
	if grants.has("skin"):
		GameState.add_skin(str(grants["skin"]))
	if grants.has("hero"):
		GameState.unlock_hero(str(grants["hero"]))
	if grants.has("entitlement"):
		GameState.add_entitlement(str(grants["entitlement"]))
	if str(product.get("type", "")) == "non_consumable":
		GameState.add_entitlement(str(product["id"]))
	GameState.save()
