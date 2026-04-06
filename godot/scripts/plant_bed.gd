class_name PlantBed
extends RefCounted
## 5×4 personal bed: tracks polyomino placements and their victory points.

const COLS := 5
const ROWS := 4

var _occupancy: PackedInt32Array = PackedInt32Array()
## Each entry: plant_id, anchor_col, anchor_row, rotation.
var _placements: Array = []


func _init() -> void:
	_occupancy.resize(COLS * ROWS)
	for i in _occupancy.size():
		_occupancy[i] = -1


func cell_index(col: int, row: int) -> int:
	return row * COLS + col


func _in_bounds(col: int, row: int) -> bool:
	return col >= 0 and col < COLS and row >= 0 and row < ROWS


func occupancy_at(col: int, row: int) -> int:
	if not _in_bounds(col, row):
		return -2
	return _occupancy[cell_index(col, row)]


## Absolute cells (col, row) covered if anchored at `anchor_col`, `anchor_row` with `rotation` (0–3 CW).
func footprint_cells(plant_id: String, anchor_col: int, anchor_row: int, rotation: int = 0) -> Array[Vector2i]:
	var def := PlantCatalog.get_definition(plant_id)
	var out: Array[Vector2i] = []
	if def == null:
		return out
	var offsets := PlantDefinition.rotate_shape(def.shape_offsets, rotation)
	for off in offsets:
		out.append(Vector2i(anchor_col + off.x, anchor_row + off.y))
	return out


func can_place(plant_id: String, anchor_col: int, anchor_row: int, rotation: int = 0) -> bool:
	var def := PlantCatalog.get_definition(plant_id)
	if def == null:
		return false
	for cell in footprint_cells(plant_id, anchor_col, anchor_row, rotation):
		if not _in_bounds(cell.x, cell.y):
			return false
		if _occupancy[cell_index(cell.x, cell.y)] >= 0:
			return false
	return true


func commit_place(plant_id: String, anchor_col: int, anchor_row: int, rotation: int = 0) -> bool:
	if not can_place(plant_id, anchor_col, anchor_row, rotation):
		return false
	var idx := _placements.size()
	_placements.append({
		"plant_id": plant_id,
		"anchor_col": anchor_col,
		"anchor_row": anchor_row,
		"rotation": rotation,
	})
	for cell in footprint_cells(plant_id, anchor_col, anchor_row, rotation):
		_occupancy[cell_index(cell.x, cell.y)] = idx
	return true


func placement_count() -> int:
	return _placements.size()


func get_placement(i: int) -> Dictionary:
	if i < 0 or i >= _placements.size():
		return {}
	return _placements[i]


func placement_index_at_cell(col: int, row: int) -> int:
	return occupancy_at(col, row)


## Sum of victory_points for every plant currently placed in this bed.
func total_vp() -> int:
	var t := 0
	for pl in _placements:
		var pid: String = str(pl.get("plant_id", ""))
		var def := PlantCatalog.get_definition(pid)
		if def != null:
			t += def.victory_points
	return t


func format_compact() -> String:
	if _placements.is_empty():
		return "(empty)"
	var parts: PackedStringArray = []
	for pl in _placements:
		var pid: String = str(pl.get("plant_id", ""))
		var def := PlantCatalog.get_definition(pid)
		var label := def.display_name if def != null else pid
		parts.append(label)
	return " | ".join(parts)
