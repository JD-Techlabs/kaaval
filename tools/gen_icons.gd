extends SceneTree
## Renders the launcher icon PNGs and the 512 px store icon from the SVG art.
##   godot --headless --path . -s tools/gen_icons.gd
## Run tools/gen_art.py first; the export presets point at the files in assets/icons.

const BG: String = "res://assets/sprites/icon_bg.svg"
const FG: String = "res://assets/sprites/icon_fg.svg"
## The adaptive layers keep the hero inside Android's safe zone; a flat icon
## shows this central share of the canvas so the hero fills it.
const FLAT_CROP: float = 0.74
const RENDER_SCALE: float = 4.0
## [layers bottom to top, output file, pixel size, crop to the centre]
const ICONS: Array[Array] = [
	[[FG], "res://assets/icons/adaptive_fg_432.png", 432, false],
	[[BG], "res://assets/icons/adaptive_bg_432.png", 432, false],
	[[BG, FG], "res://assets/icons/icon_192.png", 192, true],
	[[BG, FG], "res://docs/store/graphics/icon_512.png", 512, true],
]


func _process(_delta: float) -> bool:
	for entry: Array in ICONS:
		var output: String = entry[1]
		var size: int = entry[2]
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		var canvas: Image = null
		for layer: String in entry[0]:
			var image: Image = Image.new()
			image.load_svg_from_string(FileAccess.get_file_as_string(layer), RENDER_SCALE)
			image.convert(Image.FORMAT_RGBA8)
			if canvas == null:
				canvas = image
			else:
				canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
		if bool(entry[3]):
			var full: int = canvas.get_width()
			var keep: int = roundi(full * FLAT_CROP)
			@warning_ignore("integer_division")
			canvas = canvas.get_region(Rect2i((full - keep) / 2, (full - keep) / 2, keep, keep))
		canvas.resize(size, size, Image.INTERPOLATE_LANCZOS)
		var err: Error = canvas.save_png(output)
		print("%s -> %s" % [output, "ok" if err == OK else "error %d" % err])
	return true
