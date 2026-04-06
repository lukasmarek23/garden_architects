extends Node2D

const CARRY_SEED := 0
const CARRY_WATER := 1

## Layout convention: prefer placing and parenting nodes in the viewport; use scripts for
## rules and animation. `BoardLayout` + `apply_layout_positions_to_pawns` are for grid math
## when you need programmatic cells (highlights, clicks), not for overriding hand-tuned poses.

@export var origin_b1_top_left: Vector2 = Vector2(682, 1138)
@export var cell_px: Vector2 = Vector2(128, 128)
## false (default for `board3`): row **1** = top of image, row **5** = bottom (**A5/G5** bases).
## true: flipped — row **5** at top, row **1** at bottom. Toggle if highlights still look upside-down.
@export var row_1_at_bottom: bool = false
## Add to every cell in **sprite local space** (same units as texture pixels; +Y = down).
@export var cell_position_nudge: Vector2 = Vector2.ZERO
## When true (default): **`origin_b1_top_left` and `cell_px` are recomputed** from the
## **scene positions** of PawnP1 / PawnP2 (assumed **A5** and **G5**, same row, P2 to the right).
## Fixes highlights / moves vs hand-placed pawns. Set false to use the exports only.
@export var derive_grid_from_starting_pawns: bool = true
## With pawn derivation, use one number for both axes (`cell_px = Vector2(w, w)`).
@export var calibration_square_cells: bool = true
## When false (default), pawn **position** from the saved scene is kept at startup.
@export var apply_layout_positions_to_pawns: bool = false
## Max distance (Board3 local units) from a highlight center to count as “clicked”.
@export var highlight_pick_radius: float = 36.0
## Seconds between each “Rock / Paper / Scissors / Shoot!” step during a bump.
@export var bump_countdown_step_sec: float = 0.9
## Global supply still at seed box / well (decremented on pickup). Game ends when every seed
## and every droplet has been delivered to bases (see `_deposit_hand_to_base`).
@export var starting_seed_pool: int = 20
@export var starting_water_pool: int = 20
@onready var _board: Sprite2D = $Board3
@onready var _highlights_root: Node2D = $Board3/MoveHighlights
@onready var _pawn_p1: PawnMarker = $Board3/PawnP1
@onready var _pawn_p2: PawnMarker = $Board3/PawnP2
@onready var _turn_label: Label = $CanvasLayer/TurnLabel
@onready var _end_turn_button: Button = $CanvasLayer/EndTurnButton
@onready var _resources_label: Label = $CanvasLayer/ResourcesLabel
@onready var _canvas_layer: CanvasLayer = $CanvasLayer
@onready var _hud_bed_p1: PlantBedView = $CanvasLayer/P1BedGroup/PlantBedP1
@onready var _hud_bed_p2: PlantBedView = $CanvasLayer/P2BedGroup/PlantBedP2
@onready var _bump_layer: CanvasLayer = $BumpLayer
@onready var _bump_main_label: Label = $BumpLayer/OverlayRoot/MainLabel
@onready var _bump_hint_label: Label = $BumpLayer/OverlayRoot/HintLabel

var _active: BoardData.Player = BoardData.Player.P1
var _cell_p1: String = BoardData.BASE_P1
var _cell_p2: String = BoardData.BASE_P2
## Legal destinations this turn (order matches highlight children). Arrow keys pick by **screen direction**.
var _legal_order: Array[String] = []
var _kb_highlight_index: int = 0
## Pawn **Board3 local** positions at **game start** (hand-tuned bases); loser snaps back here.
var _home_local_p1: Vector2
var _home_local_p2: Vector2
## Bump / Rock–Paper–Scissors overlay (same cell after a move).
var _bump_active: bool = false
var _bump_waiting_keys: bool = false
var _bump_p1_pick: int = -1
var _bump_p2_pick: int = -1
## Carried resources (normally 0–1 item; bump can push more onto the winner). Values: CARRY_*.
var _hand_p1: Array = []
var _hand_p2: Array = []
var _base_seeds_p1: int = 0
var _base_water_p1: int = 0
var _base_seeds_p2: int = 0
var _base_water_p2: int = 0
var _seed_pool_remaining: int = 0
var _water_pool_remaining: int = 0
var _game_over: bool = false
var _bed_p1: PlantBed
var _bed_p2: PlantBed
var _deck_p1: PlantDeck
var _deck_p2: PlantDeck
var _plant_ui_layer: CanvasLayer
var _planting_modal: PlantingModal
var _deposited_this_move: bool = false
var _planting_flow_active: bool = false


