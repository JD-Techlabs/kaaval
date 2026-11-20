class_name SpatialGrid
extends RefCounted
## Uniform grid over the bounded map. Rebuilt every frame; cells are reused so
## the per-frame rebuild allocates nothing.

var cell_size: float
var cols: int
var rows: int
var _cells: Array[Array] = []
var _used: PackedInt32Array = PackedInt32Array()


func _init(world_size: Vector2, p_cell_size: float) -> void:
	cell_size = p_cell_size
	cols = ceili(world_size.x / cell_size) + 1
	rows = ceili(world_size.y / cell_size) + 1
	_cells.resize(cols * rows)
	for i: int in _cells.size():
		_cells[i] = []


func clear() -> void:
	for index: int in _used:
		_cells[index].clear()
	_used.clear()


func cell_index(pos: Vector2) -> int:
	var cx: int = clampi(int(pos.x / cell_size), 0, cols - 1)
	var cy: int = clampi(int(pos.y / cell_size), 0, rows - 1)
	return cy * cols + cx


func insert(item: Variant, pos: Vector2) -> void:
	var index: int = cell_index(pos)
	var cell: Array = _cells[index]
	if cell.is_empty():
		_used.append(index)
	cell.append(item)


func cell_items(pos: Vector2) -> Array:
	return _cells[cell_index(pos)]


## Appends every item whose cell touches the circle's bounding box.
## Callers do the exact distance test.
func query(center: Vector2, radius: float, out: Array) -> void:
	var x0: int = clampi(int((center.x - radius) / cell_size), 0, cols - 1)
	var x1: int = clampi(int((center.x + radius) / cell_size), 0, cols - 1)
	var y0: int = clampi(int((center.y - radius) / cell_size), 0, rows - 1)
	var y1: int = clampi(int((center.y + radius) / cell_size), 0, rows - 1)
	for cy: int in range(y0, y1 + 1):
		var row: int = cy * cols
		for cx: int in range(x0, x1 + 1):
			var cell: Array = _cells[row + cx]
			if not cell.is_empty():
				out.append_array(cell)
