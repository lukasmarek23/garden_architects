class_name PlantingModal
extends Control
## Full-screen overlay for planting.
##
## Phase 0 — Pool:  Up/Down select plant · Enter → go to bed · Escape → close modal.
## Phase 1 — Bed:   Arrows move cursor   · R rotate        · Enter place · Escape → back to pool.

signal finished

const PHASE_POOL := 0
const PHASE_BED  := 1

var _phase: int = PHASE_POOL
var _pool_idx: int = 0
var _cursor_col: int = 0
var _cursor_row: int = 0
var _rotation: int = 0
var _pending_plant_id: String = ""

var _bed_view: PlantBedView
var _pool_slots: Array = []          # Array[PlantPoolSlot]
var _pool_scroll: ScrollContainer
var _pool_box: VBoxContainer
var _title: Label
var _hint: Label

var _deck: PlantDeck
var _try_place: Callable = Callable()
var _base_seeds_getter: Callable = Callable()
var _base_water_getter: Callable = Callable()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0; offset_top = 0.0
	offset_right = 0.0; offset_bottom = 0.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical   = Control.GROW_DIRECTION_BOTH

	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 560)
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.18, 0.18, 0.2, 1.0)
	panel_bg.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_bg)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var root_v := VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 8)
	margin.add_child(root_v)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_v.add_child(_title)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75, 1.0))
	root_v.add_child(_hint)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 24)
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(hb)

	# --- Left: bed ---
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	var bed_lbl := Label.new()
	bed_lbl.text = "Your bed"
	left.add_child(bed_lbl)
	_bed_view = PlantBedView.new()
	_bed_view.cell_size = 52
	_bed_view.grid_line_color = Color(1, 1, 1, 1)
	_bed_view.custom_minimum_size = Vector2(PlantBed.COLS * 52, PlantBed.ROWS * 52)
	left.add_child(_bed_view)
	hb.add_child(left)

	# --- Right: pool ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pool_lbl := Label.new()
	pool_lbl.text = "Plant pool"
	right.add_child(pool_lbl)
	_pool_scroll = ScrollContainer.new()
	_pool_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_pool_scroll)
	_pool_box = VBoxContainer.new()
	_pool_box.add_theme_constant_override("separation", 6)
	_pool_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pool_scroll.add_child(_pool_box)
	hb.add_child(right)

	var done := Button.new()
	done.text = "Done (close)"
	done.pressed.connect(_close_modal)
	root_v.add_child(done)

	_bed_view.drop_requested.connect(_on_bed_drop_requested)


func open(
	player: BoardData.Player,
	bed: PlantBed,
	deck: PlantDeck,
	try_place: Callable,
	base_seeds_getter: Callable,
	base_water_getter: Callable
) -> void:
	_deck = deck
	_try_place = try_place
	_base_seeds_getter = base_seeds_getter
	_base_water_getter = base_water_getter
	var n := 1 if player == BoardData.Player.P1 else 2
	_title.text = "Planting — Player %d" % n
	_bed_view.bed = bed
	_bed_view.interactive = true
	_bed_view.cell_size = 52
	_bed_view.refresh()
	_rebuild_pool_slots()
	_phase = PHASE_POOL
	_pool_idx = 0
	_cursor_col = 0
	_cursor_row = 0
	_rotation = 0
	_pending_plant_id = ""
	_bed_view.clear_ghost()
	_refresh_pool_highlight()
	_update_hint()
	visible = true
	move_to_front()
	set_process_input(true)


func _rebuild_pool_slots() -> void:
	for c in _pool_box.get_children():
		c.queue_free()
	_pool_slots.clear()
	for pid in PlantCatalog.deck_plant_ids():
		var slot := PlantPoolSlot.new()
		slot.plant_id = str(pid)
		slot.deck = _deck
		slot.base_seeds_getter = _base_seeds_getter
		slot.base_water_getter = _base_water_getter
		_pool_box.add_child(slot)
		_pool_slots.append(slot)


func _refresh_pool_highlight() -> void:
	for i in _pool_slots.size():
		var slot: PlantPoolSlot = _pool_slots[i]
		var on := (_phase == PHASE_POOL and i == _pool_idx)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.28, 0.46, 0.28, 0.85) if on else Color(0.12, 0.12, 0.14, 0.5)
		sb.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", sb)
		slot.refresh_visual()


