class_name PixelUICustom
extends PixelUIItem

## Arbitrary draw content. See REQUIREMENTS.md §5.12.
##
## draw_fn: Callable(canvas: CanvasItem, rect: Rect2, mouse: Vector2) → void
##   canvas — the PixelUI Node2D. Call any draw_* method on it.
##   rect   — the exact area allocated to this item in virtual pixels.
##   mouse  — current mouse position in virtual pixels.
##
## click_fn is optional. When provided, the item is interactive.


var item_height: float    = 32.0
var draw_fn:     Callable
var click_fn:    Callable


func height(_style: PixelUIStyle, _content_width: float) -> float:
	return item_height


func _hit(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> bool:
	return click_fn.is_valid() and rect.has_point(mouse)


func _click(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> void:
	if click_fn.is_valid():
		click_fn.call(rect, mouse)


func render(canvas: CanvasItem, _style: PixelUIStyle, _font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	if draw_fn.is_valid():
		draw_fn.call(canvas, rect, mouse)
