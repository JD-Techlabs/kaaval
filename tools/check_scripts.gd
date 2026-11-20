extends SceneTree
## Compiles every project script and loads every data resource; exits 1 on any failure.
## Run: godot --headless --path . -s tools/check_scripts.gd

const ROOTS: Array[String] = ["res://autoload", "res://scripts", "res://data", "res://scenes", "res://tests"]


func _process(_delta: float) -> bool:
	var failures: int = 0
	var checked: int = 0
	for root_dir: String in ROOTS:
		for path: String in _walk(root_dir):
			if not (path.ends_with(".gd") or path.ends_with(".tres") or path.ends_with(".tscn")):
				continue
			checked += 1
			var res: Resource = load(path)
			var ok: bool = res != null
			if ok and res is GDScript:
				ok = (res as GDScript).can_instantiate()
			if not ok:
				failures += 1
				printerr("FAILED: ", path)
	print("checked %d files, %d failed" % [checked, failures])
	quit(1 if failures > 0 else 0)
	return true


func _walk(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub: String in dir.get_directories():
		out.append_array(_walk(dir_path.path_join(sub)))
	for file: String in dir.get_files():
		out.append(dir_path.path_join(file))
	return out