func _ready() -> void:
	print("The Garden Architects — Godot project loaded.")
	if derive_grid_from_starting_pawns:
		_apply_layout_calibration_from_pawns()
	BoardLayout.origin_b1_top_left = origin_b1_top_left
	BoardLayout.cell_px = cell_px
	BoardLayout.row_1_at_bottom = row_1_at_bottom

	if apply_layout_positions_to_pawns:
		var tex_size_ap := _board.texture.get_size()
		var n_ap := cell_position_nudge
		_pawn_p1.position = BoardLayout.cell_center_local(BoardData.BASE_P1, tex_size_ap) + n_ap
		_pawn_p2.position = BoardLayout.cell_center_local(BoardData.BASE_P2, tex_size_ap) + n_ap

	_end_turn_button.pressed.connect(_on_end_turn_pressed)
	_home_local_p1 = _pawn_p1.position
	_home_local_p2 = _pawn_p2.position
	_seed_pool_remaining = starting_seed_pool
	_water_pool_remaining = starting_water_pool
	_bed_p1 = PlantBed.new()
	_bed_p2 = PlantBed.new()
	_deck_p1 = PlantDeck.new()
	_deck_p2 = PlantDeck.new()
	_plant_ui_layer = CanvasLayer.new()
	_plant_ui_layer.layer = 15
	add_child(_plant_ui_layer)
	_planting_modal = PlantingModal.new()
	_planting_modal.finished.connect(_on_planting_modal_finished)
	_plant_ui_layer.add_child(_planting_modal)
	_hud_bed_p1.bed = _bed_p1
	_hud_bed_p1.interactive = false
	_hud_bed_p2.bed = _bed_p2
	_hud_bed_p2.interactive = false
	_refresh_plant_hud()
	_update_turn_label()
	_update_resource_readout()
	_refresh_move_highlights()


func _apply_layout_calibration_from_pawns() -> void:
	var tex := _board.texture.get_size()
	var p1 := _pawn_p1.position
	var p2 := _pawn_p2.position
	var dx := p2.x - p1.x
	if dx <= 1.0:
		push_warning(
			"Board calibration: PawnP2 should be to the right of PawnP1 (A5→G5). Using exported layout."
		)
		return
	var w := dx / 6.0
	var h := w if calibration_square_cells else cell_px.y
	cell_px = Vector2(w, h)
	var half_tex := tex * 0.5
	if row_1_at_bottom:
		origin_b1_top_left = Vector2(
			p1.x + half_tex.x + w * 0.5,
			p1.y + half_tex.y + 3.5 * h
		)
	else:
		origin_b1_top_left = Vector2(
			p1.x + half_tex.x + w * 0.5,
			p1.y + half_tex.y - 4.5 * h
		)
	var dy := absf(p2.y - p1.y)
	if dy > absf(w) * 0.08:
		push_warning(
			"Board calibration: P1/P2 Y differs by %.1f px — bases may not share row 5; try toggling `row_1_at_bottom`."
			% dy
		)


func _input(event: InputEvent) -> void:
	if _game_over:
		return
	if not _bump_waiting_keys:
		return
	if not event is InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return
	var c := ek.physical_keycode
	if _bump_p1_pick < 0:
		if c == KEY_A:
			_bump_p1_pick = 0
		elif c == KEY_S:
			_bump_p1_pick = 1
		elif c == KEY_D:
			_bump_p1_pick = 2
	if _bump_p2_pick < 0:
		if c == KEY_J:
			_bump_p2_pick = 0
		elif c == KEY_K:
			_bump_p2_pick = 1
		elif c == KEY_L:
			_bump_p2_pick = 2


