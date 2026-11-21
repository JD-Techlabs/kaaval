class_name VillageArtExtras
extends RefCounted
## Details that set the age buildings apart, drawn next to the shared house
## shape (by `emblem`). (0, 0) is the middle of the base; up is negative y.

const WOOD: Color = Color("6b4a2b")
const WOOD_DARK: Color = Color("3f2b1a")
const STEEL: Color = Color("8c93a6")
const SMOKE: Color = Color(0.8, 0.82, 0.9, 0.22)
const LIGHT: Color = Color("ffd36b")


static func draw(c: CanvasItem, data: BuildingData, stage: int, top: float) -> void:
	var half: float = (116.0 + stage * 14.0) * 0.5
	match data.emblem:
		"farm":
			_farm(c, half, stage)
		"logs":
			_logs(c, half, stage)
		"rocks":
			_rocks(c, half, stage)
		"sacks":
			_chimney(c, Vector2(half * 0.45, -top + 30.0), 1)
			_sacks(c, half, stage)
		"wheel":
			_wheel(c, half, stage)
		"derrick":
			_derrick(c, half, stage)
		"chimneys":
			for i: int in mini(stage + 1, 3):
				_chimney(c, Vector2(-half * 0.6 + half * 0.6 * i, -top + 40.0), i)
		"shield":
			_shield(c, Vector2(0.0, -top + 14.0))
		"dish":
			_dish(c, Vector2(half * 0.4, -top + 20.0), stage)


## Rows of crops beside the barn; more rows as it grows.
static func _farm(c: CanvasItem, half: float, stage: int) -> void:
	for side: float in [-1.0, 1.0]:
		for row: int in mini(stage + 1, 4):
			var y: float = -6.0 - row * 12.0
			var x0: float = side * (half + 12.0)
			c.draw_line(Vector2(x0, y), Vector2(x0 + side * 46.0, y), Color("7a5a2a"), 6.0)
			for k: int in 4:
				c.draw_circle(Vector2(x0 + side * (6.0 + 12.0 * k), y - 5.0), 5.0, Color("8fcf5a"))


static func _logs(c: CanvasItem, half: float, stage: int) -> void:
	var count: int = mini(stage + 2, 5)
	for i: int in count:
		var pos: Vector2 = Vector2(half + 26.0 + (i % 3) * 18.0, -8.0 - floorf(i / 3.0) * 16.0)
		c.draw_circle(pos, 9.0, WOOD)
		c.draw_circle(pos, 5.0, Color("c48a4a"))
	# Chopping block with an axe.
	c.draw_rect(Rect2(Vector2(-half - 34.0, -16.0), Vector2(22.0, 16.0)), WOOD_DARK)
	c.draw_line(Vector2(-half - 23.0, -16.0), Vector2(-half - 12.0, -40.0), WOOD, 4.0)
	c.draw_rect(Rect2(Vector2(-half - 16.0, -44.0), Vector2(12.0, 9.0)), STEEL)


static func _rocks(c: CanvasItem, half: float, stage: int) -> void:
	for i: int in mini(stage + 1, 4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var base: Vector2 = Vector2(side * (half + 22.0 + 14.0 * floorf(i / 2.0)), 0.0)
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-18.0, 0.0), base + Vector2(-10.0, -24.0),
			base + Vector2(8.0, -28.0), base + Vector2(18.0, 0.0)]), STEEL)
		c.draw_line(base + Vector2(-6.0, -18.0), base + Vector2(6.0, -10.0), Color("c9d0dc"), 3.0)


static func _sacks(c: CanvasItem, half: float, stage: int) -> void:
	for i: int in mini(stage + 1, 4):
		var pos: Vector2 = Vector2(-half - 18.0 - 18.0 * (i % 2), -12.0 - 16.0 * floorf(i / 2.0))
		VillageArt.ellipse(c, pos, Vector2(11.0, 13.0), Color("e9dcae"))
		c.draw_line(pos + Vector2(-5.0, -11.0), pos + Vector2(5.0, -11.0), WOOD_DARK, 3.0)


## A water wheel on the side, with more paddles as it grows.
static func _wheel(c: CanvasItem, half: float, stage: int) -> void:
	var centre: Vector2 = Vector2(half + 30.0, -34.0)
	c.draw_circle(centre, 32.0, WOOD_DARK)
	c.draw_circle(centre, 26.0, WOOD)
	var spokes: int = 4 + stage * 2
	for i: int in spokes:
		var dir: Vector2 = Vector2.from_angle(TAU * float(i) / float(spokes))
		c.draw_line(centre, centre + dir * 32.0, WOOD_DARK, 4.0)
	c.draw_circle(centre, 6.0, STEEL)
	c.draw_rect(Rect2(Vector2(half + 4.0, -4.0), Vector2(56.0, 6.0)), Color("3f7aa0"))


static func _derrick(c: CanvasItem, half: float, stage: int) -> void:
	var foot: Vector2 = Vector2(-half - 34.0, 0.0)
	var height: float = 80.0 + stage * 14.0
	c.draw_line(foot + Vector2(-20.0, 0.0), foot + Vector2(0.0, -height), WOOD_DARK, 5.0)
	c.draw_line(foot + Vector2(20.0, 0.0), foot + Vector2(0.0, -height), WOOD_DARK, 5.0)
	for i: int in 3:
		var y: float = -height * (0.25 + 0.25 * i)
		var w: float = 20.0 * (1.0 - (0.25 + 0.25 * i))
		c.draw_line(foot + Vector2(-w, y), foot + Vector2(w, y), WOOD_DARK, 3.0)
	c.draw_rect(Rect2(Vector2(half + 8.0, -26.0), Vector2(22.0, 26.0)), Color("2c2c34"))
	c.draw_rect(Rect2(Vector2(half + 34.0, -26.0), Vector2(22.0, 26.0)), Color("2c2c34"))


static func _chimney(c: CanvasItem, pos: Vector2, index: int) -> void:
	c.draw_rect(Rect2(pos + Vector2(-9.0, -30.0), Vector2(18.0, 54.0)), Color("8a3b2a"))
	c.draw_rect(Rect2(pos + Vector2(-11.0, -34.0), Vector2(22.0, 6.0)), WOOD_DARK)
	for i: int in 3:
		c.draw_circle(pos + Vector2(6.0 * i + 3.0 * index, -46.0 - 15.0 * i), 9.0 + 3.0 * i,
			Color(SMOKE.r, SMOKE.g, SMOKE.b, SMOKE.a - 0.05 * i))


static func _shield(c: CanvasItem, pos: Vector2) -> void:
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(-16.0, -18.0), pos + Vector2(16.0, -18.0),
		pos + Vector2(16.0, 0.0), pos + Vector2(0.0, 16.0), pos + Vector2(-16.0, 0.0)]), STEEL)
	c.draw_line(pos + Vector2(0.0, -14.0), pos + Vector2(0.0, 10.0), LIGHT, 4.0)


## A dish antenna on the roof with a blinking light.
static func _dish(c: CanvasItem, pos: Vector2, stage: int) -> void:
	c.draw_line(pos, pos + Vector2(0.0, -26.0), STEEL, 4.0)
	VillageArt.ellipse(c, pos + Vector2(0.0, -34.0), Vector2(22.0, 10.0), Color("e8ecf2"))
	c.draw_line(pos + Vector2(0.0, -34.0), pos + Vector2(10.0, -50.0), STEEL, 3.0)
	c.draw_circle(pos + Vector2(10.0, -52.0), 4.0 + stage, Color("59d6c9"))
