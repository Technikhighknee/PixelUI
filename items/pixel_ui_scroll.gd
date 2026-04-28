class_name PixelUIScroll
extends PixelUIItem

## Scrollable container. See REQUIREMENTS.md §5.8.
## height() always returns max_height — the scroll area has a fixed visible height.
## Mouse wheel scrolls when _hit() is true.


var children:   Array = []
var max_height: float = 80.0
var show_bar:   bool  = true

var _scroll_offset: float = 0.0


func height(_style: PixelUIStyle, _content_width: float) -> float:
	return max_height


func _hit(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> bool:
	return rect.has_point(mouse)


func _click(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> void:
	if not rect.has_point(mouse): return
	var child_w := content_width(rect.size.x)
	var child_y := rect.position.y - _scroll_offset
	for item: PixelUIItem in children:
		if not item.is_visible(): continue
		var item_height := item.height(style, child_w)
		var child_rect  := Rect2(rect.position.x, child_y, child_w, item_height)
		if child_y + item_height > rect.position.y and child_y < rect.position.y + max_height:
			if item._hit(child_rect, mouse, style):
				item._click(child_rect, mouse, style)
				return
		child_y += item_height + style.item_gap


func scroll_by(delta_px: float, style: PixelUIStyle, content_w: float) -> void:
	var total_height := _total_height(style, content_w)
	var max_offset   := maxf(total_height - max_height, 0.0)
	_scroll_offset = clampf(_scroll_offset + delta_px, 0.0, max_offset)


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var child_w := content_width(rect.size.x)
	var child_y := rect.position.y - _scroll_offset

	for item: PixelUIItem in children:
		if not item.is_visible(): continue
		var item_height := item.height(style, child_w)
		var child_rect  := Rect2(rect.position.x, child_y, child_w, item_height)
		if child_y + item_height > rect.position.y and child_y < rect.position.y + max_height:
			item.render(canvas, style, font, child_rect, mouse)
		child_y += item_height + style.item_gap

	if show_bar:
		var total_height := _total_height(style, child_w)
		if total_height > max_height:
			var bar_x     := rect.position.x + rect.size.x - 2.0
			var bar_ratio := max_height / total_height
			var bar_h     := max_height * bar_ratio
			var bar_y     := rect.position.y + (_scroll_offset / total_height) * max_height
			canvas.draw_rect(Rect2(bar_x, bar_y, 1.5, bar_h),
				Color(style.col_text, 0.40))


func _total_height(style: PixelUIStyle, child_w: float) -> float:
	var total         := 0.0
	var visible_count := 0
	for item: PixelUIItem in children:
		if not item.is_visible(): continue
		total += item.height(style, child_w)
		visible_count += 1
	if visible_count > 1:
		total += style.item_gap * (visible_count - 1)
	return total


## Returns the available width for child items, accounting for the scrollbar.
func content_width(panel_w: float) -> float:
	return panel_w - (2.5 if show_bar else 0.0)