func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if _planting_flow_active:
		return
	if _bump_active:
		return
	if event is InputEventKey:
		var ek := event as InputEventKey
		if not ek.pressed or ek.echo:
			return
		if _legal_order.size() > 0:
			var k := ek.physical_keycode
			if k == KEY_UP or k == KEY_DOWN or k == KEY_LEFT or k == KEY_RIGHT:
				var dir: Vector2
				if k == KEY_UP:
					dir = Vector2.UP
				elif k == KEY_DOWN:
					dir = Vector2.DOWN
				elif k == KEY_LEFT:
					dir = Vector2.LEFT
				else:
					dir = Vector2.RIGHT
				var idx := _index_of_best_legal_in_direction(dir)
				if idx >= 0:
					_kb_highlight_index = idx
					_update_keyboard_highlight_style()
				get_viewport().set_input_as_handled()
				return
			if k == KEY_ENTER or k == KEY_KP_ENTER:
				_apply_move(_legal_order[_kb_highlight_index])
				get_viewport().set_input_as_handled()
				return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		var local := _board.to_local(get_global_mouse_position())
		var hi := 0
		for child in _highlights_root.get_children():
			if not child is Node2D:
				continue
			if not child.has_meta(&"cell_id"):
				continue
			if local.distance_to((child as Node2D).position) <= highlight_pick_radius:
				_kb_highlight_index = hi
				_apply_move(str(child.get_meta(&"cell_id")))
				get_viewport().set_input_as_handled()
				return
			hi += 1


func _on_end_turn_pressed() -> void:
	if _game_over:
		return
	if _planting_flow_active:
		return
	if _bump_active:
		return
	_end_active_turn_and_switch()


func _end_active_turn_and_switch() -> void:
	_active = BoardData.Player.P2 if _active == BoardData.Player.P1 else BoardData.Player.P1
	_update_turn_label()
	_update_resource_readout()
	_refresh_move_highlights()


func _current_cell() -> String:
	return _cell_p1 if _active == BoardData.Player.P1 else _cell_p2


func _active_pawn() -> PawnMarker:
	return _pawn_p1 if _active == BoardData.Player.P1 else _pawn_p2


func _set_cell_for_active(cell: String) -> void:
	if _active == BoardData.Player.P1:
		_cell_p1 = cell
	else:
		_cell_p2 = cell


func _hand_mut(player: BoardData.Player) -> Array:
	return _hand_p1 if player == BoardData.Player.P1 else _hand_p2


func _bed_for(player: BoardData.Player) -> PlantBed:
	return _bed_p1 if player == BoardData.Player.P1 else _bed_p2


func _deck_for(player: BoardData.Player) -> PlantDeck:
	return _deck_p1 if player == BoardData.Player.P1 else _deck_p2


func _base_seeds_for(player: BoardData.Player) -> int:
	return _base_seeds_p1 if player == BoardData.Player.P1 else _base_seeds_p2


func _spend_base_seeds(player: BoardData.Player, amount: int) -> void:
	if amount <= 0:
		return
	if player == BoardData.Player.P1:
		_base_seeds_p1 = maxi(0, _base_seeds_p1 - amount)
	else:
		_base_seeds_p2 = maxi(0, _base_seeds_p2 - amount)


func _refresh_plant_hud() -> void:
	if _hud_bed_p1 != null:
		_hud_bed_p1.refresh()
	if _hud_bed_p2 != null:
		_hud_bed_p2.refresh()


func _try_place_plant(player: BoardData.Player, plant_id: String, col: int, row: int) -> bool:
	var def := PlantCatalog.get_definition(plant_id)
	if def == null:
		return false
	var bed := _bed_for(player)
	if not bed.can_place(plant_id, col, row):
		return false
	if _base_seeds_for(player) < def.seeds_to_plant:
		return false
	var deck := _deck_for(player)
	if not deck.take(plant_id):
		return false
	if not bed.commit_place(plant_id, col, row):
		deck.undo_take(plant_id)
		return false
	_spend_base_seeds(player, def.seeds_to_plant)
	_update_resource_readout()
	_refresh_plant_hud()
	return true


func _open_planting_modal(player: BoardData.Player) -> void:
	var try_place := func(pid: String, c: int, r: int) -> bool:
		return _try_place_plant(player, pid, c, r)
	var seeds_fn := func() -> int:
		return _base_seeds_for(player)
	_planting_modal.open(player, _bed_for(player), _deck_for(player), try_place, seeds_fn)


func _on_planting_modal_finished() -> void:
	_planting_flow_active = false
	_refresh_plant_hud()
	_refresh_move_highlights()
	_end_active_turn_and_switch()


