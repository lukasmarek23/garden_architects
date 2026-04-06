class_name GeneratedLayout
extends RefCounted
## Result of PathGenerator.generate(). Consumed by BoardData.apply_layout() and main.gd visuals.

var p1_base: String = ""
var p2_base: String = ""
var well: String = ""
var seed_box: String = ""
## Adjacency dicts — same format as BoardData.PATH_NEIGHBORS_*.
## Key: cell String, Value: Array[String] of reachable neighbours.
var p1_neighbors: Dictionary = {}
var p2_neighbors: Dictionary = {}
## Flat lists of all cells in each path (including base).
var p1_cells: Array[String] = []
var p2_cells: Array[String] = []
## Cells shared by both paths (excluding bases).
var crossing_cells: Array[String] = []
