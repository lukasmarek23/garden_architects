extends RefCounted
## Shared menu / character-select styling. Use: const T = preload("res://scripts/ui_menu_theme.gd")
## Do not use class_name here (avoids global registration issues on some setups).

const FONT_HEADING_PATH := "res://fonts/NotoSans-Bold.ttf"
const FONT_BODY_PATH := "res://fonts/Sniglet-Regular.ttf"
const FONT_HEADING_FALLBACK := "res://fonts/NotoSans-Bold.ttf"
const FONT_BODY_FALLBACK := "res://fonts/NotoSans-Regular.ttf"

const BG_TOP := Color(0.96, 0.93, 0.84, 1.0)
const BG_BOTTOM := Color(0.82, 0.74, 0.58, 1.0)
const ACCENT_GOLD := Color(0.92, 0.78, 0.28, 1.0)
const ACCENT_MOSS := Color(0.28, 0.48, 0.32, 1.0)
const ACCENT_CREAM := Color(0.99, 0.96, 0.88, 1.0)
const TEXT_DARK := Color(0.22, 0.18, 0.12, 1.0)


static func load_heading_font() -> Font:
	var f: Font = load(FONT_HEADING_PATH) as Font
	if f == null:
		f = load(FONT_HEADING_FALLBACK) as Font
	return f


static func load_body_font() -> Font:
	var f: Font = load(FONT_BODY_PATH) as Font
	if f == null:
		f = load(FONT_BODY_FALLBACK) as Font
	return f


static func make_gradient_background() -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, BG_TOP)
	grad.set_color(1, BG_BOTTOM)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 256
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	return tr


static func add_plant_corners(parent: Control) -> void:
	var tex := load("res://art/plants/strawberry.png") as Texture2D
	if tex == null:
		return
	var layer := Control.new()
	layer.layout_mode = 1
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = -3
	parent.add_child(layer)
	_plant_corner(layer, tex, true)
	_plant_corner(layer, tex, false)


static func _plant_corner(layer: Control, tex: Texture2D, left: bool) -> void:
	var tr := TextureRect.new()
	tr.layout_mode = 1
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color(1, 1, 1, 0.14)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if left:
		tr.anchor_left = 0.0
		tr.anchor_right = 0.0
		tr.anchor_top = 0.12
		tr.anchor_bottom = 0.12
		tr.offset_left = -90.0
		tr.offset_top = -40.0
		tr.offset_right = 320.0
		tr.offset_bottom = 360.0
		tr.grow_horizontal = Control.GROW_DIRECTION_END
	else:
		tr.anchor_left = 1.0
		tr.anchor_right = 1.0
		tr.anchor_top = 0.08
		tr.anchor_bottom = 0.08
		tr.offset_left = -310.0
		tr.offset_top = 0.0
		tr.offset_right = 90.0
		tr.offset_bottom = 400.0
		tr.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	layer.add_child(tr)


static func style_heading_label(l: Label) -> void:
	var fh := load_heading_font()
	if fh != null:
		l.add_theme_font_override("font", fh)
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", ACCENT_CREAM)
	l.add_theme_color_override("font_outline_color", ACCENT_MOSS)
	l.add_theme_constant_override("outline_size", 10)
	l.add_theme_color_override("font_shadow_color", Color(0.45, 0.22, 0.12, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 4)
	l.add_theme_constant_override("shadow_offset_y", 4)


static func style_subheading_label(l: Label) -> void:
	var fh := load_heading_font()
	if fh != null:
		l.add_theme_font_override("font", fh)
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", ACCENT_GOLD)
	l.add_theme_color_override("font_outline_color", ACCENT_MOSS)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_shadow_color", Color(0.35, 0.2, 0.1, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 3)
	l.add_theme_constant_override("shadow_offset_y", 3)


static func style_body_label(l: Label, font_px: int = 17) -> void:
	var fb := load_body_font()
	if fb != null:
		l.add_theme_font_override("font", fb)
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", TEXT_DARK)


static func style_menu_button(b: Button) -> void:
	var fb := load_body_font()
	if fb != null:
		b.add_theme_font_override("font", fb)
	b.add_theme_font_size_override("font_size", 22)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.94, 0.88, 0.72, 1.0)
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(3)
	normal.border_color = ACCENT_MOSS
	normal.set_content_margin_all(14)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.99, 0.94, 0.78, 1.0)
	hover.set_corner_radius_all(14)
	hover.set_border_width_all(3)
	hover.border_color = ACCENT_GOLD
	hover.set_content_margin_all(14)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.85, 0.78, 0.62, 1.0)
	pressed.set_corner_radius_all(14)
	pressed.set_border_width_all(3)
	pressed.border_color = ACCENT_MOSS
	pressed.set_content_margin_all(14)
	var focus_sb := hover.duplicate() as StyleBoxFlat
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus_sb)
	b.add_theme_color_override("font_color", TEXT_DARK)
	b.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.05, 1.0))
	b.add_theme_color_override("font_pressed_color", TEXT_DARK)
	b.add_theme_color_override("font_focus_color", Color(0.05, 0.05, 0.05, 1.0))


static func style_panel_flat(inner: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.95, 0.88, 0.96) if inner else Color(0.96, 0.91, 0.80, 0.98)
	s.set_corner_radius_all(16)
	s.set_border_width_all(4)
	s.border_color = ACCENT_MOSS
	s.set_content_margin_all(22)
	s.shadow_color = Color(0, 0, 0, 0.18)
	s.shadow_size = 6
	return s


static func style_menu_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1.0, 0.98, 0.94, 0.42)
	s.set_corner_radius_all(22)
	s.set_border_width_all(3)
	s.border_color = Color(ACCENT_MOSS.r, ACCENT_MOSS.g, ACCENT_MOSS.b, 0.55)
	s.set_content_margin_all(32)
	s.shadow_color = Color(0, 0, 0, 0.12)
	s.shadow_size = 8
	return s
