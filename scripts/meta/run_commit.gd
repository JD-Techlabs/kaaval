class_name RunCommit
extends RefCounted
## The single place where a finished run changes the profile (spec §12.2).


## Coins the run earned before any ad doubling.
static func coins_for(summary: Dictionary) -> int:
	return Economy.run_coins(int(summary["kills"]), float(summary["time"]), bool(summary["victory"]),
		float(summary.get("coin_mult", 1.0)), RemoteConfig.num("coin_multiplier"), int(summary["bonus_coins"]))


static func timber_for(summary: Dictionary) -> int:
	return Economy.run_timber(int(summary["boss_timber"]), bool(summary["victory"]))


static func commit(summary: Dictionary, coins: int) -> void:
	GameState.grant({"coins": coins, "timber": timber_for(summary), "gifts": int(summary.get("gifts", 0))})
	GameState.spend("potions", mini(int(summary.get("potions_used", 0)), GameState.amount("potions")))
	DailyLogic.record_run(summary)
	GameState.p["runs_played"] = int(GameState.p["runs_played"]) + 1
	GameState.p["hints_done"] = true
	GameState.save()


## Hero unlock with coins (spec §5.1).
static func unlock_hero_with_coins(hero_id: String) -> bool:
	var hero: HeroData = GameData.hero(hero_id)
	if hero == null or hero.unlock_coins <= 0 or GameState.has_hero(hero_id) or not GameState.spend("coins", hero.unlock_coins):
		return false
	GameState.unlock_hero(hero_id)
	GameState.save()
	return true


static func buy_skin(skin_id: String) -> bool:
	var skin: Dictionary = GameData.skin(skin_id)
	if skin.is_empty() or GameState.has_skin(skin_id) or skin.has("exclusive"):
		return false
	if not GameState.spend("gems", int(skin.get("gems", 0))):
		return false
	GameState.add_skin(skin_id)
	GameState.save()
	return true
