extends "res://tests/base_test.gd"
## Spec §9.6 against the mock store: grant-then-consume, acknowledge, restore,
## pending, cancelled, failed, already owned.

var store: BillingMock


func before_each() -> void:
	super.before_each()
	store = BillingMock.new()
	store.delay = 0.0
	BillingService.set_backend(store)
	watch_signals(BillingService)


func after_each() -> void:
	BillingService.set_backend(BillingMock.new())
	super.after_each()


func test_test_store_only_stands_in_for_play_in_debug_builds_without_prices() -> void:
	assert_true(BillingService.should_use_test_store(true, false))
	assert_false(BillingService.should_use_test_store(true, true), "Play prices win")
	assert_false(BillingService.should_use_test_store(false, false), "never in a release build")
	assert_false(BillingService.should_use_test_store(false, true))


func test_prices_come_from_the_store() -> void:
	assert_eq(BillingService.price("gems_80"), "₹89.00")
	for id: String in BillingService.product_ids():
		assert_ne(BillingService.price(id), "", id)
	assert_eq(BillingService.product_ids().size(), 12)


func test_consumable_is_granted_then_consumed() -> void:
	BillingService.purchase("gems_500")
	assert_eq(GameState.amount("gems"), 500)
	assert_eq(store.consumed_tokens.size(), 1)
	assert_true(store.store.is_empty(), "nothing left owned after consume")
	assert_signal_emitted_with_parameters(BillingService, "purchase_succeeded", ["gems_500"])


func test_consumable_can_be_bought_again() -> void:
	BillingService.purchase("gems_80")
	BillingService.purchase("gems_80")
	assert_eq(GameState.amount("gems"), 160)
	assert_eq(store.consumed_tokens.size(), 2)


func test_consumable_is_never_granted_twice_for_one_token() -> void:
	BillingService.purchase("gems_80")
	var token: String = store.consumed_tokens[0]
	# Play re-delivers the same purchase (e.g. consume failed last session).
	store.store[token] = {"product_id": "gems_80", "state": "purchased", "acknowledged": false}
	BillingService.restore()
	assert_eq(GameState.amount("gems"), 80)
	assert_eq(store.consumed_tokens.size(), 2, "still consumed again so it clears")


func test_non_consumable_is_granted_and_acknowledged() -> void:
	BillingService.purchase("ad_free_pass")
	assert_true(GameState.has_entitlement("ad_free_pass"))
	assert_true(BillingService.is_owned("ad_free_pass"))
	assert_eq(store.acknowledged_tokens.size(), 1)
	assert_eq(store.consumed_tokens.size(), 0, "one-time products are never consumed")


func test_starter_pack_contents() -> void:
	BillingService.purchase("starter_pack")
	assert_eq(GameState.amount("gems"), 300)
	assert_eq(GameState.amount("coins"), 2000)
	assert_eq(GameState.amount("timber"), 20)
	assert_true(GameState.has_skin("skin_muthu_dawnbringer"))
	assert_true(BillingService.is_owned("starter_pack"))


func test_hero_and_builder_products() -> void:
	BillingService.purchase("hero_ammu")
	BillingService.purchase("builder_2")
	assert_true(GameState.has_hero("hero_ammu"))
	assert_eq(VillageLogic.builder_slots(), 2)


func test_owned_one_time_product_cannot_be_bought_twice() -> void:
	BillingService.purchase("starter_pack")
	BillingService.purchase("starter_pack")
	assert_eq(GameState.amount("gems"), 300)
	assert_signal_emitted_with_parameters(BillingService, "purchase_failed", ["starter_pack", "already_owned"])


func test_restore_after_reinstall_returns_one_time_purchases() -> void:
	BillingService.purchase("ad_free_pass")
	BillingService.purchase("hero_ammu")
	BillingService.purchase("gems_80")
	GameState.reset_profile()  # "reinstall": local profile gone, Play still knows
	assert_false(GameState.has_entitlement("ad_free_pass"))
	BillingService.restore()
	assert_true(GameState.has_entitlement("ad_free_pass"))
	assert_true(GameState.has_hero("hero_ammu"))
	assert_eq(GameState.amount("gems"), 0, "consumed gems are not restored")
	assert_signal_emitted_with_parameters(BillingService, "restore_finished", [2])


func test_restore_acknowledges_unacknowledged_purchases() -> void:
	store.store["tok-x"] = {"product_id": "builder_2", "state": "purchased", "acknowledged": false}
	BillingService.restore()
	assert_true(GameState.has_entitlement("builder_2"))
	assert_true(store.acknowledged_tokens.has("tok-x"))


func test_pending_purchase_grants_nothing_until_it_completes() -> void:
	store.next_result = "pending"
	BillingService.purchase("gems_1200")
	assert_eq(GameState.amount("gems"), 0)
	assert_signal_emitted_with_parameters(BillingService, "purchase_pending", ["gems_1200"])
	assert_eq(store.consumed_tokens.size(), 0)
	store.complete_pending("gems_1200")
	assert_eq(GameState.amount("gems"), 1200)
	assert_eq(store.consumed_tokens.size(), 1)


func test_cancelled_and_failed_purchases_grant_nothing() -> void:
	store.next_result = "cancel"
	BillingService.purchase("gems_2800")
	assert_signal_emitted_with_parameters(BillingService, "purchase_failed", ["gems_2800", "cancelled"])
	store.next_result = "fail"
	BillingService.purchase("gems_2800")
	assert_signal_emitted_with_parameters(BillingService, "purchase_failed", ["gems_2800", "network"])
	assert_eq(GameState.amount("gems"), 0)


func test_purchase_is_saved_immediately() -> void:
	BillingService.purchase("gems_80")
	GameState.reset_profile()
	GameState.load_profile()
	assert_eq(GameState.amount("gems"), 80)


func test_unavailable_store_fails_cleanly() -> void:
	BillingService.set_backend(BillingBackend.new())
	watch_signals(BillingService)
	assert_false(BillingService.is_available())
	BillingService.purchase("gems_80")
	assert_eq(GameState.amount("gems"), 0)
	assert_signal_emitted_with_parameters(BillingService, "purchase_failed", ["gems_80", "unavailable"])


func test_ad_free_pass_skips_ads() -> void:
	var ads: AdsMock = AdsMock.new()
	ads.delay = 0.0
	AdsService.set_backend(ads)
	var results: Array[bool] = []
	AdsService.show_rewarded("revive", func(rewarded: bool) -> void: results.append(rewarded))
	assert_eq(ads.shows, 1, "without the pass the ad is shown")
	BillingService.purchase("ad_free_pass")
	AdsService.show_rewarded("revive", func(rewarded: bool) -> void: results.append(rewarded))
	assert_eq(ads.shows, 1, "with the pass no ad is shown")
	assert_eq(results, [true, true] as Array[bool])
	ads.next_rewarded = false
	GameState.reset_profile()
	AdsService.show_rewarded("revive", func(rewarded: bool) -> void: results.append(rewarded))
	assert_eq(results[2], false, "closing an ad early gives no reward")
	AdsService.set_backend(AdsMock.new())


func test_debug_builds_use_googles_test_ad_unit() -> void:
	assert_eq(AdsService.rewarded_unit_id(), "ca-app-pub-3940256099942544/5224354917")
