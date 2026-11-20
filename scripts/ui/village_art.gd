class_name VillageArt
extends RefCounted
## Draws one village building. Each building has its own silhouette and grows
## through four stages (spec §8.4: L1, L4, L7, L10). Everything is drawn around
## (0, 0) = the middle of the building's base; up is negative y.

const STONE: Color = Color("5b6478")
const WOOD: Color = Color("6b4a2b")
const WOOD_DARK: Color = Color("3f2b1a")
const GLOW: Color = Color(1.0, 0.75, 0.3, 0.2)
const WINDOW: Color = Color("ffd36b")
const SHADOW: Color = Color(0.0, 0.0, 0.0, 0.28)


## Draws the building and returns how tall it is (for placing badges above it).
static func draw(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var top: float = 0.0
	match data.id:
		"bld_lamp_tower":
			top = _lamp_tower(c, data, stage)
		"bld_watchtower":
			top = _watchtower(c, data, stage)
		"bld_granary":
			top = _granary(c, data, stage)
		"bld_training":
			top = _training(c, data, stage)
		"bld_library":
			top = _library(c, data, stage)
		"bld_blacksmith":
			top = _house(c, data, stage)
			_blacksmith_extras(c, stage, top)
		"bld_healer":
			top = _house(c, data, stage)
			_healer_extras(c, stage)
		_:
			top = _house(c, data, stage)
	return top


static func ellipse(c: CanvasItem, centre: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 20:
		var angle: float = TAU * float(i) / 20.0
		points.append(centre + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	c.draw_colored_polygon(points, color)


static func _tri(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([a, b, d]), color)


static func _quad(c: CanvasItem, a: Vector2, b: Vector2, d: Vector2, e: Vector2, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([a, b, d, e]), color)


static func _window(c: CanvasItem, pos: Vector2, size: Vector2, lit: bool) -> void:
	c.draw_rect(Rect2(pos - Vector2(3.0, 3.0), size + Vector2(6.0, 6.0)), WOOD_DARK)
	c.draw_rect(Rect2(pos, size), WINDOW if lit else Color("2a3350"))
	if lit:
		c.draw_line(pos + Vector2(size.x * 0.5, 0.0), pos + Vector2(size.x * 0.5, size.y), WOOD_DARK, 2.0)


static func _door(c: CanvasItem, width: float, height: float, color: Color) -> void:
	c.draw_rect(Rect2(Vector2(-width * 0.5 - 3.0, -height - 3.0), Vector2(width + 6.0, height + 3.0)), WOOD_DARK)
	c.draw_rect(Rect2(Vector2(-width * 0.5, -height), Vector2(width, height)), color)
	c.draw_circle(Vector2(width * 0.25, -height * 0.45), 2.5, WINDOW)


static func _flag(c: CanvasItem, foot: Vector2, height: float, color: Color) -> void:
	c.draw_line(foot, foot - Vector2(0.0, height), WOOD_DARK, 4.0)
	_tri(c, foot - Vector2(0.0, height), foot + Vector2(34.0, -height + 11.0), foot - Vector2(0.0, height - 22.0), color)


## A gabled house: stone footing, shaded wall, two-tone roof, door, lit windows.
static func _house(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var width: float = 116.0 + stage * 14.0
	var height: float = 62.0 + stage * 8.0
	var half: float = width * 0.5
	var peak: float = height + 46.0 + stage * 6.0
	ellipse(c, Vector2(0.0, 2.0), Vector2(half + 22.0, 13.0), SHADOW)
	if stage >= 4:
		c.draw_circle(Vector2(0.0, -height), width * 0.85, GLOW)
	c.draw_rect(Rect2(Vector2(-half, -height), Vector2(width, height)), data.wall_color)
	c.draw_rect(Rect2(Vector2(half * 0.3, -height), Vector2(half * 0.7, height)), data.wall_color.darkened(0.14))
	c.draw_rect(Rect2(Vector2(-half - 4.0, -9.0), Vector2(width + 8.0, 9.0)), STONE)
	_tri(c, Vector2(-half - 16.0, -height), Vector2(0.0, -peak), Vector2(0.0, -height), data.roof_color.lightened(0.1))
	_tri(c, Vector2(0.0, -height), Vector2(0.0, -peak), Vector2(half + 16.0, -height), data.roof_color.darkened(0.12))
	c.draw_rect(Rect2(Vector2(-half - 16.0, -height - 3.0), Vector2(width + 32.0, 7.0)), data.roof_color.darkened(0.3))
	_door(c, 26.0, 40.0, data.roof_color.darkened(0.4))
	_window(c, Vector2(-half + 13.0, -height + 16.0), Vector2(22.0, 22.0), stage >= 2)
	_window(c, Vector2(half - 35.0, -height + 16.0), Vector2(22.0, 22.0), stage >= 2)
	if stage >= 3:
		c.draw_circle(Vector2(0.0, -height - 18.0), 10.0, WOOD_DARK)
		c.draw_circle(Vector2(0.0, -height - 18.0), 7.0, WINDOW)
		_flag(c, Vector2(0.0, -peak), 40.0, UiKit.DANGER)
		peak += 40.0
	if stage >= 4:
		c.draw_rect(Rect2(Vector2(-half, -height), Vector2(width, height)), UiKit.GOLD, false, 4.0)
	return peak


static func _blacksmith_extras(c: CanvasItem, stage: int, top: float) -> void:
	var half: float = (116.0 + stage * 14.0) * 0.5
	var chimney: Vector2 = Vector2(half * 0.5, -top + 34.0 + (40.0 if stage >= 3 else 0.0))
	c.draw_rect(Rect2(chimney + Vector2(-9.0, -26.0), Vector2(18.0, 50.0)), STONE)
	for i: int in 3:
		c.draw_circle(chimney + Vector2(6.0 * i, -38.0 - 15.0 * i), 9.0 + 3.0 * i, Color(0.8, 0.82, 0.9, 0.22 - 0.05 * i))
	c.draw_circle(Vector2(0.0, -16.0), 20.0, Color(1.0, 0.5, 0.15, 0.3))
	# Anvil in front of the forge.
	var anvil: Vector2 = Vector2(-half - 10.0, 0.0)
	c.draw_rect(Rect2(anvil + Vector2(-8.0, -12.0), Vector2(16.0, 12.0)), WOOD_DARK)
	_quad(c, anvil + Vector2(-20.0, -24.0), anvil + Vector2(22.0, -24.0), anvil + Vector2(14.0, -12.0), anvil + Vector2(-12.0, -12.0), Color("8c93a6"))


static func _healer_extras(c: CanvasItem, stage: int) -> void:
	var half: float = (116.0 + stage * 14.0) * 0.5
	# Hanging leaf sign and herb pots.
	c.draw_circle(Vector2(0.0, -56.0), 13.0, WOOD_DARK)
	ellipse(c, Vector2(0.0, -56.0), Vector2(5.0, 9.0), Color("6fe08a"))
	for i: int in mini(stage + 1, 4):
		var side: float = -1.0 if i % 2 == 0 else 1.0
		@warning_ignore("integer_division")
		var pot: Vector2 = Vector2(side * (half + 12.0 + 20.0 * float(i / 2)), 0.0)
		c.draw_rect(Rect2(pot + Vector2(-8.0, -12.0), Vector2(16.0, 12.0)), Color("a3542b"))
		c.draw_circle(pot + Vector2(-4.0, -17.0), 7.0, Color("3e7a3a"))
		c.draw_circle(pot + Vector2(5.0, -19.0), 7.0, Color("5fae58"))


## A tall tapered stone tower with a glowing lantern room.
static func _lamp_tower(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var base: float = 34.0 + stage * 4.0
	var neck: float = base * 0.68
	var height: float = 80.0 + stage * 12.0
	ellipse(c, Vector2(0.0, 2.0), Vector2(base + 22.0, 13.0), SHADOW)
	c.draw_circle(Vector2(0.0, -height - 20.0), 40.0 + stage * 9.0, GLOW)
	_quad(c, Vector2(-base, 0.0), Vector2(-neck, -height), Vector2(neck, -height), Vector2(base, 0.0), data.wall_color)
	_quad(c, Vector2(base * 0.3, 0.0), Vector2(neck * 0.3, -height), Vector2(neck, -height), Vector2(base, 0.0), data.wall_color.darkened(0.14))
	for i: int in stage + 1:
		var y: float = -height * float(i + 1) / float(stage + 2)
		c.draw_line(Vector2(-base, y), Vector2(base, y), data.wall_color.darkened(0.3), 3.0)
	_door(c, 20.0, 32.0, WOOD)
	c.draw_rect(Rect2(Vector2(-neck - 10.0, -height - 6.0), Vector2(neck * 2.0 + 20.0, 8.0)), STONE)
	c.draw_rect(Rect2(Vector2(-neck + 2.0, -height - 38.0), Vector2(neck * 2.0 - 4.0, 32.0)), WINDOW)
	c.draw_line(Vector2(0.0, -height - 38.0), Vector2(0.0, -height - 6.0), WOOD_DARK, 3.0)
	c.draw_circle(Vector2(0.0, -height - 22.0), 8.0, Color("fff3c4"))
	_tri(c, Vector2(-neck - 12.0, -height - 38.0), Vector2(0.0, -height - 72.0), Vector2(neck + 12.0, -height - 38.0), data.roof_color)
	if stage >= 4:
		c.draw_line(Vector2(-base, 0.0), Vector2(-neck, -height), UiKit.GOLD, 4.0)
		c.draw_line(Vector2(base, 0.0), Vector2(neck, -height), UiKit.GOLD, 4.0)
	return height + 72.0


## A wooden lookout cabin on braced stilts.
static func _watchtower(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var legs: float = 58.0 + stage * 9.0
	var half: float = 38.0 + stage * 5.0
	ellipse(c, Vector2(0.0, 2.0), Vector2(half + 30.0, 12.0), SHADOW)
	for side: float in [-1.0, 1.0]:
		c.draw_line(Vector2(side * (half + 10.0), 0.0), Vector2(side * half * 0.75, -legs), WOOD, 8.0)
	c.draw_line(Vector2(-half - 6.0, -legs * 0.2), Vector2(half * 0.8, -legs * 0.85), WOOD_DARK, 4.0)
	c.draw_line(Vector2(half + 6.0, -legs * 0.2), Vector2(-half * 0.8, -legs * 0.85), WOOD_DARK, 4.0)
	for i: int in 5:
		var y: float = -legs * float(i + 1) / 6.0
		c.draw_line(Vector2(-7.0, y), Vector2(7.0, y), WOOD_DARK, 3.0)
	c.draw_line(Vector2(-7.0, 0.0), Vector2(-7.0, -legs), WOOD_DARK, 3.0)
	c.draw_line(Vector2(7.0, 0.0), Vector2(7.0, -legs), WOOD_DARK, 3.0)
	c.draw_rect(Rect2(Vector2(-half - 12.0, -legs - 8.0), Vector2(half * 2.0 + 24.0, 10.0)), WOOD_DARK)
	var cabin: float = 40.0 + stage * 3.0
	c.draw_rect(Rect2(Vector2(-half, -legs - 8.0 - cabin), Vector2(half * 2.0, cabin)), data.wall_color)
	c.draw_rect(Rect2(Vector2(half * 0.3, -legs - 8.0 - cabin), Vector2(half * 0.7, cabin)), data.wall_color.darkened(0.14))
	_window(c, Vector2(-12.0, -legs - cabin + 4.0), Vector2(24.0, 20.0), stage >= 2)
	var eave: float = legs + 8.0 + cabin
	_tri(c, Vector2(-half - 14.0, -eave), Vector2(0.0, -eave - 40.0), Vector2(0.0, -eave), data.roof_color.lightened(0.1))
	_tri(c, Vector2(0.0, -eave), Vector2(0.0, -eave - 40.0), Vector2(half + 14.0, -eave), data.roof_color.darkened(0.12))
	var top: float = eave + 40.0
	if stage >= 3:
		_flag(c, Vector2(0.0, -top), 38.0, UiKit.DANGER)
		top += 38.0
	if stage >= 4:
		c.draw_rect(Rect2(Vector2(-half, -legs - 8.0 - cabin), Vector2(half * 2.0, cabin)), UiKit.GOLD, false, 4.0)
	return top


## A round grain store with a domed roof and sacks stacked outside.
static func _granary(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var half: float = 44.0 + stage * 7.0
	var height: float = 70.0 + stage * 12.0
	ellipse(c, Vector2(0.0, 2.0), Vector2(half + 26.0, 13.0), SHADOW)
	if stage >= 4:
		c.draw_circle(Vector2(0.0, -height), half * 1.9, GLOW)
	c.draw_rect(Rect2(Vector2(-half, -height), Vector2(half * 2.0, height)), data.wall_color)
	c.draw_rect(Rect2(Vector2(half * 0.35, -height), Vector2(half * 0.65, height)), data.wall_color.darkened(0.14))
	ellipse(c, Vector2(0.0, 0.0), Vector2(half, 9.0), data.wall_color.darkened(0.25))
	for i: int in stage + 1:
		var y: float = -height * float(i + 1) / float(stage + 2)
		c.draw_line(Vector2(-half, y), Vector2(half, y), WOOD_DARK, 3.0)
	ellipse(c, Vector2(0.0, -height), Vector2(half + 12.0, 34.0 + stage * 4.0), data.roof_color)
	c.draw_rect(Rect2(Vector2(-half, -height), Vector2(half * 2.0, 40.0)), data.wall_color)
	c.draw_rect(Rect2(Vector2(half * 0.35, -height), Vector2(half * 0.65, 40.0)), data.wall_color.darkened(0.14))
	c.draw_rect(Rect2(Vector2(-half - 12.0, -height - 3.0), Vector2(half * 2.0 + 24.0, 7.0)), data.roof_color.darkened(0.3))
	c.draw_circle(Vector2(0.0, -height - 34.0 - stage * 4.0), 6.0, WINDOW if stage >= 3 else WOOD_DARK)
	_door(c, 24.0, 36.0, WOOD)
	for i: int in stage + 1:
		var sack: Vector2 = Vector2(half + 12.0 + 17.0 * float(i % 2), -9.0 - 15.0 * float(i / 2))
		ellipse(c, sack, Vector2(12.0, 10.0), Color("c9a86a"))
		c.draw_line(sack + Vector2(-5.0, -8.0), sack + Vector2(5.0, -8.0), WOOD_DARK, 2.0)
	if stage >= 4:
		c.draw_rect(Rect2(Vector2(-half, -height), Vector2(half * 2.0, height)), UiKit.GOLD, false, 4.0)
	return height + 40.0 + stage * 4.0


## A fenced yard with practice dummies, a tent and (later) a banner.
static func _training(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var half: float = 78.0 + stage * 8.0
	ellipse(c, Vector2(0.0, -6.0), Vector2(half + 10.0, 24.0), Color("3a3426"))
	# Tent at the back.
	var tent: float = 54.0 + stage * 10.0
	_tri(c, Vector2(-half * 0.75, -14.0), Vector2(-half * 0.3, -14.0 - tent), Vector2(-half * 0.3, -14.0), data.wall_color.lightened(0.08))
	_tri(c, Vector2(-half * 0.3, -14.0), Vector2(-half * 0.3, -14.0 - tent), Vector2(half * 0.15, -14.0), data.wall_color.darkened(0.14))
	_tri(c, Vector2(-half * 0.38, -14.0), Vector2(-half * 0.3, -14.0 - tent * 0.55), Vector2(-half * 0.2, -14.0), WOOD_DARK)
	c.draw_line(Vector2(-half * 0.75, -14.0), Vector2(-half * 0.3, -14.0 - tent), data.roof_color, 5.0)
	c.draw_line(Vector2(half * 0.15, -14.0), Vector2(-half * 0.3, -14.0 - tent), data.roof_color, 5.0)
	# Practice dummies with targets.
	for i: int in mini(stage, 3):
		var foot: Vector2 = Vector2(half * (0.42 + 0.26 * float(i)) - 10.0, -6.0 + 5.0 * float(i))
		c.draw_line(foot, foot - Vector2(0.0, 52.0), WOOD, 6.0)
		c.draw_line(foot + Vector2(-17.0, -36.0), foot + Vector2(17.0, -36.0), WOOD, 5.0)
		c.draw_circle(foot - Vector2(0.0, 58.0), 10.0, Color("c9a86a"))
		c.draw_circle(foot - Vector2(0.0, 28.0), 11.0, Color("fff3c4"))
		c.draw_circle(foot - Vector2(0.0, 28.0), 6.0, UiKit.DANGER)
	# Fence in front.
	for i: int in 7:
		var x: float = lerpf(-half, half, float(i) / 6.0)
		c.draw_line(Vector2(x, 8.0), Vector2(x, -18.0), WOOD, 5.0)
	c.draw_line(Vector2(-half, -12.0), Vector2(half, -12.0), WOOD_DARK, 4.0)
	c.draw_line(Vector2(-half, 0.0), Vector2(half, 0.0), WOOD_DARK, 4.0)
	var top: float = 14.0 + tent
	if stage >= 3:
		_flag(c, Vector2(-half * 0.3, -14.0 - tent), 36.0, UiKit.DANGER)
		top += 36.0
	if stage >= 4:
		c.draw_line(Vector2(-half, -12.0), Vector2(half, -12.0), UiKit.GOLD, 3.0)
		c.draw_circle(Vector2(-half * 0.3, -40.0), tent * 1.2, GLOW)
	return top


## A wide hall with columns, steps and a low pediment.
static func _library(c: CanvasItem, data: BuildingData, stage: int) -> float:
	var half: float = 68.0 + stage * 9.0
	var height: float = 60.0 + stage * 8.0
	ellipse(c, Vector2(0.0, 2.0), Vector2(half + 26.0, 13.0), SHADOW)
	if stage >= 4:
		c.draw_circle(Vector2(0.0, -height), half * 1.5, GLOW)
	c.draw_rect(Rect2(Vector2(-half - 12.0, -8.0), Vector2(half * 2.0 + 24.0, 8.0)), STONE)
	c.draw_rect(Rect2(Vector2(-half - 5.0, -15.0), Vector2(half * 2.0 + 10.0, 7.0)), STONE.lightened(0.15))
	c.draw_rect(Rect2(Vector2(-half, -15.0 - height), Vector2(half * 2.0, height)), data.wall_color)
	c.draw_rect(Rect2(Vector2(half * 0.4, -15.0 - height), Vector2(half * 0.6, height)), data.wall_color.darkened(0.14))
	var columns: int = 3 + stage
	for i: int in columns:
		var x: float = lerpf(-half + 9.0, half - 9.0, float(i) / float(columns - 1))
		c.draw_rect(Rect2(Vector2(x - 6.0, -15.0 - height), Vector2(12.0, height)), data.wall_color.lightened(0.3))
		c.draw_rect(Rect2(Vector2(x - 9.0, -21.0), Vector2(18.0, 6.0)), data.wall_color.lightened(0.4))
	c.draw_rect(Rect2(Vector2(-14.0, -15.0 - 40.0), Vector2(28.0, 40.0)), WINDOW if stage >= 2 else WOOD_DARK)
	c.draw_rect(Rect2(Vector2(-half - 10.0, -23.0 - height), Vector2(half * 2.0 + 20.0, 10.0)), data.roof_color.darkened(0.3))
	var eave: float = 23.0 + height
	var peak: float = eave + 30.0 + stage * 5.0
	_tri(c, Vector2(-half - 10.0, -eave), Vector2(0.0, -peak), Vector2(half + 10.0, -eave), data.roof_color)
	# An open book in the pediment.
	_quad(c, Vector2(-13.0, -eave - 8.0), Vector2(0.0, -eave - 5.0), Vector2(0.0, -eave - 18.0), Vector2(-13.0, -eave - 21.0), Color("fff3c4"))
	_quad(c, Vector2(13.0, -eave - 8.0), Vector2(0.0, -eave - 5.0), Vector2(0.0, -eave - 18.0), Vector2(13.0, -eave - 21.0), Color("e9dcae"))
	if stage >= 3:
		_flag(c, Vector2(0.0, -peak), 36.0, UiKit.DANGER)
		peak += 36.0
	if stage >= 4:
		c.draw_rect(Rect2(Vector2(-half, -15.0 - height), Vector2(half * 2.0, height)), UiKit.GOLD, false, 4.0)
	return peak
