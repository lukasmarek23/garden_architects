class_name PlantBedView
extends Control
## Renders a `PlantBed` as a 5×4 grid; optional drag-and-drop target when `interactive`.
## Grid cells **scale to fill** the control’s rectangle (resize in the editor or at runtime).

signal drop_requested(plant_id: String, col: int, row: int)

@export var cell_size: int = 44
@export var grid_line_color: Color = Color(0.12, 0.14, 0.1, 0.35)
@export var grid_line_width: float = 2.0
var bed: PlantBed
var interactive: bool = false:
	set(v):
		interactive = v
		mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE

var _plants_layer: Control
## Ghost preview state (set by PlantingModal during bed-phase keyboard nav).
var ghost_plant_id: String = ""
var ghost_rotation: int = 0
var ghost_col: int = 0
var ghost_row: int = 0
var ghost_active: bool = false:
	set(v):
		ghost_active = v
		queue_redraw()


func set_ghost(plant_id: String, col: int, row: int, rotation: int) -> void:
	ghost_plant_id = plant_id
	ghost_col = col
	ghost_row = row
	ghost_rotation = rotation
	ghost_active = true
	queue_redraw()


func clear_ghost() -> void:
	ghost_active = false
	queue_redraw()


func _ready() -> void:
	if custom_minimum_size.x < 1.0 and custom_minimum_size.y < 1.0:
		custom_minimum_size = Vector2(
			float(PlantBed.COLS * cell_size),
			float(PlantBed.ROWS * cell_size)
		)
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	_plants_layer = Control.new()
	_plants_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_plants_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plants_layer)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		if is_node_ready() and _plants_layer != null:
			refresh()


func _grid_cell_px() -> float:
	var w := size.x / float(PlantBed.COLS)
	var h := size.y / float(PlantBed.ROWS)
	if w < 1.0 or h < 1.0:
		return float(cell_size)
	return mini(w, h)


## Keep VBox/HBox layout stable: do not let large textures inflate this control’s minimum size.
func _get_minimum_size() -> Vector2:
	if custom_minimum_size.x > 0.0 and custom_minimum_size.y > 0.0:
		return custom_minimum_size
	return Vector2(float(PlantBed.COLS * cell_size), float(PlantBed.ROWS * cell_size))


func _draw() -> void:
	var sz := _grid_cell_px()
	for c in PlantBed.COLS:
		for r in PlantBed.ROWS:
			var rect := Rect2(Vector2(c * sz, r * sz), Vector2(sz, sz))
			draw_rect(rect, grid_line_color, false, grid_line_width)
	if ghost_active and not ghost_plant_id.is_empty() and bed != null:
		var cells := bed.footprint_cells(ghost_plant_id, ghost_col, ghost_row, ghost_rotation)
		var valid := bed.can_place(ghost_plant_id, ghost_col, ghost_row, ghost_rotation)
		var fill := Color(0.2, 0.9, 0.3, 0.45) if valid else Color(0.9, 0.2, 0.2, 0.45)
		var border := Color(0.2, 0.9, 0.3, 0.9) if valid else Color(0.9, 0.2, 0.2, 0.9)
		for cell in cells:
			if cell.x < 0 or cell.y < 0 or cell.x >= PlantBed.COLS or cell.y >= PlantBed.ROWS:
				continue
			var r2 := Rect2(Vector2(cell.x * sz, cell.y * sz), Vector2(sz, sz))
			draw_rect(r2, fill, true)
			draw_rect(r2, border, false, 2.5)


func refresh() -> void:
	if _plants_layer == null:
		return
	for c in _plants_layer.get_children():
		c.queue_free()
	if bed == null:
		return
	var g := _grid_cell_px()
	var n := bed.placement_count()
	for i in n:
		var pl: Dictionary = bed.get_placement(i)
		var pid: String = str(pl.get("plant_id", ""))
		var ac := int(pl.get("anchor_col", 0))
		var ar := int(pl.get("anchor_row", 0))
		var rot := int(pl.get("rotation", 0))
		var cells := bed.footprint_cells(pid, ac, ar, rot)
		if cells.is_empty():
			continue
		var min_c := 99
		var min_r := 99
		var max_c := -1
		var max_r := -1
		for cell in cells:
			min_c = mini(min_c, cell.x)
			min_r = mini(min_r, cell.y)
			max_c = maxi(max_c, cell.x)
			max_r = maxi(max_r, cell.y)
		var def := PlantCatalog.get_definition(pid)
		var w := float(max_c - min_c + 1) * g
		var h := float(max_r - min_r + 1) * g
		var node: Control
		if def != null and def.icon != null:
			var tr := TextureRect.new()
			tr.texture = def.icon
			tr.ignore_texture_size = true
			tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			node = tr
		else:
			var cr := ColorRect.new()
			cr.color = _fallback_color(pid)
			node = cr
		node.position = Vector2(float(min_c) * g, float(min_r) * g)
		node.custom_minimum_size = Vector2(w, h)
		node.size = Vector2(w, h)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_plants_layer.add_child(node)


func _fallback_color(plant_id: String) -> Color:
	match plant_id:
		"onion":
			return Color(0.55, 0.38, 0.22, 0.92)
		"rose":
			return Color(0.78, 0.35, 0.52, 0.92)
		_:
			return Color(0.4, 0.45, 0.42, 0.88)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not interactive:
		return false
	if data is Dictionary:
		var d := data as Dictionary
		return str(d.get("type", "")) == "plant"
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not (data is Dictionary):
		return
	var d := data as Dictionary
	var pid: String = str(d.get("plant_id", ""))
	var g := _grid_cell_px()
	var col := int(at_position.x / g)
	var row := int(at_position.y / g)
	if col < 0 or row < 0 or col >= PlantBed.COLS or row >= PlantBed.ROWS:
		return
	drop_requested.emit(pid, col, row)
