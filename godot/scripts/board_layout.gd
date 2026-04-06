class_name BoardLayout
extends RefCounted
## Maps cell ids ("B1" … "G5") to **board texture** space, then to local coords for
## children of the board Sprite2D. Pawns belong on the board (or a Board Node2D),
## not viewport-anchored UI—that breaks camera zoom and board pan. Wrong placement
## is almost always **origin / cell_px / row direction**. Prefer **Main → derive_grid_from_starting_pawns**
## when PawnP1/PawnP2 are hand-placed at A5/G5 so spacing matches the art.

## Top-left corner of cell **B1** in **texture pixel space** (0,0 = top-left of PNG).
static var origin_b1_top_left: Vector2 = Vector2(682, 1138)
## One cell width × height in pixels (same for columns A–G and rows 1–5).
static var cell_px: Vector2 = Vector2(128, 128)
## true → row **5** is toward the **top** of the image (smaller Y), row **1** toward the bottom.
## false → row **1** at top, row **5** at bottom (bases on row 5 sit lower on the PNG). `board3` uses false.
static var row_1_at_bottom: bool = false


static func cell_top_left_texture_px(cell: String) -> Vector2:
	var col := cell[0]
	var row := int(cell.substr(1, cell.length() - 1))
	var col_i := ord(col) - ord("A")
	var x := origin_b1_top_left.x + float(col_i - 1) * cell_px.x
	var y: float
	if row_1_at_bottom:
		y = origin_b1_top_left.y - float(row - 1) * cell_px.y
	else:
		y = origin_b1_top_left.y + float(row - 1) * cell_px.y
	return Vector2(x, y)


static func cell_center_texture_px(cell: String) -> Vector2:
	return cell_top_left_texture_px(cell) + cell_px * 0.5


## Position as child of Sprite2D (centered): local = texture px − half texture size.
static func cell_center_local(cell: String, texture_size: Vector2) -> Vector2:
	return cell_center_texture_px(cell) - texture_size * 0.5
