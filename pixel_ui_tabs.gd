class_name PixelUITabs
extends PixelUIItem

## Tab / page switcher. See REQUIREMENTS.md §5.11.
## height() = tab row height + height of active page content.
## Only the active page's items are rendered and included in height.


var tabs:          Array[String] = []
var active_tab:    int           = 0
var on_tab_change: Callable
var pages:         Array         = []


func page(items: Array) -> PixelUITabs:
	pages.append(items)
	return self


func height(style: PixelUIStyle, content_width: float) -> float:
	return style.btn_height + _page_height(style, content_width)


func _hit(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> bool:
	if _tab_bar_rect(rect, style).has_point(mouse): return true
	if _page_items().is_empty(): return false
	var page_rect  := _page_rect(rect, style)
	var page_width := page_rect.size.x
	var item_y     := page_rect.position.y
	for item: PixelUIItem in _page_items():
		if not item.is_visible(): continue
		var item_height := item.height(style, page_width)
		if item._hit(Rect2(page_rect.position.x, item_y, page_width, item_height), mouse, style):
			return true
		item_y += item_height + style.item_gap
	return false


func _click(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> void:
	var tab_bar := _tab_bar_rect(rect, style)
	if tab_bar.has_point(mouse):
		var tab_w := tab_bar.size.x / float(maxi(tabs.size(), 1))
		var idx: int = clamp(int((mouse.x - tab_bar.position.x) / tab_w), 0, tabs.size() - 1)
		if idx != active_tab:
			active_tab = idx
			if on_tab_change.is_valid(): on_tab_change.call(active_tab)
		return
	var page_rect  := _page_rect(rect, style)
	var page_width := page_rect.size.x
	var item_y     := page_rect.position.y
	for item: PixelUIItem in _page_items():
		if not item.is_visible(): continue
		var item_height := item.height(style, page_width)
		var child_rect  := Rect2(page_rect.position.x, item_y, page_width, item_height)
		if item._hit(child_rect, mouse, style):
			item._click(child_rect, mouse, style)
			return
		item_y += item_height + style.item_gap


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var tab_bar := _tab_bar_rect(rect, style)
	var tab_w   := tab_bar.size.x / float(maxi(tabs.size(), 1))

	for i: int in tabs.size():
		var tab_rect   := Rect2(tab_bar.position.x + i * tab_w, tab_bar.position.y,
			tab_w, style.btn_height)
		var is_active  := (i == active_tab)
		var is_hovered := tab_rect.has_point(mouse)
		var bg_color   := style.col_on_bg if is_active else \
			(style.col_btn_hover if is_hovered else style.col_btn_bg)
		canvas.draw_rect(tab_rect, bg_color)
		canvas.draw_rect(tab_rect, style.col_btn_bd, false, 1.0)
		var font_size  := style.fs_body
		var text_y     := tab_rect.position.y + font_size + (style.btn_height - font_size) * 0.5 - 1.0
		var text_color := style.col_on if is_active else style.col_text
		canvas.draw_string(font, Vector2(tab_rect.position.x, text_y),
			fit_text(font, tabs[i], font_size, tab_w - 4.0),
			HORIZONTAL_ALIGNMENT_CENTER, tab_w, font_size, text_color)

	var page_rect  := _page_rect(rect, style)
	var page_width := page_rect.size.x
	var item_y     := page_rect.position.y
	for item: PixelUIItem in _page_items():
		if not item.is_visible(): continue
		var item_height := item.height(style, page_width)
		item.render(canvas, style, font,
			Rect2(page_rect.position.x, item_y, page_width, item_height), mouse)
		item_y += item_height + style.item_gap


func _tab_bar_rect(panel_rect: Rect2, style: PixelUIStyle) -> Rect2:
	return Rect2(panel_rect.position.x, panel_rect.position.y,
		panel_rect.size.x, style.btn_height)


func _page_rect(panel_rect: Rect2, style: PixelUIStyle) -> Rect2:
	return Rect2(panel_rect.position.x,
		panel_rect.position.y + style.btn_height + style.item_gap,
		panel_rect.size.x, 0.0)


func _page_items() -> Array:
	if active_tab < 0 or active_tab >= pages.size():
		return []
	return pages[active_tab] as Array


func _page_height(style: PixelUIStyle, content_width: float) -> float:
	var items         := _page_items()
	if items.is_empty(): return 0.0
	var total         := 0.0
	var visible_count := 0
	for item: PixelUIItem in items:
		if not item.is_visible(): continue
		total += item.height(style, content_width)
		visible_count += 1
	if visible_count > 1:
		total += style.item_gap * (visible_count - 1)
	return total
