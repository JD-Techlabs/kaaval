class_name Potions
extends Node2D
## Life potions. Defeated creatures sometimes drop one, more often when the
## hero is badly hurt and less often as the hero's level rises; bosses always
## do. Potions bought in the shop are carried in and drunk from the HUD. Walking over a potion
## heals a share of max HP. A potion is left alone while the hero is at full
## health, so it is never wasted. Every number is in balance.json -> "potion".

signal collected(amount: float)

const TEXTURE: String = "res://assets/sprites/potion.svg"
const BOB_HEIGHT: float = 6.0
const BOB_SPEED: float = 4.0

var run: RunManager
var _sprites: Array[Sprite2D] = []
var _gap: float = 0.0
var _clock: float = 0.0


## Chance that one defeated creature drops a potion, for the hero's HP share
## (0..1) and level this night. Higher levels find fewer potions.
static func drop_chance(hp_fraction: float, level: int = 1) -> float:
	var level_mult: float = maxf(1.0 - GameData.num("potion", "level_falloff") * float(level - 1), GameData.num("potion", "min_level_mult"))
	var chance: float = GameData.num("potion", "drop_chance") * level_mult
	if hp_fraction <= GameData.num("potion", "low_hp_threshold"):
		chance *= GameData.num("potion", "low_hp_mult")
	return chance


func count() -> int:
	return _sprites.size()


func positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for sprite: Sprite2D in _sprites:
		out.append(sprite.position)
	return out


## Roll for a drop from an ordinary creature.
func on_enemy_died(pos: Vector2) -> void:
	if _gap > 0.0 or count() >= int(GameData.num("potion", "max_on_ground")):
		return
	var player: Player = run.player
	if run.rng.randf() < drop_chance(player.hp / maxf(player.stats.max_hp, 1.0), run.state.level):
		drop(pos)


func drop(pos: Vector2) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load(TEXTURE) as Texture2D
	sprite.position = run.clamp_to_map(pos)
	add_child(sprite)
	_sprites.append(sprite)
	_gap = GameData.num("potion", "min_gap_seconds")


## Bought potions that can still be drunk this night.
func carried_left() -> int:
	var limit: int = int(GameData.num("potion", "max_uses_per_run"))
	return maxi(mini(GameState.amount("potions"), limit) - run.state.potions_used, 0)


## Drinks one bought potion. The profile is only charged when the run is committed.
func drink() -> bool:
	var player: Player = run.player
	if run.mode != RunManager.Mode.PLAYING or carried_left() <= 0 or not player.alive or player.hp >= player.stats.max_hp:
		return false
	run.state.potions_used += 1
	var amount: float = player.stats.max_hp * GameData.num("potion", "carry_heal_pct")
	player.heal(amount)
	collected.emit(amount)
	return true


func step(delta: float) -> void:
	_gap -= delta
	_clock += delta
	var player: Player = run.player
	var reach: float = GameData.num("potion", "pickup_radius")
	var hurt: bool = player.alive and player.hp < player.stats.max_hp
	for i: int in range(_sprites.size() - 1, -1, -1):
		var sprite: Sprite2D = _sprites[i]
		sprite.offset.y = sin(_clock * BOB_SPEED + float(i)) * BOB_HEIGHT
		if hurt and sprite.position.distance_to(player.position) <= reach:
			sprite.queue_free()
			_sprites.remove_at(i)
			var amount: float = player.stats.max_hp * GameData.num("potion", "heal_pct")
			player.heal(amount)
			collected.emit(amount)
			hurt = player.hp < player.stats.max_hp
