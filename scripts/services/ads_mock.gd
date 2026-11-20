class_name AdsMock
extends AdsBackend
## Desktop/editor ads: "plays" for a moment, then rewards.

## Whether the next ad is watched to the end.
var next_rewarded: bool = true
## Seconds an ad "plays"; 0 = immediately (tests).
var delay: float = 0.8
var shows: int = 0


func is_ready() -> bool:
	return true


func show(on_done: Callable) -> void:
	shows += 1
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	on_done.call(next_rewarded)
