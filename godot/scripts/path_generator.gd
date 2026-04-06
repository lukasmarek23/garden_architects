class_name PathGenerator
extends RefCounted
## Procedurally generates two player paths on the 5×5 interior grid (cols B–F, rows 1–5),
## with bases in the A-column (P1) and G-column (P2).
##
## Constraints enforced:
##   1. Both paths are connected graphs containing their base, the well, and the seed box.
##   2. |P1 path cells| == |P2 path cells| (same total cell count).
##   3. Paths share ≥ MIN_CROSSINGS interior cells.
##   4. dist(P1_base→well) + dist(P1_base→seed) == dist(P2_base→well) + dist(P2_base→seed)
##      where distance is shortest path within each player's own graph.
##
## Well and seed box are placed on opposite halves (one in cols B–C, one in cols E–F) so
## that the distance-sum constraint has a realistic chance of being satisfied by retrying.

const COLS := "ABCDEFG"
const ROWS := 5
const MIN_PATH_CELLS := 9
const MAX_PATH_CELLS := 15
const MIN_CROSSINGS := 3
const MAX_OUTER := 600
const MAX_P2_INNER := 100


static func generate(rng: RandomNumberGenerator = null) -> GeneratedLayout:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	for _i in MAX_OUTER:
		var result := _attempt(rng)
		if result != null:
			return result
	push_warning("PathGenerator: no valid layout found after %d attempts." % MAX_OUTER)
	return null


# ── single attempt ──────────────────────────────────────────────────────────

static func _attempt(rng: RandomNumberGenerator) -> GeneratedLayout:
	# 1. Place bases (random row in their column).
	var p1_base := _cell(0, rng.randi_range(1, ROWS))  # column A
	var p2_base := _cell(6, rng.randi_range(1, ROWS))  # column G

	# 2. Place well and seed on opposite halves (one B–C, one E–F) to aid balance.
	var p1_side: Array[String] = _cells_in_col_range(1, 2)  # B–C
	var p2_side: Array[String] = _cells_in_col_range(4, 5)  # E–F
	_shuffle(p1_side, rng)
	_shuffle(p2_side, rng)
	var well: String
	var seed_box: String
	if rng.randi() % 2 == 0:
		well = p1_side[0]
		seed_box = p2_side[0]
	else:
		well = p2_side[0]
		seed_box = p1_side[0]

	# 3. Determine P1 entry: the B-column cell on the same row as the base.
	var p1_entry := _cell(1, _row(p1_base))  # B + base_row
	# P2 entry: F-column cell on same row as base.
	var p2_entry := _cell(5, _row(p2_base))  # F + base_row

	# 4. Generate P1 path (base + cells in B–F interior).
	var target_size := rng.randi_range(MIN_PATH_CELLS, MAX_PATH_CELLS)
	var p1_adj := _grow_path(p1_base, p1_entry, [well, seed_box], target_size, rng)
	if p1_adj.is_empty():
		return null

	var d1_well := _bfs_dist(p1_adj, p1_base, well)
	var d1_seed := _bfs_dist(p1_adj, p1_base, seed_box)
	if d1_well < 0 or d1_seed < 0:
		return null
	var target_dist := d1_well + d1_seed

	# 5. Generate P2 path with same size and matching distance sum.
	var p2_adj: Dictionary = {}
	var found_p2 := false
	for _j in MAX_P2_INNER:
		var candidate := _grow_path(p2_base, p2_entry, [well, seed_box], p1_adj.size(), rng)
		if candidate.is_empty():
			continue
		var d2_well := _bfs_dist(candidate, p2_base, well)
		var d2_seed := _bfs_dist(candidate, p2_base, seed_box)
		if d2_well < 0 or d2_seed < 0:
			continue
		if d2_well + d2_seed == target_dist:
			p2_adj = candidate
			found_p2 = true
			break
	if not found_p2:
		return null

	# 6. Collect cell lists.
	var p1_cells: Array[String] = []
	for k in p1_adj.keys():
		p1_cells.append(str(k))
	var p2_cells: Array[String] = []
	for k in p2_adj.keys():
		p2_cells.append(str(k))

	# 7. Check crossing count (shared cells that aren't a base).
	var p1_set: Dictionary = {}
	for c in p1_cells:
		p1_set[c] = true
	var crossings: Array[String] = []
	for c in p2_cells:
		if p1_set.has(c) and c != p1_base and c != p2_base:
			crossings.append(c)
	if crossings.size() < MIN_CROSSINGS:
		return null

	var layout := GeneratedLayout.new()
	layout.p1_base = p1_base
	layout.p2_base = p2_base
	layout.well = well
	layout.seed_box = seed_box
	layout.p1_neighbors = p1_adj
	layout.p2_neighbors = p2_adj
	layout.p1_cells = p1_cells
	layout.p2_cells = p2_cells
	layout.crossing_cells = crossings
	return layout


# ── path growth ──────────────────────────────────────────────────────────────

