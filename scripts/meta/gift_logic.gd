class_name GiftLogic
extends RefCounted
## Hero Gifts: earned by reaching set levels in a night, opened on the Heroes
## screen. A gift rolls on the "hero_gift" table in chests.json (the same data
## the odds panel shows). Hero pieces are a rare drop; collecting a hero's full
## set unlocks that hero.

const CHEST_ID: String = "hero_gift"


static func run_levels() -> Array[int]:
	var out: Array[int] = []
	var levels: Array = GameData.balance("gifts").get("run_levels", [])
	for level: Variant in levels:
		out.append(int(level))
	return out


## Gifts a night earns for the level it reached.
static func earned_for_level(level: int) -> int:
	var earned: int = 0
	for threshold: int in run_levels():
		if level >= threshold:
			earned += 1
	return earned


static func count() -> int:
	return GameState.amount("gifts")


static func pieces(hero_id: String) -> int:
	var owned: Dictionary = GameState.p["hero_pieces"]
	return int(owned.get(hero_id, 0))


## Heroes that can still gain pieces: collectable and not yet unlocked.
static func locked_piece_heroes() -> Array[HeroData]:
	var out: Array[HeroData] = []
	for hero: HeroData in GameData.heroes():
		if hero.pieces_needed > 0 and not GameState.has_hero(hero.id):
			out.append(hero)
	return out


static func fallback_coins() -> int:
	return int(ChestLogic.config(CHEST_ID).get("piece_fallback_coins", 0))


## Adds pieces to a hero. Returns true when this completed the set and unlocked the hero.
static func add_pieces(hero_id: String, amount: int) -> bool:
	var hero: HeroData = GameData.hero(hero_id)
	if hero == null or hero.pieces_needed <= 0 or GameState.has_hero(hero_id):
		return false
	var owned: Dictionary = GameState.p["hero_pieces"]
	owned[hero_id] = mini(pieces(hero_id) + amount, hero.pieces_needed)
	GameState.changed.emit()
	if int(owned[hero_id]) < hero.pieces_needed:
		return false
	GameState.unlock_hero(hero_id)
	return true


## Opens one gift. Returns {} when there is none, otherwise
## {"text": String, "hero": String, "unlocked": bool}.
static func open(rng: RandomNumberGenerator) -> Dictionary:
	if not GameState.spend("gifts", 1):
		return {}
	var drop: Dictionary = ChestLogic.roll(CHEST_ID, rng)
	var rewards: Dictionary = drop["rewards"]
	var result: Dictionary = {"text": str(drop["label"]), "hero": "", "unlocked": false}
	if rewards.has("hero_pieces"):
		var amount: int = int(rewards["hero_pieces"])
		var locked: Array[HeroData] = locked_piece_heroes()
		if locked.is_empty():
			var coins: int = fallback_coins() * amount
			GameState.grant({"coins": coins})
			result["text"] = "%d coins (every collectable hero is already yours)" % coins
		else:
			var hero: HeroData = locked[rng.randi() % locked.size()]
			result["hero"] = hero.id
			result["unlocked"] = add_pieces(hero.id, amount)
			result["text"] = "%s for %s (%d/%d)" % [str(drop["label"]), hero.display_name, pieces(hero.id), hero.pieces_needed]
	else:
		GameState.grant(rewards)
	GameState.save()
	return result


## Shown under the odds: how the hero for a piece is chosen.
static func odds_note() -> String:
	return "A hero piece goes to a random hero you have not unlocked yet, each equally likely. If none are left you get %d coins per piece instead." % fallback_coins()
