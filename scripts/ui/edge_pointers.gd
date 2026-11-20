class_name EdgePointers
extends Control
## Arrows at the screen edge pointing to off-screen bosses, boss chests and
## (when hurt) life potions,
## so the player never has to hunt for them in the dark.

const TOP_MARGIN: float = 440.0
const SIDE_MARGIN: float = 70.0
const BOTTOM_MARGIN: float = 160.0
const ARROW: float = 34.0
const BOSS_COLOR: Color = Color("e2553d")
const CHEST_COLOR: Color = Color("ffd36b")
const POTION_COLOR: Color = Color("6fe08a")

var run: RunManager


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for boss: Enemy in run.enemies.bosses:
		if boss.alive:
			_pointer(boss.position, BOSS_COLOR)
	for chest: Vector2 in run.chest_positions():
		_pointer(chest, CHEST_COLOR)
	# Potions are only pointed out when the hero actually needs one.
	var player: Player = run.player
	if player.hp <= player.stats.max_hp * GameData.num("potion", "low_hp_threshold"):
		for potion: Vector2 in run.potions.positions():
			_pointer(potion, POTION_COLOR)


func _pointer(world_pos: Vector2, color: Color) -> void:
	var target: Vector2 = run.to_screen(world_pos)
	var area: Rect2 = Rect2(Vector2(SIDE_MARGIN, TOP_MARGIN), size - Vector2(SIDE_MARGIN * 2.0, TOP_MARGIN + BOTTOM_MARGIN))
	if area.has_point(target):
		return
	var at: Vector2 = target.clamp(area.position, area.end)
	var direction: Vector2 = (target - at).normalized()
	var side: Vector2 = direction.orthogonal()
	draw_circle(at, ARROW * 0.9, Color(0.04, 0.05, 0.1, 0.7))
	draw_colored_polygon(PackedVector2Array([at + direction * ARROW, at - direction * ARROW * 0.5 + side * ARROW * 0.7,
		at - direction * ARROW * 0.5 - side * ARROW * 0.7]), color)
