class_name PlantPoolSlot
extends PanelContainer
## Draggable catalog entry for the planting modal (drag payload = plant id).

var plant_id: String = ""
var deck: PlantDeck
var base_seeds_getter: Callable = Callable()

var _icon: TextureRect
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(40, 40)
	_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(_icon)
	_label = Label.new()
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(_label)
	add_child(hb)
	refresh_visual()


func refresh_visual() -> void:
	var def := PlantCatalog.get_definition(plant_id)
	var left := deck.remaining(plant_id) if deck != null else 0
	var need := def.seeds_to_plant if def != null else 0
	var seeds := 0
	if base_seeds_getter.is_valid():
		seeds = int(base_seeds_getter.call())
	var name := def.display_name if def != null else plant_id
	_label.text = "%s  ×%d  (needs %d seeds · you have %d)" % [name, left, need, seeds]
	if def != null and def.icon != null:
		_icon.texture = def.icon
	else:
		_icon.texture = null
		_icon.modulate = Color(0.85, 0.85, 0.88, 1.0)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if deck == null or plant_id.is_empty():
		return null
	if deck.remaining(plant_id) <= 0:
		return null
	var def := PlantCatalog.get_definition(plant_id)
	if def == null:
		return null
	var seeds := 0
	if base_seeds_getter.is_valid():
		seeds = int(base_seeds_getter.call())
	if seeds < def.seeds_to_plant:
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(48, 48)
	if def.icon != null:
		preview.texture = def.icon
		preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		preview.modulate = Color(0.7, 0.75, 0.72, 1.0)
	set_drag_preview(preview)
	return {"type": "plant", "plant_id": plant_id}
