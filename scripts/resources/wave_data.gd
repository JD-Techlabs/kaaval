class_name WaveData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
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
