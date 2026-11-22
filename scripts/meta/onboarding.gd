class_name Onboarding
extends RefCounted
## The first minutes: a first-night bonus, systems that appear once the first
## night is played, and which single popup the home screen shows on a visit.
## Numbers in data/balance.json "onboarding".


static func _num(key: String) -> float:
	return GameData.num("onboarding", key)


static func runs_played() -> int:
	return int(GameState.p.get("runs_played", 0))


## Age bar, Collect and land for sale stay hidden until the first night is played.
static func village_unlocked() -> bool:
	return runs_played() >= int(_num("unlock_after_runs"))


## Extra reward for the very first night, so the first trip home always buys a
## building. Empty after that. Read before the night is committed.
static func first_night_bonus() -> Dictionary:
	if runs_played() > 0:
		return {}
	return {"coins": int(_num("first_night_bonus_coins")), "food": int(_num("first_night_bonus_food"))}


## The home screen's "how to build" tip, for new villages only.
static func show_tip() -> bool:
	return VillageLogic.total_level() < int(_num("tip_until_village_level"))


static func village_intro_due() -> bool:
	return village_unlocked() and not bool(GameState.p.get("village_intro_seen", false))


static func mark_village_intro_seen() -> void:
	GameState.p["village_intro_seen"] = true
	GameState.save()


## The daily popup shows once per calendar day while today's login reward is unclaimed.
static func daily_popup_due() -> bool:
	return village_unlocked() and DailyLogic.login_available() \
		and str(GameState.p.get("daily_popup_date", "")) != GameState.today()


static func mark_daily_popup_shown() -> void:
	GameState.p["daily_popup_date"] = GameState.today()
	GameState.save()


## Spec §9.2: offered once after the first night; never with fake urgency.
static func starter_pack_due() -> bool:
	return runs_played() >= 1 and float(GameState.p["starter_pack_shown_at"]) <= 0.0 \
		and not BillingService.is_owned("starter_pack") and RemoteConfig.flag("starter_pack_enabled")


## At most one popup per visit to the village, most helpful first:
## "village_intro", "daily", "starter_pack" or "".
static func next_home_popup() -> String:
	if village_intro_due():
		return "village_intro"
	if daily_popup_due():
		return "daily"
	if starter_pack_due():
		return "starter_pack"
	return ""
