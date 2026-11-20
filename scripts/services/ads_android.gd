class_name AdsAndroid
extends AdsBackend
## AdMob rewarded ads + UMP consent through the Poing Studios plugin
## (addons/admob, v5.x). Only instantiated on Android.

const RELOAD_SECONDS: float = 20.0

var _unit_id: String = ""
var _init_requested: bool = false
var _initialized: bool = false
var _loader: RewardedAdLoader
var _ad: RewardedAd
var _loading: bool = false
var _rewarded: bool = false


func start(unit_id: String, on_ready: Callable) -> void:
	_unit_id = unit_id
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	info.update(ConsentRequestParameters.new(),
		func() -> void: _on_consent_info(on_ready),
		func(_error: FormError) -> void: _initialize(on_ready))


func _on_consent_info(on_ready: Callable) -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	var must_ask: bool = info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
	if must_ask and info.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_error: FormError) -> void: _initialize(on_ready)),
			func(_error: FormError) -> void: _initialize(on_ready))
	else:
		_initialize(on_ready)


func _initialize(on_ready: Callable) -> void:
	if not _init_requested:
		_init_requested = true
		# Loading before the SDK reports ready throws on the Java side, so the
		# first ad request waits for the completion callback.
		var listener: OnInitializationCompleteListener = OnInitializationCompleteListener.new()
		listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
			_initialized = true
			_load()
		MobileAds.initialize(listener)
	on_ready.call()


func is_ready() -> bool:
	return _ad != null


func _load() -> void:
	if _loading or _ad != null or not _initialized:
		return
	_loading = true
	var callback: RewardedAdLoadCallback = RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading = false
		_ad = ad
	callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_loading = false
		_retry_later()
	_loader = RewardedAdLoader.new()
	_loader.load(_unit_id, AdRequest.new(), callback)


func _retry_later() -> void:
	await get_tree().create_timer(RELOAD_SECONDS).timeout
	_load()


func show(on_done: Callable) -> void:
	if _ad == null:
		_load()
		on_done.call(false)
		return
	_rewarded = false
	var screen: FullScreenContentCallback = FullScreenContentCallback.new()
	screen.on_ad_dismissed_full_screen_content = func() -> void: _finish(on_done)
	screen.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void: _finish(on_done)
	_ad.full_screen_content_callback = screen
	var listener: OnUserEarnedRewardListener = OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: _rewarded = true
	_ad.show(listener)


func _finish(on_done: Callable) -> void:
	if _ad != null:
		_ad.destroy()
		_ad = null
	_load()
	on_done.call(_rewarded)


func privacy_options_required() -> bool:
	var status: int = UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
	return status == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form()
