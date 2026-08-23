extends Object
class_name PixelUI
# Crisp 8x8 bitmap font for HUD / menus.

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/pixel.fnt") as Font
	return _font


static func stamp(ctrl: Control, size: int = 8) -> void:
	var f := font()
	if f != null:
		ctrl.add_theme_font_override("font", f)
		ctrl.add_theme_font_size_override("font_size", size)
	ctrl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
