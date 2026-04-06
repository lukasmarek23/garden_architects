class_name PlantDeck
extends RefCounted
## Per-player fixed deck: `DECK_COPIES_EACH` of each catalog deck id at start.

var _remaining: Dictionary = {}  # String -> int


func _init() -> void:
	PlantCatalog._ensure_loaded()
	for plant_id in PlantCatalog.deck_plant_ids():
		_remaining[str(plant_id)] = PlantCatalog.DECK_COPIES_EACH


func remaining(plant_id: String) -> int:
	return int(_remaining.get(plant_id, 0))


func take(plant_id: String) -> bool:
	var n := remaining(plant_id)
	if n <= 0:
		return false
	_remaining[plant_id] = n - 1
	return true


func undo_take(plant_id: String) -> void:
	_remaining[plant_id] = remaining(plant_id) + 1


func has_any() -> bool:
	for plant_id in PlantCatalog.deck_plant_ids():
		if remaining(plant_id) > 0:
			return true
	return false
