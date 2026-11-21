class_name VillageView
extends Control
## The village map (spec §8.4): the village green on top, then a band for each
## piece of land below it. Buildings are drawn from their level, visibly
## changing at L1, L4, L7 and L10; land not yet bought shows a "for sale" sign.
## Lives inside a vertical ScrollContainer; call set_visible_height() on resize.

signal building_selected(id: String)
signal land_selected(id: String)

const PLOT: Vector2 = Vector2(250.0, 250.0)
## Buildings are drawn at their authored size so the village has room to
## breathe; name plates and badges are drawn a little larger to stay readable.
const BUILDING_SCALE: float = 1.0
const LABEL_SCALE: float = 1.2
## Building base sits this far below its village position.
const FOOT_OFFSET: float = 50.0
const BAND_HEIGHT: float = 380.0
const PATH: Color = Color("4a4130")
const PATH_EDGE: Color = Color("2a2a22")
const FENCE: Color = Color("6b4a2b")
const TREE: Texture2D = preload("res://assets/sprites/tree.svg")
const BUSH: Texture2D = preload("res://assets/sprites/bush.svg")
const GROUND_SEED: int = 4711
const TUFTS_PER_SCREEN: int = 70
const TREES_PER_SCREEN: int = 40
const TREE_CLEARANCE: float = 190.0
const BADGE_MAX_HEIGHT: float = 120.0
const LABEL_MARGIN: float = 6.0
const PLOT_FILL: Color = Color("223d38")
const LAMP_COUNT: int = 14
const TIER_LEVELS: Array[int] = [1, 4, 7, 10]
## A press that moves further than this is a scroll, not a tap.
const TAP_SLOP: float = 24.0

var _font: Font
## Building id -> drawn height, from the last art pass.
var _tops: Dictionary = {}
var _core_height: float = 700.0
var _press: Vector2 = Vector2.INF
var _icons: Dictionary = {}


func _ready() -> void:
	_font = UiKit.font()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)


## The village green fills the visible area; land bands extend below it.
func set_visible_height(height: float) -> void:
	_core_height = maxf(height, 400.0)
	custom_minimum_size.y = _core_height + BAND_HEIGHT * float(GameData.lands().size() - 1)
	queue_redraw()


## 0 = empty plot, 1..4 = the four visual stages.
static func tier(level: int) -> int:
	var out: int = 0
	for threshold: int in TIER_LEVELS:
		if level >= threshold:
			out += 1
	return out


func land_rect(land: LandData) -> Rect2:
	var index: int = GameData.lands().find(land)
	if index <= 0:
		return Rect2(0.0, 0.0, size.x, _core_height)
	return Rect2(0.0, _core_height + BAND_HEIGHT * float(index - 1), size.x, BAND_HEIGHT)


func _centre(data: BuildingData) -> Vector2:
	var rect: Rect2 = land_rect(GameData.land(data.land))
	return rect.position + rect.size * data.village_pos


func _shown(data: BuildingData) -> bool:
	return GameData.land(data.land) != null and LandLogic.owned(data.land)


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		_press = click.position
	elif _press != Vector2.INF:
		if click.position.distance_to(_press) <= TAP_SLOP:
			_tap(click.position)
		_press = Vector2.INF


func _tap(pos: Vector2) -> void:
	for data: BuildingData in GameData.buildings():
		if _shown(data) and Rect2(_centre(data) - PLOT * 0.5, PLOT).has_point(pos):
			AudioManager.play("click")
			building_selected.emit(data.id)
			return
	for land: LandData in GameData.lands():
		if not LandLogic.owned(land.id) and land_rect(land).has_point(pos):
			AudioManager.play("click")
			land_selected.emit(land.id)
			return


func _draw() -> void:
	for land: LandData in GameData.lands():
		draw_rect(land_rect(land), land.ground_color)
	_draw_ground()
	_draw_paths()
	_draw_lamps()
	var buildings: Array[BuildingData] = []
	for data: BuildingData in GameData.buildings():
		if _shown(data):
			buildings.append(data)
	buildings.sort_custom(func(a: BuildingData, b: BuildingData) -> bool: return _centre(a).y < _centre(b).y)
	for data: BuildingData in buildings:
		_draw_building(data)
	for land: LandData in GameData.lands():
		_draw_land_edge(land)
	for data: BuildingData in buildings:
		_draw_label(data)


