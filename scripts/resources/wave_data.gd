class_name WaveData
extends Resource
## One night (a stage): its map look, wave table, bosses and difficulty.
## Nights are played in `sort_order`; reaching dawn unlocks the next one.

@export var id: String = ""
@export var display_name: String = ""
## Position in the night list, 1 = first night.
@export var sort_order: int = 0
## One line shown on the night picker.
@export var tagline: String = ""
@export var map_size: Vector2 = Vector2(4000, 4000)
## Seconds until dawn.
@export var duration: float = 900.0
## {"start", "end", "rate", "mix": {enemy_id: weight}, "crow_interval"}
@export var segments: Array[Dictionary] = []
## {"time", "type": "boss"|"ring", "id", "count"}
@export var events: Array[Dictionary] = []
@export var crow_id: String = "e_crow"
@export var crow_line_count: int = 8
@export var crow_line_spacing: float = 80.0
@export var ring_radius: float = 760.0

@export_group("Difficulty")
## Multiply ordinary creatures' HP / contact damage (bosses have their own HP).
@export var enemy_hp_mult: float = 1.0
@export var enemy_dmg_mult: float = 1.0
## Multiplies the coins this night pays.
@export var coin_mult: float = 1.0

@export_group("Map look")
@export var ground_color: Color = Color(0.09, 0.2, 0.17)
@export var patch_color: Color = Color(0.11, 0.24, 0.19)
@export var outside_color: Color = Color(0.03, 0.09, 0.09)
## Sprite repeated around the edge of the map.
@export var edge_sprite: String = "res://assets/sprites/tree.svg"
## Non-colliding decorations scattered over the map.
@export var props: Array[String] = ["res://assets/sprites/rock.svg", "res://assets/sprites/bush.svg", "res://assets/sprites/lamp.svg"]
