class_name BillingBackend
extends Node
## Store interface used by BillingService. This base class is also the
## "store unavailable" backend: every purchase fails cleanly.
## Purchase: {"product_id", "token", "state": "purchased"|"pending", "acknowledged": bool}

signal prices_loaded(prices: Dictionary)
signal purchases_updated(purchases: Array[Dictionary], is_restore: bool)
signal purchase_error(product_id: String, reason: String)


func start(_product_ids: PackedStringArray) -> void:
	pass


func is_available() -> bool:
	return false


func purchase(product_id: String) -> void:
	purchase_error.emit(product_id, "unavailable")


func query_purchases() -> void:
	var none: Array[Dictionary] = []
	purchases_updated.emit(none, true)


func consume(_token: String) -> void:
	pass


func acknowledge(_token: String) -> void:
	pass