## Grass tufts and trees. Seeded, so the village looks the same every time.
func _draw_ground() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = GROUND_SEED
	var screens: float = maxf(size.y / maxf(_core_height, 1.0), 1.0)
	for i: int in roundi(TUFTS_PER_SCREEN * screens):
		var pos: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		VillageArt.ellipse(self, pos, Vector2(rng.randf_range(14.0, 40.0), rng.randf_range(6.0, 14.0)),
			Color(1.0, 1.0, 1.0, rng.randf_range(0.03, 0.07)))
	var hub: Vector2 = Vector2(size.x * 0.5, _core_height * 0.5)
	for i: int in roundi(TREES_PER_SCREEN * screens):
		var pos: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var clear: bool = pos.distance_to(hub) > TREE_CLEARANCE and absf(pos.x - size.x * 0.5) > 60.0
		for data: BuildingData in GameData.buildings():
			clear = clear and pos.distance_to(_centre(data)) > TREE_CLEARANCE
		if clear:
			var texture: Texture2D = TREE if i % 3 != 0 else BUSH
			draw_texture(texture, pos - Vector2(texture.get_size().x * 0.5, texture.get_size().y), Color(1.0, 1.0, 1.0, 0.9))


## Paths from the green's hub to its buildings, and one road down through the land.
func _draw_paths() -> void:
	var hub: Vector2 = Vector2(size.x * 0.5, _core_height * 0.5)
	var road_end: Vector2 = Vector2(size.x * 0.5, size.y)
	for width_color: Array in [[40.0, PATH_EDGE], [26.0, PATH]]:
		draw_line(hub, road_end, width_color[1], width_color[0])
		for data: BuildingData in GameData.buildings():
			if not _shown(data):
				continue
			var foot: Vector2 = _centre(data) + Vector2(0.0, FOOT_OFFSET)
			var from: Vector2 = hub if data.land == "land_core" else Vector2(size.x * 0.5, foot.y)
			draw_line(from, foot, width_color[1], width_color[0])
	VillageArt.ellipse(self, hub + Vector2(0.0, FOOT_OFFSET), Vector2(120.0, 66.0), PATH_EDGE)
	VillageArt.ellipse(self, hub + Vector2(0.0, FOOT_OFFSET), Vector2(108.0, 58.0), PATH)


func _draw_lamps() -> void:
	var max_total: int = 0
	for data: BuildingData in GameData.buildings():
		max_total += data.max_level
	@warning_ignore("integer_division")
	var lit: int = VillageLogic.total_level() * LAMP_COUNT / maxi(max_total, 1)
	if VillageLogic.total_level() > 0:
		lit = maxi(lit, 1)
	var hub: Vector2 = Vector2(size.x * 0.5, _core_height * 0.5)
	for i: int in LAMP_COUNT:
		var angle: float = TAU * float(i) / float(LAMP_COUNT) + 0.2
		var pos: Vector2 = hub + Vector2(cos(angle) * size.x * 0.4, sin(angle) * _core_height * 0.42)
		draw_line(pos, pos + Vector2(0.0, 40.0), Color("4a3a2a"), 6.0)
		if i < lit:
			draw_circle(pos, 34.0, Color(1.0, 0.7, 0.28, 0.22))
			draw_circle(pos, 13.0, UiKit.GOLD)
		else:
			draw_circle(pos, 11.0, Color("2a3350"))


## Fence and name along the top of each band; unowned land is dimmed with a sign.
func _draw_land_edge(land: LandData) -> void:
	if land.sort_order == 0:
		return
	var rect: Rect2 = land_rect(land)
	for x: float in range(0, int(size.x), 36):
		draw_line(Vector2(x, rect.position.y + 4.0), Vector2(x, rect.position.y + 26.0), FENCE, 5.0)
	draw_line(Vector2(0.0, rect.position.y + 12.0), Vector2(size.x, rect.position.y + 12.0), FENCE, 4.0)
	if LandLogic.owned(land.id):
		_text_box(Vector2(24.0, rect.position.y + 64.0), land.display_name, 30, UiKit.TEXT, false)
		return
	draw_rect(Rect2(rect.position + Vector2(0.0, 30.0), rect.size - Vector2(0.0, 30.0)), Color(0.0, 0.0, 0.0, 0.45))
	var centre: Vector2 = rect.get_center()
	var age_ok: bool = LandLogic.age_reached(land)
	_text_box(centre + Vector2(0.0, -50.0), land.display_name, 44, UiKit.GOLD, true)
	var line: String = ("For sale · %s coins" % UiKit.number(land.coin_cost)) if age_ok \
		else "Opens in the %s" % AgeLogic.age(land.required_age).display_name
	_text_box(centre + Vector2(0.0, 10.0), line, 32, UiKit.AMBER if age_ok else UiKit.MUTED, true)
	_text_box(centre + Vector2(0.0, 60.0), "Tap to see", 28, UiKit.MUTED, true)


