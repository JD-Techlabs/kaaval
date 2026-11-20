extends Node
## Draws the Google Play feature graphic (1024x500) and saves it as a PNG.
##   godot --path . res://tools/feature_graphic.tscn -- --out=docs/store/graphics/feature_graphic.png
## Needs a window (not --headless): it renders through a SubViewport.

const SIZE: Vector2i = Vector2i(1024, 500)
const SPRITES: String = "res://assets/sprites/"
## [sprite, centre x, baseline y, height in pixels]
const CAST: Array[Array] = [
	["e_golem", 598.0, 452.0, 120.0],
	["e_wisp", 972.0, 440.0, 84.0],
	["hero_banyan", 660.0, 458.0, 190.0],
	["hero_gale", 910.0, 458.0, 190.0],
	["hero_muthu", 786.0, 470.0, 270.0],
]

var _frames: int = 0
var _viewport: SubViewport
var _out: String = "docs/store/graphics/feature_graphic.png"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_viewport = SubViewport.new()
	_viewport.size = SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var art: Control = Control.new()
	art.size = Vector2(SIZE)
	art.theme = UiKit.theme()
	art.draw.connect(_draw_backdrop.bind(art))
	_viewport.add_child(art)
	for entry: Array in CAST:
		art.add_child(_sprite(str(entry[0]), Vector2(float(entry[1]), float(entry[2])), float(entry[3])))
	_text(art, "KAAVAL", 132, UiKit.GOLD, Vector2(56.0, 96.0))
	_text(art, "Guardians of Dawn", 52, UiKit.TEXT, Vector2(62.0, 262.0))
	_text(art, "Survive the night. See the dawn.", 30, UiKit.AMBER, Vector2(64.0, 344.0))


func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 4:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out).get_base_dir())
		var err: Error = _viewport.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://" + _out))
		print("feature graphic %s -> %s" % [_out, "ok" if err == OK else "error %d" % err])
		get_tree().quit()


func _draw_backdrop(art: Control) -> void:
	art.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), Color("0e1326"))
	art.draw_circle(Vector2(790.0, 330.0), 430.0, Color("15213f"))
	art.draw_circle(Vector2(790.0, 330.0), 300.0, Color(1.0, 0.54, 0.16, 0.16))
	art.draw_circle(Vector2(790.0, 330.0), 190.0, Color(1.0, 0.7, 0.28, 0.2))
	for x: float in [20.0, 150.0, 300.0, 440.0, 520.0, 1010.0]:
		art.draw_circle(Vector2(x, 520.0), 110.0, Color("0c312b"))
	art.draw_rect(Rect2(0.0, 462.0, float(SIZE.x), 40.0), Color("0a2622"))


## Sprite rendered straight from its SVG at the size needed, so it stays sharp.
func _sprite(sprite: String, foot: Vector2, height: float) -> TextureRect:
	var image: Image = Image.new()
	var source: String = FileAccess.get_file_as_string(SPRITES + sprite + ".svg")
	image.load_svg_from_string(source, 4.0)
	var width: float = height * float(image.get_width()) / float(image.get_height())
	image.resize(roundi(width), roundi(height), Image.INTERPOLATE_LANCZOS)
	var node: TextureRect = TextureRect.new()
	node.texture = ImageTexture.create_from_image(image)
	node.position = foot - Vector2(width * 0.5, height)
	return node


func _text(art: Control, text: String, size: int, color: Color, at: Vector2) -> void:
	var node: Label = UiKit.label(text, size, color)
	node.add_theme_color_override("font_outline_color", Color("0e1326"))
	node.add_theme_constant_override("outline_size", 12)
	node.position = at
	art.add_child(node)
