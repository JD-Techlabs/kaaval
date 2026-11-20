class_name AdsBackend
extends Node
## Ad network interface used by AdsService. This base class is also the
## "ads unavailable" backend: nothing loads and every show() reports no reward.


## Runs the consent flow where required, then initialises ads. Calls on_ready once.
func start(_unit_id: String, on_ready: Callable) -> void:
	on_ready.call()


func is_ready() -> bool:
	return false


## on_done(rewarded: bool)
func show(on_done: Callable) -> void:
	on_done.call(false)


func privacy_options_required() -> bool:
	return false


func show_privacy_options() -> void:
	pass
