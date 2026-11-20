class_name BillingAndroid
extends BillingBackend
## Google Play Billing through the official GodotGooglePlayBilling plugin
## (addons/GodotGooglePlayBilling, v3.x). Only instantiated on Android.

const RETRY_SECONDS: float = 6.0
const MAX_RETRIES: int = 5

var _client: BillingClient
var _product_ids: PackedStringArray = PackedStringArray()
var _retries: int = 0
var _pending_product: String = ""


func start(product_ids: PackedStringArray) -> void:
	_product_ids = product_ids
	_client = BillingClient.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.disconnected.connect(_reconnect)
	_client.connect_error.connect(func(_code: int, _message: String) -> void: _reconnect())
	_client.query_product_details_response.connect(_on_product_details)
	_client.query_purchases_response.connect(_on_purchases.bind(true))
	_client.on_purchase_updated.connect(_on_purchases.bind(false))
	_client.start_connection()


func is_available() -> bool:
	return _client != null and _client.is_ready()


func purchase(product_id: String) -> void:
	if not is_available():
		purchase_error.emit(product_id, "unavailable")
		return
	_pending_product = product_id
	var result: Dictionary = _client.purchase(product_id)
	var code: int = int(result.get("response_code", BillingClient.BillingResponseCode.OK))
	if code != BillingClient.BillingResponseCode.OK:
		_pending_product = ""
		purchase_error.emit(product_id, _reason(code))


func query_purchases() -> void:
	if is_available():
		_client.query_purchases(BillingClient.ProductType.INAPP)
	else:
		var none: Array[Dictionary] = []
		purchases_updated.emit(none, true)


func consume(token: String) -> void:
	if is_available():
		_client.consume_purchase(token)


func acknowledge(token: String) -> void:
	if is_available():
		_client.acknowledge_purchase(token)


func _on_connected() -> void:
	_retries = 0
	_client.query_product_details(_product_ids, BillingClient.ProductType.INAPP)
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _reconnect() -> void:
	if _retries >= MAX_RETRIES:
		return
	_retries += 1
	await get_tree().create_timer(RETRY_SECONDS).timeout
	if not is_available():
		_client.start_connection()


func _on_product_details(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	var prices: Dictionary = {}
	var details: Array = response.get("product_details", [])
	for detail: Dictionary in details:
		var price: String = _find_price(detail)
		if not price.is_empty():
			prices[str(detail.get("product_id", ""))] = price
	prices_loaded.emit(prices)


## The localised price string lives in a nested offer dictionary whose exact
## shape differs between Billing Library versions, so search for it.
static func _find_price(value: Variant) -> String:
	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has("formatted_price"):
			return str(dict["formatted_price"])
		for child: Variant in dict.values():
			var found: String = _find_price(child)
			if not found.is_empty():
				return found
	elif value is Array:
		var list: Array = value
		for child: Variant in list:
			var found: String = _find_price(child)
			if not found.is_empty():
				return found
	return ""


func _on_purchases(response: Dictionary, is_restore: bool) -> void:
	var code: int = int(response.get("response_code", -1))
	if code != BillingClient.BillingResponseCode.OK:
		if not is_restore:
			purchase_error.emit(_pending_product, _reason(code))
			_pending_product = ""
		return
	_pending_product = ""
	var list: Array[Dictionary] = []
	var purchases: Array = response.get("purchases", [])
	for purchase_info: Dictionary in purchases:
		var state: int = int(purchase_info.get("purchase_state", 0))
		if state == BillingClient.PurchaseState.UNSPECIFIED_STATE:
			continue
		var ids: PackedStringArray = PackedStringArray(purchase_info.get("product_ids", []))
		for id: String in ids:
			list.append({
				"product_id": id,
				"token": str(purchase_info.get("purchase_token", "")),
				"state": "pending" if state == BillingClient.PurchaseState.PENDING else "purchased",
				"acknowledged": bool(purchase_info.get("is_acknowledged", false)),
			})
	purchases_updated.emit(list, is_restore)


static func _reason(code: int) -> String:
	match code:
		BillingClient.BillingResponseCode.USER_CANCELED:
			return "cancelled"
		BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED:
			return "already_owned"
		BillingClient.BillingResponseCode.NETWORK_ERROR, BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE, \
		BillingClient.BillingResponseCode.SERVICE_DISCONNECTED:
			return "network"
		BillingClient.BillingResponseCode.BILLING_UNAVAILABLE, BillingClient.BillingResponseCode.ITEM_UNAVAILABLE:
			return "unavailable"
	return "error"
