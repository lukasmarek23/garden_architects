extends Node
## Autoload singleton — persists character choices between scenes.
##
## Register in: Project → Project Settings → AutoLoad
##   Path:  res://game_state.gd
##   Name:  GameState

const CHARACTERS = [
	{"name": "Gnome",     "color": Color(0.25, 0.45, 0.90, 1.0), "portrait": "res://art/characters/gnome_main.png"},
	{"name": "Mouse",     "color": Color(0.85, 0.20, 0.20, 1.0), "portrait": "res://art/characters/mouse_main.png"},
	{"name": "Bee",       "color": Color(0.95, 0.82, 0.10, 1.0), "portrait": "res://art/characters/bee_main.png"},
	{"name": "Butterfly", "color": Color(0.70, 0.20, 0.88, 1.0), "portrait": "res://art/characters/butterfly_main.png"},
]

var p1_character: String = "Gnome"
var p1_color: Color     = CHARACTERS[0]["color"]
var p2_character: String = "Mouse"
var p2_color: Color     = CHARACTERS[1]["color"]


static func color_for(character_name: String) -> Color:
	for c in CHARACTERS:
		if c["name"] == character_name:
			return c["color"]
	return Color.WHITE