## Builds a connected path graph for one player.
## `base`  : the A- or G-column base cell.
## `entry` : the single interior cell adjacent to the base (B-col or F-col, same row).
## `must_include` : [well, seed_box] — must be reachable from the base.
## Returns adjacency Dictionary (key=cell String, value=Array[String]).
## Returns empty dict on failure.
static func _grow_path(
	base: String,
	entry: String,
	must_include: Array,
	target_size: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var cells: Dictionary = {}
	cells[base] = true
	cells[entry] = true

	# Phase 1: connect entry cell set to each required special via BFS in B–F interior.
	for sv in must_include:
		var special := str(sv)
		if cells.has(special):
			continue
		var path := _bfs_interior_set_to_target(cells, base, special)
		if path.is_empty():
			return {}
		for c in path:
			cells[c] = true

	# Phase 2: grow randomly within B–F until target_size.
	var eff_target := maxi(cells.size(), target_size)
	var budget := eff_target * 6
	var attempts := 0
	while cells.size() < eff_target and attempts < budget:
		attempts += 1
		var candidates: Array[String] = []
		for cv in cells.keys():
			var c := str(cv)
			if c == base:
				continue
			for nbr in _interior_neighbors(c):
				if not cells.has(nbr):
					candidates.append(nbr)
		if candidates.is_empty():
			break
		cells[candidates[rng.randi_range(0, candidates.size() - 1)]] = true

	# Phase 3: build adjacency dict.
	# Base connects only to entry; everything else is 4-connected within B–F.
	var adj: Dictionary = {}
	for cv in cells.keys():
		adj[str(cv)] = [] as Array

	(adj[base] as Array).append(entry)
	for cv in cells.keys():
		var c := str(cv)
		if c == base:
			continue
		for nbr in _interior_neighbors(c):
			if cells.has(nbr) and not (adj[c] as Array).has(nbr):
				(adj[c] as Array).append(nbr)
		# entry also needs base in its neighbour list
		if c == entry and not (adj[entry] as Array).has(base):
			(adj[entry] as Array).append(base)

	return adj


## Multi-source BFS from all interior cells in `cells` (excluding `base`) toward `target`.
## Returns the new cells to add (not including existing sources, but including `target`).
static func _bfs_interior_set_to_target(
	cells: Dictionary, base: String, target: String
) -> Array[String]:
	var queue: Array = []
	var prev: Dictionary = {}

	for cv in cells.keys():
		var c := str(cv)
		if c == base:
			continue
		prev[c] = ""
		queue.append(c)

	var found := ""
	while not queue.is_empty() and found.is_empty():
		var cur := str(queue.pop_front())
		for nbr in _interior_neighbors(cur):
			if nbr == target:
				found = target
				prev[target] = cur
				break
			if not prev.has(nbr):
				prev[nbr] = cur
				queue.append(nbr)

	if found.is_empty():
		return []

	# Reconstruct path from target back to the source (don't include the source itself).
	var path_rev: Array[String] = []
	var cur := found
	while prev.has(cur) and str(prev.get(cur, "")) != "":
		path_rev.append(cur)
		cur = str(prev[cur])
	path_rev.reverse()
	return path_rev


# ── BFS distance on an adjacency dict ────────────────────────────────────────

static func _bfs_dist(adj: Dictionary, start: String, end: String) -> int:
	if start == end:
		return 0
	if not adj.has(start) or not adj.has(end):
		return -1
	var queue: Array = [start]
	var dist: Dictionary = {start: 0}
	while not queue.is_empty():
		var cur := str(queue.pop_front())
		for nbr_v in adj.get(cur, []):
			var nbr := str(nbr_v)
			if not dist.has(nbr):
				dist[nbr] = int(dist[cur]) + 1
				if nbr == end:
					return int(dist[nbr])
				queue.append(nbr)
	return -1


# ── grid helpers ─────────────────────────────────────────────────────────────

## 4-connected neighbours of `cell` strictly within the B–F interior (cols 1–5).
static func _interior_neighbors(cell: String) -> Array[String]:
	var out: Array[String] = []
	if cell.length() < 2:
		return out
	var col := COLS.find(cell.substr(0, 1))
	var row := int(cell.substr(1))
	if col < 1 or col > 5 or row < 1 or row > ROWS:
		return out
	if col > 1:
		out.append(_cell(col - 1, row))
	if col < 5:
		out.append(_cell(col + 1, row))
	if row > 1:
		out.append(_cell(col, row - 1))
	if row < ROWS:
		out.append(_cell(col, row + 1))
	return out


static func _cell(col_int: int, row: int) -> String:
	return COLS[col_int] + str(row)


static func _row(cell: String) -> int:
	return int(cell.substr(1))


static func _cells_in_col_range(min_col: int, max_col: int) -> Array[String]:
	var out: Array[String] = []
	for c in range(min_col, max_col + 1):
		for r in range(1, ROWS + 1):
			out.append(_cell(c, r))
	return out


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
