class_name AgeData
extends Resource
## One age of the village. Ages are reached in `sort_order`; advancing needs
## the listed building levels and pays `advance_cost`. Everything is data.

@export var id: String = ""
@export var display_name: String = ""
## 1 = the starting age.
@export var sort_order: int = 0
## One line shown on the age panel.
@export var tagline: String = ""
## Resources that runs pay out while in this age (timber is always paid).
@export var resources: Array[String] = []
## Highest building level allowed in this age.
@export var building_cap: int = 3
## Building levels needed to advance INTO this age: {building_id: level}.
@export var required_buildings: Dictionary = {}
## Resources spent to advance INTO this age: {kind: amount}.
@export var advance_cost: Dictionary = {}

@export_group("Difficulty and rewards")
## Multiply ordinary creatures' HP / contact damage on every night.
@export var enemy_hp_mult: float = 1.0
@export var enemy_dmg_mult: float = 1.0
## Multiplies the resources (not coins) a run pays.
@export var resource_mult: float = 1.0
