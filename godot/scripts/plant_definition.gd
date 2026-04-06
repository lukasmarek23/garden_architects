class_name PlantDefinition
extends Resource
## One catalog row: costs, VP, polyomino footprint (offsets from anchor), optional icon.

@export var id: String = ""
@export var display_name: String = ""
@export var water_to_mature: int = 1
@export var seeds_to_plant: int = 1
@export var victory_points: int = 1
@export var icon: Texture2D
## Base (rotation=0) offsets from anchor cell (col, row). Anchor normalised to min=(0,0).
var shape_offsets: Array[Vector2i] = []


## Rotate `offsets` 90° clockwise `times` times and normalise so min=(0,0).
static func rotate_shape(offsets: Array[Vector2i], times: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for off in offsets:
		result.append(off)
	for _t in (times % 4):
		var rotated: Array[Vector2i] = []
		for v in result:
			rotated.append(Vector2i(v.y, -v.x))
		var min_x := rotated[0].x
		var min_y := rotated[0].y
		for v in rotated:
			if v.x < min_x:
				min_x = v.x
			if v.y < min_y:
				min_y = v.y
		result.clear()
		for v in rotated:
			result.append(Vector2i(v.x - min_x, v.y - min_y))
	return result
