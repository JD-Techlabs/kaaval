class_name BaseWeapon
extends Node2D
## Shared weapon plumbing: data-driven stats, cooldown loop, hero multipliers.
## Subclasses override fire() (cooldown weapons) or step() (constant weapons).

var data: WeaponData
var level: int = 1
var evolution: EvolutionData
var run: RunManager
var _cooldown_left: float = 0.3


func setup(p_run: RunManager, p_data: WeaponData) -> void:
	run = p_run
	data = p_data
	refresh()


func set_level(p_level: int) -> void:
	level = p_level
	refresh()


func evolve(p_evolution: EvolutionData) -> void:
	evolution = p_evolution
	refresh()


## Raw stat at the current level; evolution params override.
func stat(key: String) -> float:
	if evolution != null and evolution.params.has(key):
		return float(evolution.params[key])
	return data.stat(key, level)


func damage() -> float:
	return stat("damage") * run.player.stats.damage_mult


## Any size-like stat, scaled by the hero's area multiplier.
func area(key: String) -> float:
	return stat(key) * run.player.stats.area_mult


func cooldown() -> float:
	return stat("cooldown") * run.player.stats.cooldown_mult


func step(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left <= 0.0 and fire():
		_cooldown_left = cooldown()


## Return true when the weapon actually fired (starts the cooldown).
func fire() -> bool:
	return false


## Called when level or evolution changes.
func refresh() -> void:
	pass


## Per-creature hit interval for constant-damage weapons.
func can_hit(enemy: Enemy, interval: float) -> bool:
	var now: float = run.state.time
	if now - float(enemy.hit_times.get(data.id, -99.0)) < interval:
		return false
	enemy.hit_times[data.id] = now
	return true


static func tex(sprite_name: String) -> Texture2D:
	return load("res://assets/sprites/%s.svg" % sprite_name) as Texture2D
