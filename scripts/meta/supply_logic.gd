class_name SupplyLogic
extends RefCounted
## Life potions bought in the shop (prices in balance.json -> "potion").


static func price_coins() -> int:
	return int(GameData.num("potion", "price_coins"))


static func pack_size() -> int:
	return int(GameData.num("potion", "pack_size"))


static func pack_gems() -> int:
	return int(GameData.num("potion", "pack_gems"))


static func buy_with_coins() -> bool:
	if not GameState.spend("coins", price_coins()):
		return false
	GameState.grant({"potions": 1})
	GameState.save()
	return true


static func buy_pack_with_gems() -> bool:
	if not GameState.spend("gems", pack_gems()):
		return false
	GameState.grant({"potions": pack_size()})
	GameState.save()
	return true
