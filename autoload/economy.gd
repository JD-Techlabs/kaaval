extends Node
## Every cost and reward formula (spec §8). Pure functions: inputs in, numbers
## out. Constants come from data/balance.json "economy".


func _c(key: String) -> float:
	return GameData.num("economy", key)


## Coins for a finished run, before the optional ad double.
func run_coins(kills: int, seconds: float, victory: bool, coin_mult: float, remote_mult: float, bonus_coins: int) -> int:
	var base: float = float(kills) / _c("kills_per_coin") + (seconds / 60.0) * _c("coins_per_minute")
	if victory:
		base = base * _c("dawn_coin_mult") + _c("dawn_coin_bonus")
	return roundi((base + bonus_coins) * coin_mult * remote_mult)


func run_timber(boss_timber: int, victory: bool) -> int:
	return boss_timber + (int(_c("dawn_timber")) if victory else 0)


## Coin cost to reach `target_level` (1-based).
func building_coin_cost(target_level: int) -> int:
	return roundi(_c("build_cost_base") * pow(_c("build_cost_growth"), target_level - 1))


func building_timber_cost(target_level: int) -> int:
	var from_level: int = int(_c("timber_from_level"))
	if target_level < from_level:
		return 0
	return roundi(_c("timber_base") * pow(_c("timber_growth"), target_level - from_level))


## Build time in seconds to reach `target_level`.
func build_seconds(target_level: int, timer_mult: float) -> float:
	var from_level: int = int(_c("timer_from_level"))
	if target_level < from_level:
		return 0.0
	var minutes: float = _c("timer_base_minutes") * pow(_c("timer_growth"), target_level - from_level)
	minutes = minf(minutes, _c("timer_cap_minutes"))
	return minutes * 60.0 * timer_mult


func skip_gems(remaining_seconds: float) -> int:
	if remaining_seconds <= 0.0:
		return 0
	return ceili((remaining_seconds / 60.0) / _c("skip_minutes_per_gem"))


func revive_gems() -> int:
	return int(_c("revive_gems"))


func builder_slots(has_second_builder: bool) -> int:
	return int(_c("base_builder_slots")) + (1 if has_second_builder else 0)