func _offer_planting_flow(player: BoardData.Player) -> void:
	if _game_over:
		_planting_flow_active = false
		_end_active_turn_and_switch()
		return
	_planting_flow_active = true
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Plant something?"
	dlg.ok_button_text = "Yes"
	dlg.cancel_button_text = "No"
	_plant_ui_layer.add_child(dlg)
	dlg.popup_centered()
	var answered := false

	var finish_no := func() -> void:
		if answered:
			return
		answered = true
		if is_instance_valid(dlg):
			dlg.queue_free()
		_planting_flow_active = false
		_refresh_plant_hud()
		_refresh_move_highlights()
		_end_active_turn_and_switch()

	dlg.canceled.connect(finish_no)
	dlg.close_requested.connect(finish_no)
	dlg.confirmed.connect(
		func() -> void:
			if answered:
				return
			answered = true
			if is_instance_valid(dlg):
				dlg.queue_free()
			_open_planting_modal(player)
	)


func _cell_is_own_base(player: BoardData.Player, cell: String) -> bool:
	return (
		(player == BoardData.Player.P1 and _cell_id_eq(cell, BoardData.BASE_P1))
		or (player == BoardData.Player.P2 and _cell_id_eq(cell, BoardData.BASE_P2))
	)


func _player_score(player: BoardData.Player) -> int:
	if player == BoardData.Player.P1:
		return _base_seeds_p1 + _base_water_p1
	return _base_seeds_p2 + _base_water_p2


func _trigger_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	var s1 := _player_score(BoardData.Player.P1)
	var s2 := _player_score(BoardData.Player.P2)
	var msg: String
	if s1 > s2:
		msg = "Game over — Player 1 wins (%d vs %d)." % [s1, s2]
	elif s2 > s1:
		msg = "Game over — Player 2 wins (%d vs %d)." % [s2, s1]
	else:
		msg = "Game over — tie (%d each)." % s1
	_turn_label.text = msg
	_end_turn_button.disabled = true


func _deposit_hand_to_base(player: BoardData.Player) -> void:
	var hand := _hand_mut(player)
	for item in hand:
		var v: Variant = item
		if v == CARRY_SEED:
			if player == BoardData.Player.P1:
				_base_seeds_p1 += 1
			else:
				_base_seeds_p2 += 1
		elif v == CARRY_WATER:
			if player == BoardData.Player.P1:
				_base_water_p1 += 1
			else:
				_base_water_p2 += 1
	hand.clear()
	var seeds_on_bases := _base_seeds_p1 + _base_seeds_p2
	var water_on_bases := _base_water_p1 + _base_water_p2
	if (
		seeds_on_bases == starting_seed_pool
		and water_on_bases == starting_water_pool
	):
		_trigger_game_over()


func _cell_id_eq(cell: Variant, expected: Variant) -> bool:
	## Avoid String vs StringName mismatches (const / dict keys vs stored state).
	return str(cell) == str(expected)


## After a move: deposit on own base if carrying; else pick up at seed/well if hands are empty.
func _resolve_cell_entry_after_move() -> void:
	var p := _active
	var cell: Variant = _current_cell()
	var hand := _hand_mut(p)
	if _cell_is_own_base(p, str(cell)) and hand.size() > 0:
		_deposit_hand_to_base(p)
		_deposited_this_move = true
		_update_resource_readout()
		return
	if _cell_id_eq(cell, BoardData.SEED_BOX) and hand.size() == 0:
		if _seed_pool_remaining > 0:
			_seed_pool_remaining -= 1
			hand.append(CARRY_SEED)
		_update_resource_readout()
		return
	if _cell_id_eq(cell, BoardData.WELL) and hand.size() == 0:
		if _water_pool_remaining > 0:
			_water_pool_remaining -= 1
			hand.append(CARRY_WATER)
		_update_resource_readout()


func _format_hand(hand: Array) -> String:
	if hand.is_empty():
		return "—"
	var parts: PackedStringArray = []
	for item in hand:
		var v: Variant = item
		parts.append("seed" if v == CARRY_SEED else "water")
	return ", ".join(parts)


