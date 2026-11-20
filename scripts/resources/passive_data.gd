class_name PassiveData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var max_level: int = 5
@export var sort_order: int = 0
## Stat key understood by PlayerStats.
@export var stat: String = ""
## "add" (flat) or "pct" (fraction of the base value).
@export var mode: String = "add"
@export var per_level: float = 0.0
