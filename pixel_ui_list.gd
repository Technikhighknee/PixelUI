class_name PixelUIList
extends PixelUIItem

## Virtual list — only renders visible items. See REQUIREMENTS.md §5.10.
## Use for large data sets (100+ items). The developer provides count + callbacks;
## PixelUIList renders only the slice currently visible in the scroll viewport.


var count:       Callable
var item_height: float    = 16.0
var draw_item:   Callable   # (canvas, index, rect, is_hovered)
var on_click:    Callable   # (index)
var max_height:  float    = 80.0
var show_bar:    bool     = true

var _scroll_offset: float = 0.0
var _hovered_idx:   int   = -1


func height(_style: PixelUIStyle, _content_width: float) -> float:
	return max_height


func _hit(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> bool:
	return rect.has_point(mouse)


func _click(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> void:
	var idx := _index_at(rect, mouse)
	if idx >= 0 and on_click.is_valid():
		on_click.call(idx)


func scroll_by(delta_px: float) -> void:
	var total_height := _count() * item_height
	_scroll_offset = clampf(_scroll_offset + delta_px, 0.0,
		maxf(total_height - max_height, 0.0))


func render(canvas: CanvasItem, style: PixelUIStyle, _font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	if not draw_item.is_valid(): return
	var total_count := _count()
	if total_count == 0: return

	var first_visible := int(_scroll_offset / item_height)
	var last_visible  := mini(first_visible + int(max_height / item_height) + 2, total_count)
	var item_w        := rect.size.x - (2.5 if show_bar else 0.0)

	_hovered_idx = _index_at(rect, mouse)

	for i: int in range(first_visible, last_visible):
		var item_y    := rect.position.y + i * item_height - _scroll_offset
		var item_rect := Rect2(rect.position.x, item_y, item_w, item_height)
		var is_hovered := (i == _hovered_idx)
		if is_hovered:
			canvas.draw_rect(item_rect, style.col_cell_hover)
		draw_item.call(canvas, i, item_rect, is_hovered)

	if show_bar:
		var total_height := float(total_count) * item_height
		if total_height > max_height:
			var bar_ratio := max_height / total_height
			var bar_h     := max_height * bar_ratio
			var bar_y     := rect.position.y + (_scroll_offset / total_height) * max_height
			canvas.draw_rect(
				Rect2(rect.position.x + rect.size.x - 2.0, bar_y, 1.5, bar_h),
				Color(style.col_text, 0.40))


func _count() -> int:
	return count.call() as int if count.is_valid() else 0


func _index_at(rect: Rect2, mouse: Vector2) -> int:
	if not rect.has_point(mouse): return -1
	var relative_y := mouse.y - rect.position.y + _scroll_offset
	var idx        := int(relative_y / item_height)
	return idx if idx >= 0 and idx < _count() else -1