func _update_hint() -> void:
	if _phase == PHASE_POOL:
		_hint.text = "↑↓ select · Enter pick up · Escape close"
	else:
		_hint.text = (
			"Arrows move · R rotate (%d°) · Enter place · Escape back to pool" % (_rotation * 90)
		)


func _update_ghost() -> void:
	if _phase == PHASE_BED and not _pending_plant_id.is_empty():
		_bed_view.set_ghost(_pending_plant_id, _cursor_col, _cursor_row, _rotation)
	else:
		_bed_view.clear_ghost()


func _close_modal() -> void:
	visible = false
	set_process_input(false)
	_bed_view.clear_ghost()
	_bed_view.interactive = false
	finished.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not event is InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return

	match _phase:
		PHASE_POOL:
			_handle_pool_input(ek.physical_keycode)
		PHASE_BED:
			_handle_bed_input(ek.physical_keycode)

	get_viewport().set_input_as_handled()


func _handle_pool_input(key: int) -> void:
	match key:
		KEY_UP:
			_pool_idx = posmod(_pool_idx - 1, _pool_slots.size())
			_refresh_pool_highlight()
			_update_hint()
		KEY_DOWN:
			_pool_idx = posmod(_pool_idx + 1, _pool_slots.size())
			_refresh_pool_highlight()
			_update_hint()
		KEY_ENTER, KEY_KP_ENTER:
			_try_enter_bed_phase()
		KEY_ESCAPE:
			_close_modal()


func _try_enter_bed_phase() -> void:
	if _pool_slots.is_empty():
		return
	var slot: PlantPoolSlot = _pool_slots[_pool_idx]
	var pid := slot.plant_id
	if _deck.remaining(pid) <= 0:
		return
	var def := PlantCatalog.get_definition(pid)
	if def == null:
		return
	var seeds := 0
	var water := 0
	if _base_seeds_getter.is_valid():
		seeds = int(_base_seeds_getter.call())
	if _base_water_getter.is_valid():
		water = int(_base_water_getter.call())
	if seeds < def.seeds_to_plant or water < def.water_to_mature:
		return
	_pending_plant_id = pid
	_phase = PHASE_BED
	_rotation = 0
	_cursor_col = 0
	_cursor_row = 0
	_refresh_pool_highlight()
	_update_ghost()
	_update_hint()


func _handle_bed_input(key: int) -> void:
	match key:
		KEY_UP:
			_cursor_row = posmod(_cursor_row - 1, PlantBed.ROWS)
			_update_ghost()
			_update_hint()
		KEY_DOWN:
			_cursor_row = posmod(_cursor_row + 1, PlantBed.ROWS)
			_update_ghost()
			_update_hint()
		KEY_LEFT:
			_cursor_col = posmod(_cursor_col - 1, PlantBed.COLS)
			_update_ghost()
			_update_hint()
		KEY_RIGHT:
			_cursor_col = posmod(_cursor_col + 1, PlantBed.COLS)
			_update_ghost()
			_update_hint()
		KEY_R:
			_rotation = (_rotation + 1) % 4
			_update_ghost()
			_update_hint()
		KEY_ENTER, KEY_KP_ENTER:
			_try_place_current()
		KEY_ESCAPE:
			_phase = PHASE_POOL
			_pending_plant_id = ""
			_bed_view.clear_ghost()
			_refresh_pool_highlight()
			_update_hint()


func _try_place_current() -> void:
	if _pending_plant_id.is_empty() or not _try_place.is_valid():
		return
	var ok: bool = _try_place.call(_pending_plant_id, _cursor_col, _cursor_row, _rotation)
	if ok:
		_bed_view.refresh()
		_pending_plant_id = ""
		_phase = PHASE_POOL
		_rotation = 0
		_bed_view.clear_ghost()
		_rebuild_pool_slots()
		_refresh_pool_highlight()
		_update_hint()


# ── drag-and-drop fallback ─────────────────────────────────────────────────────

func _on_bed_drop_requested(plant_id: String, col: int, row: int) -> void:
	if not _try_place.is_valid():
		return
	var ok: bool = _try_place.call(plant_id, col, row, 0)
	if ok:
		_bed_view.refresh()
		_rebuild_pool_slots()
		_refresh_pool_highlight()
		_update_hint()
