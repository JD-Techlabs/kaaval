class_name BillingMock
extends BillingBackend
## Desktop/editor store. Behaves like Play: owned non-consumables persist until
## "reinstall", consumables stay owned until consumed, purchases can be pending.

## "success", "pending", "cancel" or "fail" — what the next purchase() does.
var next_result: String = "success"
## Seconds before a purchase resolves; 0 = immediately (tests).
var delay: float = 0.5
## token -> {"product_id", "state", "acknowledged"}: what "Play" thinks we own.
var store: Dictionary = {}
var consumed_tokens: Array[String] = []
var acknowledged_tokens: Array[String] = []
var _next_token: int = 1


func start(product_ids: PackedStringArray) -> void:
	var prices: Dictionary = {}
	for id: String in product_ids:
		prices[id] = str(GameData.product(id).get("mock_price", "?"))
	prices_loaded.emit(prices)
	query_purchases()


func is_available() -> bool:
	return true


func purchase(product_id: String) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	match next_result:
		"cancel":
			purchase_error.emit(product_id, "cancelled")
			return
		"fail":
			purchase_error.emit(product_id, "network")
			return
	if _owns(product_id):
		purchase_error.emit(product_id, "already_owned")
		return
	var token: String = "mock-token-%d" % _next_token
	_next_token += 1
	var state: String = "pending" if next_result == "pending" else "purchased"
	store[token] = {"product_id": product_id, "state": state, "acknowledged": false}
	var list: Array[Dictionary] = [_as_purchase(token)]
	purchases_updated.emit(list, false)


## Simulates a slow payment method finally clearing.
func complete_pending(product_id: String) -> void:
	for token: String in store.keys():
		var entry: Dictionary = store[token]
		if str(entry["product_id"]) == product_id and str(entry["state"]) == "pending":
			entry["state"] = "purchased"
			var list: Array[Dictionary] = [_as_purchase(token)]
			purchases_updated.emit(list, false)


func query_purchases() -> void:
	var list: Array[Dictionary] = []
	for token: String in store.keys():
		list.append(_as_purchase(token))
	purchases_updated.emit(list, true)


func consume(token: String) -> void:
	if store.has(token):
		store.erase(token)
		consumed_tokens.append(token)


func acknowledge(token: String) -> void:
	if store.has(token):
		(store[token] as Dictionary)["acknowledged"] = true
		acknowledged_tokens.append(token)


func _owns(product_id: String) -> bool:
	for entry: Dictionary in store.values():
		if str(entry["product_id"]) == product_id:
			return true
	return false


func _as_purchase(token: String) -> Dictionary:
	var entry: Dictionary = store[token]
	return {"product_id": str(entry["product_id"]), "token": token, "state": str(entry["state"]),
		"acknowledged": bool(entry["acknowledged"])}
