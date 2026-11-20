class_name VillageView
extends Control
## The village (spec §8.4): every building is drawn from its level, visibly
## changing at L1, L4, L7 and L10, and more lamps light up as the village grows.

signal building_selected(id: String)

const PLOT: Vector2 = Vector2(330.0, 330.0)
## Buildings are authored small and drawn enlarged so they read well on a phone.
const DRAW_SCALE: float = 1.5
const GROUND: Color = Color("16302b")
const PATH: Color = Color("4a4130")
const PATH_EDGE: Color = Color("2a2a22")
const TREE: Texture2D = preload("res://assets/sprites/tree.svg")
const BUSH: Texture2D = preload("res://assets/sprites/bush.svg")
const GROUND_SEED: int = 4711
const TUFT_COUNT: int = 70
const TREE_COUNT: int = 40
const TREE_CLEARANCE: float = 250.0
const BADGE_MAX_HEIGHT: float = 150.0
const LABEL_MARGIN: float = 6.0
const PLOT_FILL: Color = Color("223d38")
const LAMP_COUNT: int = 14
const TIER_LEVELS: Array[int] = [1, 4, 7, 10]

var _font: Font
## Building id -> drawn height, from the last art pass.
var _tops: Dictionary = {}


func _ready() -> void:
	_font = ThemeDB.fallback_font
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)


## 0 = empty plot, 1..4 = the four visual stages.
static func tier(level: int) -> int:
	var out: int = 0
	for threshold: int in TIER_LEVELS:
		if level >= threshold:
			out += 1
	return out


