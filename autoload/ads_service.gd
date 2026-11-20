extends Node
## Rewarded ads (spec §9.5). Same API everywhere: AdMob + UMP consent on
## Android, a mock on desktop/editor. The Ad-Free Pass grants every reward
## instantly without showing an ad.

signal ready_changed

const PLUGIN_SINGLETON: String = "PoingGodotAdMob"
const RELEASE_CONFIG: String = "res://release_config/ads_release.json"

var backend: AdsBackend
var started: bool = false
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("android"):
		set_backend(AdsAndroid.new() if Engine.has_singleton(PLUGIN_SINGLETON) else AdsBackend.new())
	else:
		set_backend(AdsMock.new())


func set_backend(new_backend: AdsBackend) -> void:
	if backend != null:
		backend.queue_free()
	backend = new_backend
	add_child(backend)
	started = false


## Debug builds always use Google's official test unit. Release builds read
## the real unit from the git-ignored release config, falling back to the test unit.
static func rewarded_unit_id() -> String:
	var ads: Dictionary = GameData.json("app_config").get("ads", {})
	var unit: String = str(ads.get("rewarded_unit_id", ""))
	if not OS.is_debug_build() and FileAccess.file_exists(RELEASE_CONFIG):
		var parsed: Variant = GameData.parse_json(FileAccess.get_file_as_string(RELEASE_CONFIG))
		if parsed is Dictionary:
			unit = str((parsed as Dictionary).get("rewarded_unit_id", unit))
	return unit


## Consent (where required) then ad initialisation. Safe to call more than once.
func start(on_ready: Callable = Callable()) -> void:
	if started:
		if on_ready.is_valid():
			on_ready.call()
		return
	started = true
	backend.start(rewarded_unit_id(), func() -> void:
		ready_changed.emit()
		if on_ready.is_valid():
			on_ready.call())


func has_ad_free_pass() -> bool:
	return GameState.has_entitlement("ad_free_pass")


## True when a reward can be claimed right now (ad loaded, or pass owned).
func is_ready() -> bool:
	return has_ad_free_pass() or backend.is_ready()


## on_done(rewarded: bool). Grant the reward only when rewarded is true.
func show_rewarded(placement: String, on_done: Callable) -> void:
	if has_ad_free_pass():
		Analytics.log_event("ad_reward", {"placement": placement})
		on_done.call(true)
		return
	if _busy:
		return
	_busy = true
	Analytics.log_event("ad_show", {"placement": placement})
	backend.show(func(rewarded: bool) -> void:
		_busy = false
		if rewarded:
			Analytics.log_event("ad_reward", {"placement": placement})
		on_done.call(rewarded))


func privacy_options_required() -> bool:
	return backend.privacy_options_required()


func show_privacy_options() -> void:
	backend.show_privacy_options()
