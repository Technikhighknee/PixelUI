class_name PixelUISep
extends PixelUIItem

## Separator line or blank spacer. See REQUIREMENTS.md §5.2.
##
## spacer_height == 0  →  horizontal rule drawn at vertical midpoint
## spacer_height  > 0  →  blank vertical space of that many virtual pixels


var spacer_height: float = 0.0


func height(style: PixelUIStyle, _content_width: float) -> float:
	return spacer_height if spacer_height > 0.0 else style.sep_height


func render(canvas: CanvasItem, style: PixelUIStyle, _font: Font,
		rect: Rect2, _mouse: Vector2) -> void:
	if spacer_height > 0.0:
		return
	var mid_y := rect.position.y + rect.size.y * 0.5
	canvas.draw_line(
		Vector2(rect.position.x,              mid_y),
		Vector2(rect.position.x + rect.size.x, mid_y),
		style.col_sep, 1.0
	)
