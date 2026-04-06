@tool
class_name PawnMarker
extends Polygon2D
## Simple filled disc for pawns until you swap in art.
## @tool: polygon rebuilds in the editor so you see pawns under Board3.


@export var radius: float = 22.0:
	set(value):
		radius = value
		_rebuild_polygon()

@export var pawn_color: Color = Color.WHITE:
	set(value):
		pawn_color = value
		color = value


func _ready() -> void:
	_rebuild_polygon()


func _rebuild_polygon() -> void:
	var n := 20
	var pts: PackedVector2Array
	pts.resize(n)
	for i in n:
		var a := TAU * float(i) / float(n)
		pts[i] = Vector2(cos(a), sin(a)) * radius
	polygon = pts
	color = pawn_color


static func create(r: float, col: Color) -> PawnMarker:
	var p := PawnMarker.new()
	p.radius = r
	p.pawn_color = col
	p._rebuild_polygon()
	return p
