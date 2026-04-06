class_name BoardData
extends RefCounted
## Authoritative board layout + path graph for *The Garden Architects*.
## PATH_NEIGHBORS_* built from playtest routes (undirected: each step works both ways).
##
## Cell IDs: column letter + row number, e.g. "F1". Board interior is B1–F5.
## Bases sit beside the board on row 5: P1 = west (A5), P2 = east (G5).
##
## Design-doc note: the printed GDD mentioned well/seed in “opposite corners”;
## playtest layout uses SEED_BOX at B1 and WELL at F1 instead.

enum Player { P1, P2 }

## Mutable so PathGenerator can replace them before game state initialises.
static var BASE_P1: String = "A5"
static var BASE_P2: String = "G5"
static var SEED_BOX: String = "B1"
static var WELL: String = "F1"

## All 5×5 interior squares (for iteration, highlights, validation helpers).
const BOARD_CELLS: Array[String] = [
	"B1", "C1", "D1", "E1", "F1",
	"B2", "C2", "D2", "E2", "F2",
	"B3", "C3", "D3", "E3", "F3",
	"B4", "C4", "D4", "E4", "F4",
	"B5", "C5", "D5", "E5", "F5",
]

## Keys: any cell where this player’s pawn may stand (usually BOARD_CELLS + that player’s base).
## Values: Array of cell IDs reachable in **one step** along **this player’s** colored path.
## Replaced at runtime by PathGenerator; defaults are the hand-authored playtest layout.
## P1: A5↔seed (via C1 or B2 branches), A5↔well (via D1–E1 or D3–F3–F2).
static var PATH_NEIGHBORS_P1: Dictionary = {
	"A5": ["B5"],
	"B1": ["B2", "C1"],
	"B2": ["B1", "C2"],
	"B4": ["B5", "C4"],
	"B5": ["A5", "B4"],
	"C1": ["B1", "C2", "D1"],
	"C2": ["B2", "C1", "C3"],
	"C3": ["C2", "C4", "D3"],
	"C4": ["B4", "C3"],
	"D1": ["C1", "E1"],
	"D3": ["C3", "E3"],
	"E1": ["D1", "F1"],
	"E3": ["D3", "F3"],
	"F1": ["E1", "F2"],
	"F2": ["F1", "F3"],
	"F3": ["E3", "F2"],
}

## P2: G5↔seed (via B2–B1 or D2–D1–C1), G5↔well (via E1 or F2); E2↔D2.
static var PATH_NEIGHBORS_P2: Dictionary = {
	"B1": ["B2", "C1"],
	"B2": ["B1", "C2"],
	"C1": ["B1", "D1"],
	"C2": ["B2", "C3", "D2"],
	"C3": ["C2", "D3"],
	"D1": ["C1", "D2"],
	"D2": ["C2", "D1", "E2"],
	"D3": ["C3", "D4"],
	"D4": ["D3", "E4"],
	"E1": ["E2", "F1"],
	"E2": ["D2", "E1", "E3", "F2"],
	"E3": ["E2", "E4"],
	"E4": ["D4", "E3", "F4"],
	"F1": ["E1", "F2"],
	"F2": ["E2", "F1"],
	"F4": ["E4", "F5"],
	"F5": ["F4", "G5"],
	"G5": ["F5"],
}


## Replace all runtime-mutable fields from a generated layout.
## Call this before any game-state initialisation in main.gd._ready().
static func apply_layout(layout: GeneratedLayout) -> void:
	BASE_P1 = layout.p1_base
	BASE_P2 = layout.p2_base
	SEED_BOX = layout.seed_box
	WELL = layout.well
	PATH_NEIGHBORS_P1 = layout.p1_neighbors
	PATH_NEIGHBORS_P2 = layout.p2_neighbors


static func path_neighbors(player: Player) -> Dictionary:
	match player:
		Player.P1:
			return PATH_NEIGHBORS_P1
		Player.P2:
			return PATH_NEIGHBORS_P2
		_:
			return {}


static func legal_next_cells(player: Player, from_cell: String) -> Array[String]:
	var d: Dictionary = path_neighbors(player)
	if not d.has(from_cell):
		return []
	var raw: Variant = d[from_cell]
	if raw is Array:
		var out: Array[String] = []
		for item in raw:
			out.append(str(item))
		return out
	return []


static func is_board_cell(cell: String) -> bool:
	return BOARD_CELLS.has(cell)


static func specials_at(cell: String) -> Array[String]:
	var tags: Array[String] = []
	if cell == SEED_BOX:
		tags.append("seed_box")
	if cell == WELL:
		tags.append("well")
	if cell == BASE_P1:
		tags.append("base_p1")
	if cell == BASE_P2:
		tags.append("base_p2")
	return tags
