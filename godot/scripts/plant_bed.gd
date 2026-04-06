class_name PlantBed
extends RefCounted
## 5×4 personal bed: polyomino placements, per-plant watering toward bloom / VP.

const COLS := 5
const ROWS := 4

var _occupancy: PackedInt32Array = PackedInt32Array()
## Each: plant_id, anchor_col, anchor_row, water_applied (int).
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
	_placements.append(
		{
			"plant_id": plant_id,
			"anchor_col": anchor_col,
			"anchor_row": anchor_row,
			"rotation": rotation,
			"water_applied": 0,
		}
	)
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
	var o := occupancy_at(col, row)
	return o


func water_applied_for_placement(placement_idx: int) -> int:
	if placement_idx < 0 or placement_idx >= _placements.size():
		return 0
	return int(_placements[placement_idx].get("water_applied", 0))


func is_placement_mature(placement_idx: int) -> bool:
	if placement_idx < 0 or placement_idx >= _placements.size():
		return false
	var pl: Dictionary = _placements[placement_idx]
	var pid: String = str(pl.get("plant_id", ""))
	var def := PlantCatalog.get_definition(pid)
	if def == null:
		return false
	return int(pl.get("water_applied", 0)) >= def.water_to_mature


## Add water to the plant covering `col`,`row` (e.g. after delivering water at base). Clamped to mature cap.
func apply_water_at_cell(col: int, row: int, droplets: int) -> void:
	if droplets <= 0:
		return
	var pidx := occupancy_at(col, row)
	if pidx < 0:
		return
	if is_placement_mature(pidx):
		return
	var pl: Dictionary = _placements[pidx]
	var pid: String = str(pl.get("plant_id", ""))
	var def := PlantCatalog.get_definition(pid)
	if def == null:
		return
	var w: int = int(pl.get("water_applied", 0))
	var cap: int = def.water_to_mature
	pl["water_applied"] = mini(cap, w + droplets)


func total_bloomed_vp() -> int:
	var t := 0
	for i in _placements.size():
		if not is_placement_mature(i):
			continue
		var pid: String = str(_placements[i].get("plant_id", ""))
		var def := PlantCatalog.get_definition(pid)
		if def != null:
			t += def.victory_points
	return t


func format_compact() -> String:
	if _placements.is_empty():
		return "(empty)"
	var parts: PackedStringArray = []
	for i in _placements.size():
		var pl: Dictionary = _placements[i]
		var pid: String = str(pl.get("plant_id", ""))
		var def := PlantCatalog.get_definition(pid)
		var label := def.display_name if def != null else pid
		var w := int(pl.get("water_applied", 0))
		var need := def.water_to_mature if def != null else w
		parts.append("%s %d/%d" % [label, w, need])
	return " | ".join(parts)
