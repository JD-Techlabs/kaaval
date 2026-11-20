class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var texture: String = ""
@export var hp: float = 10.0
@export var speed: float = 100.0
@export var contact_damage: float = 5.0
@export var xp: float = 1.0
@export var radius: float = 20.0
## "chase", "line" or "thief".
@export var behaviour: String = "chase"
## Enemy spawned on death ("" = none) and how many.
@export var split_id: String = ""
@export var split_count: int = 0
## Behaviour-specific tunables.
@export var params: Dictionary = {}