func _text_box(pos: Vector2, text: String, font_size: int, color: Color, centred: bool) -> void:
	var text_size: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var left: float = pos.x - (text_size.x * 0.5 if centred else 0.0)
	draw_rect(Rect2(Vector2(left - 12.0, pos.y - text_size.y + 4.0), Vector2(text_size.x + 24.0, text_size.y + 8.0)), Color(0.04, 0.05, 0.1, 0.65))
	draw_string(_font, Vector2(left, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_building(data: BuildingData) -> void:
	var level: int = GameState.building_level(data.id)
	var stage: int = tier(level)
	draw_set_transform(_centre(data) + Vector2(0.0, FOOT_OFFSET), 0.0, Vector2(BUILDING_SCALE, BUILDING_SCALE))
	var top: float = 86.0
	if stage == 0:
		var plot: Rect2 = Rect2(Vector2(-80.0, -70.0), Vector2(160.0, 80.0))
		draw_rect(plot, PLOT_FILL)
		draw_rect(plot, Color(1, 1, 1, 0.35), false, 4.0)
		draw_string(_font, Vector2(-14.0, -14.0), "+", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 54, UiKit.AMBER)
	else:
		top = VillageArt.draw(self, data, stage)
	# Kept in label units, so badges sit just above the roof.
	_tops[data.id] = top * BUILDING_SCALE / LABEL_SCALE
	draw_set_transform(Vector2.ZERO)


## Name plate, build timer, "can afford" badge and stored production above every building.
func _draw_label(data: BuildingData) -> void:
	var level: int = GameState.building_level(data.id)
	var job: Dictionary = VillageLogic.job_for(data.id)
	var top: float = float(_tops.get(data.id, 86.0))
	draw_set_transform(_centre(data) + Vector2(0.0, FOOT_OFFSET), 0.0, Vector2(LABEL_SCALE, LABEL_SCALE))
	var title: String = data.display_name if level == 0 else "%s  Lv %d" % [data.display_name, level]
	var text_size: Vector2 = _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28)
	# Keep the name plate inside the view for buildings near the left or right edge.
	var half: float = (text_size.x * 0.5 + 10.0) * LABEL_SCALE
	var centre_x: float = _centre(data).x
	var shift: float = (clampf(centre_x, half + LABEL_MARGIN, size.x - half - LABEL_MARGIN) - centre_x) / LABEL_SCALE
	draw_rect(Rect2(Vector2(shift - text_size.x * 0.5 - 10.0, 10.0), Vector2(text_size.x + 20.0, 34.0)), Color(0.04, 0.05, 0.1, 0.6))
	draw_string(_font, Vector2(shift - text_size.x * 0.5, 36.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, UiKit.TEXT)
	if not job.is_empty():
		var timer: String = "⏳ " + UiKit.duration(VillageLogic.remaining(job))
		var timer_size: Vector2 = _font.get_string_size(timer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28)
		draw_string(_font, Vector2(-timer_size.x * 0.5, 72.0), timer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 28, UiKit.AMBER)
	if VillageLogic.blocker(data.id).is_empty():
		var badge: Vector2 = Vector2(58.0, -minf(top, BADGE_MAX_HEIGHT))
		draw_circle(badge, 22.0, UiKit.GOOD)
		draw_colored_polygon(PackedVector2Array([badge + Vector2(-11.0, 7.0), badge + Vector2(0.0, -12.0), badge + Vector2(11.0, 7.0)]), UiKit.DARK_TEXT)
	var stored: int = ProductionLogic.ready(data)
	if stored > 0:
		var bubble: Vector2 = Vector2(-56.0, -minf(top, BADGE_MAX_HEIGHT))
		draw_circle(bubble, 30.0, Color(0.04, 0.05, 0.1, 0.75))
		draw_texture_rect(_icon(data.produces), Rect2(bubble - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), false)
		draw_string(_font, bubble + Vector2(-30.0, 52.0), "+" + UiKit.number(stored), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 24, UiKit.GOLD)
	draw_set_transform(Vector2.ZERO)


func _icon(kind: String) -> Texture2D:
	if not _icons.has(kind):
		_icons[kind] = load(UiKit.resource_icon(kind))
	var texture: Texture2D = _icons[kind]
	return texture
