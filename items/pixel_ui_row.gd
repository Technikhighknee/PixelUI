class_name PixelUIRow
extends PixelUIItem

## Horizontal flex layout. See REQUIREMENTS.md §5.7.
##
## Each entry in children is one of:
##   PixelUIItem              → flex weight 1 (equal share)
##   RowChild (width >= 0)    → fixed pixel width
##   RowChild (width < 0)     → proportional flex share by weight
##
## Use PixelUI.make_fixed() and PixelUI.make_flex() to build RowChild values.
## Fixed children are allocated first; flex children share remaining space.
## Invisible children contribute zero width.


class RowChild:
	var item:   PixelUIItem
	var width:  float  ## >= 0 = fixed px; -1.0 = flex
	var weight: float  ## flex share, used only when width < 0

	func _init(i: PixelUIItem, w: float, wt: float = 1.0) -> void:
		item = i; width = w; weight = wt


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
	return (entry as RowChild).item


func _compute_widths(total_w: float) -> Array[float]:
	var fixed_total: float = 0.0
	var flex_total:  float = 0.0
	for entry: Variant in children:
		if not _item(entry).is_visible(): continue
		if entry is PixelUIItem:
			flex_total += 1.0
		else:
			var rc := entry as RowChild
			if rc.width >= 0.0: fixed_total += rc.width
			else:               flex_total  += rc.weight

	var flex_unit := maxf(total_w - fixed_total, 0.0) / flex_total if flex_total > 0.0 else 0.0

	var widths: Array[float] = []
	for entry: Variant in children:
		if not _item(entry).is_visible():
			widths.append(0.0)
			continue
		if entry is PixelUIItem:
			widths.append(flex_unit)
		else:
			var rc := entry as RowChild
			widths.append(rc.width if rc.width >= 0.0 else rc.weight * flex_unit)
	return widths
