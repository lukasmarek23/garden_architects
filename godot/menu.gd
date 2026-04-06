extends Control
## Main menu scene. Builds all UI in code so the .tscn stays trivial.
## Set this scene as the project's starting scene:
##   Project → Project Settings → Application → Run → Main Scene → res://menu.tscn

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


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.10, 0.07, 1.0)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(340, 0)
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	# Title
	var title := Label.new()
	title.text = "The Garden Architects"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.85, 0.78, 0.45))
	center.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	center.add_child(spacer)

	_add_button(center, "New Game",    _on_new_game)
	_add_button(center, "How to Play", _on_how_to_play)
	_add_button(center, "Quit",        _on_quit)

	_build_how_to_panel()


func _add_button(parent: Control, label: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(340, 52)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	parent.add_child(btn)


func _build_how_to_panel() -> void:
	_how_to_panel = PanelContainer.new()
	_how_to_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_how_to_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.05, 0.97)
	style.set_corner_radius_all(8)
	_how_to_panel.add_theme_stylebox_override("panel", style)
	add_child(_how_to_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_how_to_panel.add_child(vbox)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var lbl := Label.new()
	lbl.text = HOW_TO_PLAY_TEXT
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 17)
	lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.82))
	lbl.custom_minimum_size = Vector2(680, 0)
	scroll.add_child(lbl)

	_add_button(vbox, "Back", func(): _how_to_panel.visible = false)


func _on_new_game() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func _on_how_to_play() -> void:
	_how_to_panel.visible = true


func _on_quit() -> void:
	get_tree().quit()
