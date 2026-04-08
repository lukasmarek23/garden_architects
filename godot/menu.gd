extends Control
## Main menu scene. Builds all UI in code so the .tscn stays trivial.
## Set this scene as the project's starting scene:
##   Project → Project Settings → Application → Run → Main Scene → res://menu.tscn

const _MenuTheme = preload("res://scripts/ui_menu_theme.gd")
const CHARACTER_SELECT_SCENE := "res://character_select.tscn"

const HOW_TO_PLAY_TEXT := \
"""Two players race along their garden paths collecting seeds and water.

MOVEMENT
  • Select a highlighted tile and press End Turn to move.
  • Arrow keys navigate available moves; Enter or End Turn confirms.

RESOURCES
  • Land on the Seed Box  to pick up a seed.
  • Land on the Well      to pick up a water drop.
  • Return to your Base   to deposit whatever you carry.
  • Each deposited item scores 1 point.

BUMPING
  • If both pawns meet on the same tile, play Rock–Paper–Scissors.
  • The winner takes the loser's carried item.

PLANTING
  • After depositing at your base you may plant something.
  • Choose a plant from your pool — it costs seeds + water from your base.
  • Place and rotate the plant shape onto your 5×4 garden bed.
  • Each planted plant adds its Victory Points to your score.

END OF GAME
  The game ends when the last seed or water drop is delivered to a base.
  The player with the highest combined score wins."""

var _how_to_panel: Control
var _btn_new: Button
var _btn_how: Button
var _btn_quit: Button
var _btn_back: Button
var _how_to_scroll: ScrollContainer
const _HOW_TO_SCROLL_STEP := 56


## Godot 4: code-created Controls need explicit anchor layout_mode + grow or they stay top-left sized.
## layout_mode 1 = anchors (LAYOUT_MODE_ANCHORS — name varies by engine version).
func _ui_cover_screen(c: Control) -> void:
	c.layout_mode = 1
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.anchor_right = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = 0.0
	c.offset_top = 0.0
	c.offset_right = 0.0
	c.offset_bottom = 0.0
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.grow_vertical = Control.GROW_DIRECTION_BOTH


func _ready() -> void:
	MenuFlowMusic.ensure_playing()
	_ui_cover_screen(self)

	var grad := _MenuTheme.make_gradient_background()
	_ui_cover_screen(grad)
	grad.z_index = -5
	add_child(grad)

	_MenuTheme.add_plant_corners(self)

	var cc := CenterContainer.new()
	_ui_cover_screen(cc)
	cc.z_index = 0
	add_child(cc)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _MenuTheme.style_menu_card())
	cc.add_child(card)

	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(380, 0)
	center.add_theme_constant_override("separation", 20)
	card.add_child(center)

	var title := Label.new()
	title.text = "The Garden\nArchitects"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_MenuTheme.style_heading_label(title)
	center.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	center.add_child(spacer)

	_btn_new = _add_button(center, "New Game", _on_new_game)
	_btn_how = _add_button(center, "How to Play", _on_how_to_play)
	_btn_quit = _add_button(center, "Quit", _on_quit)
	_btn_new.focus_neighbor_bottom = _btn_new.get_path_to(_btn_how)
	_btn_how.focus_neighbor_top = _btn_how.get_path_to(_btn_new)
	_btn_how.focus_neighbor_bottom = _btn_how.get_path_to(_btn_quit)
	_btn_quit.focus_neighbor_top = _btn_quit.get_path_to(_btn_how)

	_build_how_to_panel()
	_btn_new.grab_focus.call_deferred()


func _add_button(parent: Control, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(360, 56)
	_MenuTheme.style_menu_button(btn)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn


func _build_how_to_panel() -> void:
	# Dim overlay that fills the whole screen.
	_how_to_panel = Control.new()
	_ui_cover_screen(_how_to_panel)
	_how_to_panel.visible = false
	add_child(_how_to_panel)

	var dim := ColorRect.new()
	_ui_cover_screen(dim)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_how_to_panel.add_child(dim)

	# Centered content panel — 900 px wide.
	var cc := CenterContainer.new()
	_ui_cover_screen(cc)
	_how_to_panel.add_child(cc)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	panel.add_theme_stylebox_override("panel", _MenuTheme.style_panel_flat(true))
	cc.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var h2 := Label.new()
	h2.text = "How to Play"
	h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_MenuTheme.style_subheading_label(h2)
	vbox.add_child(h2)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_how_to_scroll = scroll

	var lbl := Label.new()
	lbl.text = HOW_TO_PLAY_TEXT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_MenuTheme.style_body_label(lbl, 18)
	scroll.add_child(lbl)

	_btn_back = _add_button(vbox, "Back", _close_how_to_play)


func _on_new_game() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func _on_how_to_play() -> void:
	_how_to_panel.visible = true
	_btn_back.grab_focus.call_deferred()


func _close_how_to_play() -> void:
	_how_to_panel.visible = false
	_how_to_scroll.scroll_vertical = 0
	_btn_new.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if not _how_to_panel.visible:
		return
	if not event is InputEventKey:
		return
	var ek := event as InputEventKey
	if not ek.pressed or ek.echo:
		return
	var vp := get_viewport()
	match ek.physical_keycode:
		KEY_UP:
			_how_to_scroll.scroll_vertical -= _HOW_TO_SCROLL_STEP
			if vp != null:
				vp.set_input_as_handled()
		KEY_DOWN:
			_how_to_scroll.scroll_vertical += _HOW_TO_SCROLL_STEP
			if vp != null:
				vp.set_input_as_handled()
		KEY_ESCAPE:
			_close_how_to_play()
			if vp != null:
				vp.set_input_as_handled()


func _on_quit() -> void:
	get_tree().quit()
