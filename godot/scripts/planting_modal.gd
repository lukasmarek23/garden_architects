class_name PlantingModal
extends Control
## Full-screen overlay: bed (drop target) + draggable pool + Done.

signal finished

var _bed_view: PlantBedView
var _pool_box: VBoxContainer
var _slots: Array[PlantPoolSlot] = []
var _title: Label

var _deck: PlantDeck
var _try_place: Callable = Callable()
var _base_seeds_getter: Callable = Callable()


func _ready() -> void:
	## Root is a direct child of `CanvasLayer` — must fill the viewport or children with
	## `PRESET_FULL_RECT` get zero size and the dim never covers the game.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 520)
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.18, 0.18, 0.2, 1.0)
	panel_bg.set_corner_radius_all(8)
	panel.add_theme_stylebox_override(&"panel", panel_bg)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 10)
	margin.add_child(root_v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_v.add_child(_title)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	root_v.add_child(hb)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	var bed_lbl := Label.new()
	bed_lbl.text = "Your bed (drop here)"
	left.add_child(bed_lbl)
	_bed_view = PlantBedView.new()
	_bed_view.cell_size = 48
	_bed_view.grid_line_color = Color(1, 1, 1, 1)
	left.add_child(_bed_view)
	hb.add_child(left)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	var pool_lbl := Label.new()
	pool_lbl.text = "Plant pool (drag onto bed)"
	right.add_child(pool_lbl)
	_pool_box = VBoxContainer.new()
	_pool_box.add_theme_constant_override("separation", 6)
	right.add_child(_pool_box)
	hb.add_child(right)

	var done := Button.new()
	done.text = "Done"
	done.pressed.connect(_on_done_pressed)
	root_v.add_child(done)

	_bed_view.drop_requested.connect(_on_bed_drop_requested)


func open(
	player: BoardData.Player,
	bed: PlantBed,
	deck: PlantDeck,
	try_place: Callable,
	base_seeds_getter: Callable
) -> void:
	_deck = deck
	_try_place = try_place
	_base_seeds_getter = base_seeds_getter
	var n := 1 if player == BoardData.Player.P1 else 2
	_title.text = "Planting — Player %d" % n
	_bed_view.bed = bed
	_bed_view.interactive = true
	_bed_view.cell_size = 48
	_bed_view.refresh()
	_rebuild_pool_slots()
	visible = true
	move_to_front()


func _rebuild_pool_slots() -> void:
	for c in _pool_box.get_children():
		c.queue_free()
	_slots.clear()
	for pid in PlantCatalog.deck_plant_ids():
		var slot := PlantPoolSlot.new()
		slot.plant_id = str(pid)
		slot.deck = _deck
		slot.base_seeds_getter = _base_seeds_getter
		_pool_box.add_child(slot)
		_slots.append(slot)


func _on_bed_drop_requested(plant_id: String, col: int, row: int) -> void:
	if not _try_place.is_valid():
		return
	var ok: Variant = _try_place.call(plant_id, col, row)
	if bool(ok):
		_bed_view.refresh()
		for s in _slots:
			s.refresh_visual()


func _on_done_pressed() -> void:
	visible = false
	_bed_view.interactive = false
	finished.emit()
