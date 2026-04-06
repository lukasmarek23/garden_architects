class_name PlantDefinition
extends Resource
## One catalog row: costs, VP, polyomino footprint (offsets from anchor), optional icon.

@export var id: String = ""
@export var display_name: String = ""
@export var water_to_mature: int = 1
@export var seeds_to_plant: int = 1
@export var victory_points: int = 1
@export var icon: Texture2D
## Offsets from anchor cell (col, row). Anchor is the top-left of the footprint bounding box.
## Horizontal-only layouts for now (no rotation).
var shape_offsets: Array[Vector2i] = []
