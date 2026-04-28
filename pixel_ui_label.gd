class_name PixelUILabel
extends PixelUIItem

## Text label — wraps automatically. Never truncates. See REQUIREMENTS.md §5.3.
##
## Text ALWAYS wraps to fit the allocated content width. The item grows
## vertically. height() uses Font.get_multiline_string_size() and render()
## uses draw_multiline_string(). The developer never calculates character counts.
##
## Variants:
##   BODY    — fs_body, col_text
##   HEADING — fs_small, col_heading, text forced to uppercase
##   HINT    — fs_small, col_hint


enum Variant { BODY, HEADING, HINT }

var variant:      Variant  = Variant.BODY

## Static text content. Overridden by text_getter when valid.
var text:         String   = ""
## Called every frame to produce display text. Overrides text.
var text_getter:  Callable

## Explicit colour. Color() (default-constructed) means "use style default".
var color:        Color    = Color()
## Called every frame to produce display colour. Overrides color.
var color_getter: Callable

## Text alignment within the item's allocated rect.
var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT


func height(style: PixelUIStyle, content_width: float) -> float:
	var label_text := _resolve_text()
	if label_text.is_empty():
		return style.line_height
	var font      := style.resolve_font(variant)
	var font_size := _font_size(style)
	var text_size := font.get_multiline_string_size(
		label_text, HORIZONTAL_ALIGNMENT_LEFT, content_width, font_size)
	return text_size.y + (style.line_height - font_size)


func render(canvas: CanvasItem, style: PixelUIStyle, _font: Font,
		rect: Rect2, _mouse: Vector2) -> void:
	var label_text := _resolve_text()
	if label_text.is_empty():
		return
	var font      := style.resolve_font(variant)
	var font_size := _font_size(style)
	var color     := _resolve_color(style)
	var baseline  := Vector2(rect.position.x, rect.position.y + font_size)
	canvas.draw_multiline_string(font, baseline, label_text,
		align, rect.size.x, font_size, -1, color)


func _resolve_text() -> String:
	var raw := text_getter.call() as String if text_getter.is_valid() else text
	return raw.to_upper() if variant == Variant.HEADING else raw


func _resolve_color(style: PixelUIStyle) -> Color:
	if color_getter.is_valid():
		return color_getter.call() as Color
	if color != Color():
		return color
	match variant:
		Variant.HEADING: return style.col_heading
		Variant.HINT:    return style.col_hint
		_:               return style.col_text


func _font_size(style: PixelUIStyle) -> int:
	return style.fs_small if variant != Variant.BODY else style.fs_body