func _update_resource_readout() -> void:
	if _resources_label == null:
		return
	_resources_label.text = (
		(
			"Supply  seeds %d  water %d\n"
			+ "P1  hand: %s  |  base  seeds %d  water %d\n"
			+ "P1  bed:  %s  (VP %d)\n"
			+ "P2  hand: %s  |  base  seeds %d  water %d\n"
			+ "P2  bed:  %s  (VP %d)"
		)
		% [
			_seed_pool_remaining,
			_water_pool_remaining,
			_format_hand(_hand_p1),
			_base_seeds_p1,
			_base_water_p1,
			_bed_p1.format_compact(),
			_bed_p1.total_bloomed_vp(),
			_format_hand(_hand_p2),
			_base_seeds_p2,
			_base_water_p2,
			_bed_p2.format_compact(),
			_bed_p2.total_bloomed_vp(),
		]
	)


func _bump_transfer_carry_to_winner(winner: BoardData.Player, loser: BoardData.Player) -> void:
	var win_h := _hand_mut(winner)
	var lose_h := _hand_mut(loser)
	for item in lose_h:
		win_h.append(item)
	lose_h.clear()
	_update_resource_readout()


func _apply_move(dest_cell: String) -> void:
	if _game_over:
		return
	if _bump_active:
		return
	_deposited_this_move = false
	var legal := BoardData.legal_next_cells(_active, _current_cell())
	if not dest_cell in legal:
		return
	_set_cell_for_active(dest_cell)
	var tex_size := _board.texture.get_size()
	var pos := BoardLayout.cell_center_local(dest_cell, tex_size) + cell_position_nudge
	_active_pawn().position = pos
	_resolve_cell_entry_after_move()
	if _game_over:
		_refresh_move_highlights()
		return
	if _deposited_this_move:
		call_deferred("_offer_planting_flow", _active)
		_refresh_move_highlights()
		return
	if _cell_p1 == _cell_p2:
		_run_bump_rps_flow.call_deferred()
	else:
		_end_active_turn_and_switch()


func _update_turn_label() -> void:
	if _game_over:
		return
	var n := 1 if _active == BoardData.Player.P1 else 2
	_turn_label.text = (
		"Player %d — arrows = direction to target · Enter = move · click dot · auto next · End = pass."
		% n
	)


func _refresh_move_highlights() -> void:
	for c in _highlights_root.get_children():
		c.queue_free()
	_legal_order.clear()
	if _game_over or _bump_active:
		return
	var tex_size := _board.texture.get_size()
	var nudge := cell_position_nudge
	for cell in BoardData.legal_next_cells(_active, _current_cell()):
		_legal_order.append(cell)
		var dot := _make_highlight_dot()
		dot.position = BoardLayout.cell_center_local(cell, tex_size) + nudge
		dot.set_meta(&"cell_id", cell)
		_highlights_root.add_child(dot)
	if _legal_order.size() > 0:
		var toward := Vector2.RIGHT if _active == BoardData.Player.P1 else Vector2.LEFT
		_kb_highlight_index = _index_of_best_legal_for_direction(toward)
	else:
		_kb_highlight_index = 0
	_update_keyboard_highlight_style()


## Among legal cells, pick the one whose vector from the pawn best matches `unit_dir` (screen: +Y down).
func _index_of_best_legal_for_direction(unit_dir: Vector2) -> int:
	if _legal_order.is_empty():
		return 0
	var pawn_pos := _active_pawn().position
	var tex_size := _board.texture.get_size()
	var nudge := cell_position_nudge
	var best_i := 0
	var best_dot := -2.0
	var best_dist_sq := INF
	for i in _legal_order.size():
		var cell := _legal_order[i]
		var target := BoardLayout.cell_center_local(cell, tex_size) + nudge
		var delta := target - pawn_pos
		var len_sq := delta.length_squared()
		if len_sq < 1e-4:
			continue
		var nd := delta * (1.0 / sqrt(len_sq))
		var dot := nd.dot(unit_dir)
		if dot > best_dot + 1e-5:
			best_dot = dot
			best_dist_sq = len_sq
			best_i = i
		elif absf(dot - best_dot) <= 1e-5 and len_sq < best_dist_sq:
			best_dist_sq = len_sq
			best_i = i
	return best_i


