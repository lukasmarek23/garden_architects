extends Control
## Two-phase character selection: P1 picks first, then P2.
## Keyboard: Up/Down navigate list · Enter confirms · Escape returns to main menu.

const MENU_SCENE := "res://menu.tscn"
const GAME_SCENE := "res://main.tscn"

var _phase: int = 1          # 1 = P1 choosing, 2 = P2 choosing
var _cursor: int = 0         # index into GameState.CHARACTERS
var _p1_choice: int = 0

# UI refs built in _ready
var _title_label: Label
var _portrait_rect: ColorRect
var _portrait_label: Label
var _list_items: Array[Control] = []
var _hint_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dark background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.10, 0.07, 1.0)
	add_child(bg)

	# Outer VBox (title + content + hint)
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 24)
	outer.offset_left   =  60.0
	outer.offset_right  = -60.0
	outer.offset_top    =  40.0
	outer.offset_bottom = -40.0
	add_child(outer)

	# Title
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.45))
	outer.add_child(_title_label)

	# Content row: portrait (left) + list (right)
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 40)
	outer.add_child(hbox)

	# Left — portrait
	var portrait_wrap := VBoxContainer.new()
	portrait_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_wrap.add_theme_constant_override("separation", 14)
	hbox.add_child(portrait_wrap)

	_portrait_rect = ColorRect.new()
	_portrait_rect.custom_minimum_size = Vector2(220, 220)
	_portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_wrap.add_child(_portrait_rect)

	_portrait_label = Label.new()
	_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_label.add_theme_font_size_override("font_size", 24)
	_portrait_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	portrait_wrap.add_child(_portrait_label)

	# Right — character list
	var list_wrap := VBoxContainer.new()
	list_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	list_wrap.add_theme_constant_override("separation", 10)
	hbox.add_child(list_wrap)

	for i in GameState.CHARACTERS.size():
		var entry: Dictionary = GameState.CHARACTERS[i]
		var row := _make_list_row(entry["name"], entry["color"])
		list_wrap.add_child(row)
		_list_items.append(row)

	# Hint at the bottom
	_hint_label = Label.new()
	_hint_label.text = "↑ ↓  navigate   ·   Enter  confirm   ·   Escape  back"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.50))
	outer.add_child(_hint_label)

	_refresh_ui()


func _make_list_row(char_name: String, char_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 56)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)

	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(28, 28)
	swatch.color = char_color
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(swatch)

	var lbl := Label.new()
	lbl.text = char_name
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl)

	return panel


func _refresh_ui() -> void:
	_title_label.text = "Player %d — choose your character" % _phase

	var chars := GameState.CHARACTERS
	var selected: Dictionary = chars[_cursor]
	_portrait_rect.color = selected["color"]
	_portrait_label.text = selected["name"]

	for i in _list_items.size():
		var panel: PanelContainer = _list_items[i]
		var is_cursor   := (i == _cursor)
		var is_taken    := (_phase == 2 and i == _p1_choice)
		var style := StyleBoxFlat.new()
		if is_cursor and not is_taken:
			style.bg_color = Color(0.25, 0.35, 0.25, 0.95)
			style.set_border_width_all(2)
			style.border_color = Color(0.85, 0.78, 0.45)
		elif is_taken:
			style.bg_color = Color(0.15, 0.15, 0.15, 0.60)
		else:
			style.bg_color = Color(0.12, 0.16, 0.12, 0.80)
		panel.add_theme_stylebox_override("panel", style)

		# Grey out the label and swatch of the taken slot
		var hb := panel.get_child(0) as HBoxContainer
		var lbl: Label = hb.get_child(1)
		lbl.modulate = Color(0.40, 0.40, 0.40) if is_taken else Color.WHITE


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not event is InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return

	var vp := get_viewport()
	match ek.physical_keycode:
		KEY_UP:
			_move_cursor(-1)
		KEY_DOWN:
			_move_cursor(1)
		KEY_ENTER, KEY_KP_ENTER:
			_confirm()
		KEY_ESCAPE:
			get_tree().change_scene_to_file(MENU_SCENE)
	if vp != null and is_instance_valid(vp):
		vp.set_input_as_handled()


func _move_cursor(delta: int) -> void:
	var n := GameState.CHARACTERS.size()
	# Skip the taken slot when in phase 2
	for _i in n:
		_cursor = posmod(_cursor + delta, n)
		if _phase == 1 or _cursor != _p1_choice:
			break
	_refresh_ui()


func _confirm() -> void:
	if _phase == 2 and _cursor == _p1_choice:
		return  # taken slot, ignore

	if _phase == 1:
		_p1_choice = _cursor
		GameState.p1_character = GameState.CHARACTERS[_cursor]["name"]
		GameState.p1_color     = GameState.CHARACTERS[_cursor]["color"]
		# Start P2 cursor on a different slot
		_phase = 2
		_cursor = posmod(_p1_choice + 1, GameState.CHARACTERS.size())
		_refresh_ui()
	else:
		GameState.p2_character = GameState.CHARACTERS[_cursor]["name"]
		GameState.p2_color     = GameState.CHARACTERS[_cursor]["color"]
		get_tree().change_scene_to_file(GAME_SCENE)
