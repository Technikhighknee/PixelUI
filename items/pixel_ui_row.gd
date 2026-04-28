class_name PixelUIRow
extends PixelUIItem

## Horizontal flex layout. See REQUIREMENTS.md §5.7.
##
## Each entry in children is one of:
##   PixelUIItem                          → flex weight 1 (equal share)
##   {item: PixelUIItem, flex: float}     → proportional share of remaining space
##   {item: PixelUIItem, width: float}    → fixed pixel width
##
## Fixed-width entries are allocated first.
## Remaining space is distributed among flex entries proportionally.
## Invisible children (visible_when returning false) occupy zero width.


var children: Array = []


func height(style: PixelUIStyle, content_width: float) -> float:
	if children.is_empty():
		return 0.0
	var widths    := _compute_widths(content_width)
	var max_height: float = 0.0
	for i: int in children.size():
		var child := _item(children[i])
		if child.is_visible():
			max_height = maxf(max_height, child.height(style, widths[i]))
	return max_height


func _hit(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> bool:
	var widths  := _compute_widths(rect.size.x)
	var child_x := rect.position.x
	for i: int in children.size():
		var child := _item(children[i])
		if child.is_visible() and \
				child._hit(Rect2(child_x, rect.position.y, widths[i], rect.size.y), mouse, style):
			return true
		child_x += widths[i]
	return false


func _click(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> void:
	var widths  := _compute_widths(rect.size.x)
	var child_x := rect.position.x
	for i: int in children.size():
		var child      := _item(children[i])
		var child_rect := Rect2(child_x, rect.position.y, widths[i], rect.size.y)
		if child.is_visible() and child._hit(child_rect, mouse, style):
			child._click(child_rect, mouse, style)
			return
		child_x += widths[i]


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var widths  := _compute_widths(rect.size.x)
	var child_x := rect.position.x
	for i: int in children.size():
		var child := _item(children[i])
		if child.is_visible():
			child.render(canvas, style, font,
				Rect2(child_x, rect.position.y, widths[i], rect.size.y), mouse)
		child_x += widths[i]


func _item(entry: Variant) -> PixelUIItem:
	if entry is PixelUIItem: return entry as PixelUIItem
	return (entry as Dictionary)["item"] as PixelUIItem


func _compute_widths(total_w: float) -> Array[float]:
	var fixed_total: float = 0.0
	var flex_total:  float = 0.0
	for entry in children:
		if not _item(entry).is_visible(): continue
		if entry is PixelUIItem:
			flex_total += 1.0
		else:
			var dict := entry as Dictionary
			if dict.has("width"): fixed_total += float(dict["width"])
			else:                 flex_total  += float(dict.get("flex", 1.0))

	var flex_unit := maxf(total_w - fixed_total, 0.0) / flex_total if flex_total > 0.0 else 0.0

	var widths: Array[float] = []
	for entry in children:
		if not _item(entry).is_visible():
			widths.append(0.0)
			continue
		if entry is PixelUIItem:
			widths.append(flex_unit)
		else:
			var dict := entry as Dictionary
			widths.append(float(dict["width"]) if dict.has("width") \
				else float(dict.get("flex", 1.0)) * flex_unit)
	return widths