## Like `_index_of_best_legal_for_direction`, but only cells that lie in the half-space of `unit_dir`
## (pawn→cell aligned with the arrow). Returns -1 if no legal move exists in that direction.
func _index_of_best_legal_in_direction(unit_dir: Vector2) -> int:
	if _legal_order.is_empty():
		return -1
	var pawn_pos := _active_pawn().position
	var tex_size := _board.texture.get_size()
	var nudge := cell_position_nudge
	var best_i := -1
	var best_dot := -2.0
	var best_dist_sq := INF
	for i in _legal_order.size():
		var cell := _legal_order[i]
		var target := BoardLayout.cell_center_local(cell, tex_size) + nudge
		var delta := target - pawn_pos
		var len_sq := delta.length_squared()
		if len_sq < 1e-4:
			continue
		var nd := delta * (1.0 / sqrt(len_sq))
		var dot := nd.dot(unit_dir)
		if dot <= 1e-4:
			continue
		if dot > best_dot + 1e-5:
			best_dot = dot
			best_dist_sq = len_sq
			best_i = i
		elif absf(dot - best_dot) <= 1e-5 and len_sq < best_dist_sq:
			best_dist_sq = len_sq
			best_i = i
	return best_i


func _update_keyboard_highlight_style() -> void:
	var i := 0
	for child in _highlights_root.get_children():
		if not child is Polygon2D:
			continue
		var poly := child as Polygon2D
		var on := _legal_order.size() > 0 and i == _kb_highlight_index
		poly.color = (
			Color(1.0, 0.72, 0.12, 0.95) if on else Color(1.0, 0.92, 0.25, 0.52)
		)
		poly.scale = Vector2(1.32, 1.32) if on else Vector2.ONE
		i += 1


func _make_highlight_dot() -> Polygon2D:
	var h := Polygon2D.new()
	var pts: PackedVector2Array
	var count := 16
	var r := 16.0
	pts.resize(count)
	for i in count:
		var a := TAU * float(i) / float(count)
		pts[i] = Vector2(cos(a), sin(a)) * r
	h.polygon = pts
	h.color = Color(1.0, 0.92, 0.25, 0.62)
	h.z_index = 0
	return h


## Rock=0 Paper=1 Scissors=2 — true if `a` beats `b`.
static func _rps_beats(a: int, b: int) -> bool:
	return (a == 0 and b == 2) or (a == 2 and b == 1) or (a == 1 and b == 0)


func _send_player_home(loser: BoardData.Player) -> void:
	if loser == BoardData.Player.P1:
		_cell_p1 = BoardData.BASE_P1
		_pawn_p1.position = _home_local_p1
	else:
		_cell_p2 = BoardData.BASE_P2
		_pawn_p2.position = _home_local_p2


func _close_bump_overlay() -> void:
	_bump_active = false
	_bump_waiting_keys = false
	_bump_layer.visible = false
	_end_turn_button.disabled = false
	_bump_main_label.text = ""
	_bump_hint_label.text = ""
	_update_resource_readout()
	_refresh_move_highlights()


func _run_bump_rps_flow() -> void:
	_bump_active = true
	_bump_layer.visible = true
	_end_turn_button.disabled = true
	_bump_hint_label.text = ""
	var steps: Array[String] = ["Rock", "Paper", "Scissors", "Shoot!"]
	for w in steps:
		_bump_main_label.text = w
		await get_tree().create_timer(bump_countdown_step_sec).timeout
	while true:
		_bump_main_label.text = "Choose!"
		_bump_hint_label.text = (
			"P1: A Rock · S Paper · D Scissors          P2: J Rock · K Paper · L Scissors"
		)
		_bump_p1_pick = -1
		_bump_p2_pick = -1
		_bump_waiting_keys = true
		while _bump_p1_pick < 0 or _bump_p2_pick < 0:
			await get_tree().process_frame
		_bump_waiting_keys = false
		if _bump_p1_pick == _bump_p2_pick:
			_bump_main_label.text = "Tie!"
			_bump_hint_label.text = "Same throw — choose again."
			await get_tree().create_timer(0.65).timeout
			continue
		break
	var p1_wins := _rps_beats(_bump_p1_pick, _bump_p2_pick)
	if p1_wins:
		_bump_main_label.text = "Player 1 wins!"
		_bump_transfer_carry_to_winner(BoardData.Player.P1, BoardData.Player.P2)
		_send_player_home(BoardData.Player.P2)
	else:
		_bump_main_label.text = "Player 2 wins!"
		_bump_transfer_carry_to_winner(BoardData.Player.P2, BoardData.Player.P1)
		_send_player_home(BoardData.Player.P1)
	_bump_hint_label.text = "Loser returns to home base."
	await get_tree().create_timer(1.2).timeout
	_close_bump_overlay()
	_end_active_turn_and_switch()
