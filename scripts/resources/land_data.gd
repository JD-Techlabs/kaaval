class_name LandData
extends Resource
## A piece of land around the village. Bought with coins once the village has
## reached `required_age`; its buildings can then be built.

@export var id: String = ""
@export var display_name: String = ""
## Order on the village map, 0 = the village green at the top.
@export var sort_order: int = 0
@export var description: String = ""
## 0 = owned from the start.
@export var coin_cost: int = 0
## AgeData id the village must have reached to buy it.
@export var required_age: String = "age_founders"
@export var ground_color: Color = Color("16302b")
