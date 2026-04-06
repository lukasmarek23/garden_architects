class_name PlantCatalog
extends RefCounted
## In-memory plant database + deck order for the planting UI.

const DECK_COPIES_EACH := 5

static var _by_id: Dictionary = {}  # String -> PlantDefinition
static var _deck_order: PackedStringArray = []


static func _def(
	p_id: String,
	p_name: String,
	p_water: int,
	p_seeds: int,
	p_vp: int,
	p_shape: Array[Vector2i],
	p_icon: Texture2D = null
) -> PlantDefinition:
	var d := PlantDefinition.new()
	d.id = p_id
	d.display_name = p_name
	d.water_to_mature = p_water
	d.seeds_to_plant = p_seeds
	d.victory_points = p_vp
	d.shape_offsets = p_shape
	d.icon = p_icon
	return d


static func _ensure_loaded() -> void:
	if not _by_id.is_empty():
		return
	var strawberry_tex: Texture2D = null
	if ResourceLoader.exists("res://art/plants/strawberry.png"):
		strawberry_tex = load("res://art/plants/strawberry.png") as Texture2D
	_register(
		_def(
			"strawberry",
			"Strawberry",
			1,
			1,
			1,
			[Vector2i(0, 0)],
			strawberry_tex
		)
	)
	_register(_def("onion", "Onion", 2, 2, 2, [Vector2i(0, 0), Vector2i(1, 0)], null))
	_register(_def("rose", "Rose", 4, 4, 4, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)], null))
	_deck_order = PackedStringArray(["strawberry", "onion", "rose"])


static func _register(def: PlantDefinition) -> void:
	if def.id.is_empty():
		push_warning("PlantCatalog: skipped plant with empty id")
		return
	_by_id[def.id] = def


static func get_definition(plant_id: String) -> PlantDefinition:
	_ensure_loaded()
	var v: Variant = _by_id.get(plant_id, null)
	return v as PlantDefinition


static func has_id(plant_id: String) -> bool:
	_ensure_loaded()
	return _by_id.has(plant_id)


## Fixed deck order for the planting pool UI (left-to-right / top-to-bottom).
static func deck_plant_ids() -> PackedStringArray:
	_ensure_loaded()
	return _deck_order


static func all_ids() -> PackedStringArray:
	_ensure_loaded()
	var out: PackedStringArray = []
	for k in _by_id.keys():
		out.append(str(k))
	out.sort()
	return out