func _centre(data: BuildingData) -> Vector2:
	return Vector2(size.x * data.village_pos.x, size.y * data.village_pos.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click: InputEventMouseButton = event
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			for data: BuildingData in GameData.buildings():
				if Rect2(_centre(data) - PLOT * 0.5, PLOT).has_point(click.position):
					AudioManager.play("click")
					building_selected.emit(data.id)
					return


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	_draw_ground()
	var hub: Vector2 = size * 0.5
	for data: BuildingData in GameData.buildings():
		draw_line(hub, _centre(data) + Vector2(0.0, 60.0), PATH_EDGE, 40.0)
	for data: BuildingData in GameData.buildings():
		draw_line(hub, _centre(data) + Vector2(0.0, 60.0), PATH, 26.0)
		draw_circle(_centre(data) + Vector2(0.0, 60.0), 13.0, PATH)
	VillageArt.ellipse(self, hub + Vector2(0.0, 60.0), Vector2(150.0, 84.0), PATH_EDGE)
	VillageArt.ellipse(self, hub + Vector2(0.0, 60.0), Vector2(138.0, 74.0), PATH)
	_draw_lamps()
	var buildings: Array[BuildingData] = GameData.buildings()
	buildings.sort_custom(func(a: BuildingData, b: BuildingData) -> bool: return a.village_pos.y < b.village_pos.y)
	for data: BuildingData in buildings:
		_draw_building(data)
	for data: BuildingData in buildings:
		_draw_label(data)


## Grass tufts and a ring of trees. Seeded, so the village looks the same every time.
func _draw_ground() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GROUND_SEED
	for i: int in TUFT_COUNT:
		var pos: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		VillageArt.ellipse(self, pos, Vector2(rng.randf_range(14.0, 40.0), rng.randf_range(6.0, 14.0)),
			GROUND.lightened(rng.randf_range(0.03, 0.09)))
	for i: int in TREE_COUNT:
		var pos: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var clear: bool = pos.distance_to(size * 0.5) > TREE_CLEARANCE
		for data: BuildingData in GameData.buildings():
			clear = clear and pos.distance_to(_centre(data)) > TREE_CLEARANCE
		if clear:
			var texture: Texture2D = TREE if i % 3 != 0 else BUSH
			draw_texture(texture, pos - Vector2(texture.get_size().x * 0.5, texture.get_size().y), Color(1.0, 1.0, 1.0, 0.9))


func _draw_lamps() -> void:
	var max_total: int = 0
	for data: BuildingData in GameData.buildings():
		max_total += data.max_level
	@warning_ignore("integer_division")
	var lit: int = VillageLogic.total_level() * LAMP_COUNT / maxi(max_total, 1)
	if VillageLogic.total_level() > 0:
		lit = maxi(lit, 1)
	for i: int in LAMP_COUNT:
		var angle: float = TAU * float(i) / float(LAMP_COUNT) + 0.2
		var pos: Vector2 = size * 0.5 + Vector2(cos(angle) * size.x * 0.4, sin(angle) * size.y * 0.42)
		draw_line(pos, pos + Vector2(0.0, 40.0), Color("4a3a2a"), 6.0)
		if i < lit:
			draw_circle(pos, 34.0, Color(1.0, 0.7, 0.28, 0.22))
			draw_circle(pos, 13.0, UiKit.GOLD)
		else:
			draw_circle(pos, 11.0, Color("2a3350"))


func _draw_building(data: BuildingData) -> void:
	var level: int = GameState.building_level(data.id)
	var stage: int = tier(level)
	draw_set_transform(_centre(data) + Vector2(0.0, 70.0), 0.0, Vector2(DRAW_SCALE, DRAW_SCALE))
	var base: Vector2 = Vector2.ZERO
	var top: float = 86.0
	if stage == 0:
		var plot: Rect2 = Rect2(base + Vector2(-80.0, -70.0), Vector2(160.0, 80.0))
		draw_rect(plot, PLOT_FILL)
		draw_rect(plot, Color(1, 1, 1, 0.35), false, 4.0)
		draw_string(_font, base + Vector2(-14.0, -14.0), "+", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 54, UiKit.AMBER)
	else:
		top = VillageArt.draw(self, data, stage)
	_tops[data.id] = top
	draw_set_transform(Vector2.ZERO)


## Name plate, build timer and the "can afford" badge, drawn above every building.
func _draw_label(data: BuildingData) -> void:
	var level: int = GameState.building_level(data.id)
	var base: Vector2 = Vector2.ZERO
	var job: Dictionary = VillageLogic.job_for(data.id)
	var top: float = float(_tops.get(data.id, 86.0))
	draw_set_transform(_centre(data) + Vector2(0.0, 70.0), 0.0, Vector2(DRAW_SCALE, DRAW_SCALE))
	var title: String = data.display_name if level == 0 else "%s  Lv %d" % [data.display_name, level]
	var text_size: Vector2 = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28)
	# Keep the name plate inside the view for buildings near the left or right edge.
	var half: float = (text_size.x * 0.5 + 10.0) * DRAW_SCALE
	var centre_x: float = _centre(data).x
	var shift: float = (clampf(centre_x, half + LABEL_MARGIN, size.x - half - LABEL_MARGIN) - centre_x) / DRAW_SCALE
	draw_rect(Rect2(base + Vector2(shift - text_size.x * 0.5 - 10.0, 10.0), Vector2(text_size.x + 20.0, 34.0)), Color(0.04, 0.05, 0.1, 0.6))
	draw_string(_font, base + Vector2(shift - text_size.x * 0.5, 36.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, UiKit.TEXT)
	if not job.is_empty():
		var timer: String = "⏳ " + UiKit.duration(VillageLogic.remaining(job))
		var timer_size: Vector2 = _font.get_string_size(timer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28)
		draw_string(_font, base + Vector2(-timer_size.x * 0.5, 72.0), timer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, UiKit.AMBER)
	if VillageLogic.blocker(data.id).is_empty():
		var badge: Vector2 = base + Vector2(78.0, -minf(top, BADGE_MAX_HEIGHT))
		draw_circle(badge, 22.0, UiKit.GOOD)
		draw_colored_polygon(PackedVector2Array([badge + Vector2(-11.0, 7.0), badge + Vector2(0.0, -12.0), badge + Vector2(11.0, 7.0)]), UiKit.DARK_TEXT)
	draw_set_transform(Vector2.ZERO)
