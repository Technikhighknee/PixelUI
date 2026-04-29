class_name PixelUI
extends Node2D

## Lightweight pixel-exact UI library for Godot 4.
## See REQUIREMENTS.md for the full specification.
##
## ── Retained mode (stable panels) ────────────────────────────────────────────
##
##   var layer := CanvasLayer.new()
##   layer.layer = 20
##   add_child(layer)
##
##   var ui := PixelUI.new(72.0)
##   layer.add_child(ui)
##   ui.heading("MY PANEL").separator()
##   ui.button("Click me", func(): do_thing())
##   ui.toggle("God mode", func(on: bool): god = on)
##   ui.label_live(func() -> String: return "HP: %d" % hp)
##   ui.row([
##       ui.make_fixed(ui.make_button("−", fn_minus), 14.0),
##       ui.make_label_live(func() -> String: return str(depth)),
##       ui.make_fixed(ui.make_button("+", fn_plus),  14.0),
##   ])
##   ui.center()   # call AFTER adding all items
##
## ── Immediate mode (dev tools, dynamic structure) ─────────────────────────────
##
##   See PixelUIIM (pixel_ui_im.gd) for the immediate mode API.
##
##   func _process(_delta: float) -> void:
##       PixelUIIM.begin("hud", Vector2(4, 4), 80.0, get_tree())
##       PixelUIIM.text("FPS: %d" % Engine.get_frames_per_second())
##       if PixelUIIM.button("Reset"): game.reset()
##       PixelUIIM.end()
##
## ── Layout report (debug / AI verification) ───────────────────────────────────
##
##   print(ui.layout_report())    # full text description of rendered layout
##   print(ui.ascii_render())     # rough ASCII art of the panel


# ── Corner constants for anchor() ─────────────────────────────────────────────
const CORNER_TL: int = 0
const CORNER_TR: int = 1
const CORNER_BL: int = 2
const CORNER_BR: int = 3

# ── Edge constants for slide_in() ─────────────────────────────────────────────
const EDGE_LEFT:   int = 0
const EDGE_RIGHT:  int = 1
const EDGE_TOP:    int = 2
const EDGE_BOTTOM: int = 3


# ── Instance state ────────────────────────────────────────────────────────────

## Override to apply a custom visual theme.
var style: PixelUIStyle = PixelUIStyle.new()

var _width:       float      = 80.0
var _items:       Array      = []     # Array[PixelUIItem]
var _warned:      Dictionary = {}     # warning string → true; prevents repeat spam
var _show_bg:     bool   = true
var _modal_dim:   float  = 0.0
var _mouse:       Vector2 = Vector2(-9999.0, -9999.0)
## Rebuilt every _draw(). Used by _input() for hit-testing.
var _draw_cache:  Array  = []     # Array[{item, rect}]
## Keyboard navigation
var _kb_nav:      bool   = false
var _focus_idx:   int    = -1
## Drag state
var _drag_item:   PixelUIItem = null
var _drag_rect:   Rect2


func _init(panel_width: float = 80.0) -> void:
	_width = panel_width


func _ready() -> void:
	set_process_input(true)


func _process(_delta: float) -> void:
	if not visible: return
	_mouse = get_viewport().get_mouse_position()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible: return

	# Drag motion
	if _drag_item != null and event is InputEventMouseMotion:
		_drag_item._drag(_drag_rect, _mouse, style)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var me := event as InputEventMouseButton
		if me.button_index == MOUSE_BUTTON_LEFT:
			if me.pressed:
				_handle_left_click(_mouse)
			elif _drag_item != null:
				_drag_item = null  # end drag
		elif me.pressed:
			_handle_scroll(me)
		return

	if _kb_nav and event is InputEventKey:
		_handle_key(event as InputEventKey)
		return

	# Hotkey scan
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			_check_hotkeys(ke.keycode)


func _draw() -> void:
	_draw_cache.clear()
	var font        := style.resolve_font(PixelUILabel.Variant.BODY)
	var content_w   := _width - style.padding * 2.0

	if _modal_dim > 0.0:
		draw_rect(Rect2(-position, style.viewport_size),
			Color(0.0, 0.0, 0.0, _modal_dim))

	var visible_items: Array[PixelUIItem] = []
	var heights:       Array[float]       = []
	for item: PixelUIItem in _items:
		if not item.is_visible(): continue
		visible_items.append(item)
		heights.append(item.height(style, content_w))

	var total_height := style.padding * 2.0
	for item_height: float in heights:
		total_height += item_height + style.item_gap
	if not heights.is_empty():
		total_height -= style.item_gap

	if _show_bg:
		draw_rect(Rect2(0.0, 0.0, _width, total_height), style.col_bg)
		draw_rect(Rect2(0.0, 0.0, _width, total_height), style.col_border, false, 1.0)

	var content_x := style.padding
	var cursor_y  := style.padding
	for i: int in visible_items.size():
		var item := visible_items[i]
		var rect := Rect2(content_x, cursor_y, content_w, heights[i])
		_draw_cache.append({"item": item, "rect": rect})
		item.render(self, style, font, rect, _mouse)
		if _kb_nav and _focus_idx == _cache_index_of(item):
			draw_rect(rect.grow(1.0), style.col_focus, false, 1.0)
		cursor_y += heights[i] + style.item_gap

	if OS.is_debug_build():
		_emit_warnings()


# ── Input helpers ─────────────────────────────────────────────────────────────

func _handle_left_click(mouse: Vector2) -> void:
	for entry: Dictionary in _draw_cache:
		var item := entry["item"] as PixelUIItem
		var rect := entry["rect"] as Rect2
		if item._hit(rect, mouse, style):
			if item._is_draggable():
				_drag_item = item
				_drag_rect = rect
			else:
				item._click(rect, mouse, style)
			get_viewport().set_input_as_handled()
			return


func _handle_scroll(me: InputEventMouseButton) -> void:
	for entry: Dictionary in _draw_cache:
		var item := entry["item"] as PixelUIItem
		var rect := entry["rect"] as Rect2
		if not rect.has_point(_mouse): continue
		var line_h := style.line_height * 3.0
		if item is PixelUIScroll:
			var s_item := item as PixelUIScroll
			s_item.scroll_by(
				line_h if me.button_index == MOUSE_BUTTON_WHEEL_DOWN else -line_h,
				style, s_item.content_width(rect.size.x))
			get_viewport().set_input_as_handled()
			return
		if item is PixelUIList:
			(item as PixelUIList).scroll_by(
				line_h if me.button_index == MOUSE_BUTTON_WHEEL_DOWN else -line_h)
			get_viewport().set_input_as_handled()
			return


func _handle_key(ke: InputEventKey) -> void:
	if not ke.pressed or ke.echo: return
	var interactive := _interactive_items()
	if interactive.is_empty(): return
	match ke.keycode:
		KEY_TAB:
			var dir := -1 if ke.shift_pressed else 1
			_focus_idx = (_focus_idx + dir) % interactive.size()
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_SPACE:
			if _focus_idx >= 0 and _focus_idx < interactive.size():
				var entry := interactive[_focus_idx] as Dictionary
				(entry["item"] as PixelUIItem)._click(
					entry["rect"] as Rect2, _mouse, style)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()


func _interactive_items() -> Array:
	var out := []
	for entry: Dictionary in _draw_cache:
		if entry["item"] is PixelUIButton or \
				entry["item"] is PixelUISlider or \
				entry["item"] is PixelUIGrid:
			out.append(entry)
	return out


func _check_hotkeys(keycode: Key) -> void:
	for entry: Dictionary in _draw_cache:
		var item := entry["item"] as PixelUIItem
		if item is PixelUIButton:
			var button := item as PixelUIButton
			if button.hotkey == keycode:
				button._click(entry["rect"] as Rect2, _mouse, style)
				get_viewport().set_input_as_handled()
				return


func _cache_index_of(item: PixelUIItem) -> int:
	for i: int in _draw_cache.size():
		if _draw_cache[i]["item"] == item:
			return i
	return -1


# ── Positioning ───────────────────────────────────────────────────────────────

## Center panel in style.viewport_size. Call AFTER adding all items.
func center() -> PixelUI:
	var panel_height := _compute_height()
	position = ((style.viewport_size - Vector2(_width, panel_height)) * 0.5).floor()
	return self


## Position at an explicit virtual-pixel coordinate.
func at(pos: Vector2) -> PixelUI:
	position = pos
	return self


## Anchor to a screen corner. Use CORNER_TL / CORNER_TR / CORNER_BL / CORNER_BR.
func anchor(corner: int, margin: float = 4.0) -> PixelUI:
	var viewport_size := style.viewport_size
	var panel_height  := _compute_height()
	match corner:
		CORNER_TL: position = Vector2(margin,                            margin)
		CORNER_TR: position = Vector2(viewport_size.x - _width - margin, margin)
		CORNER_BL: position = Vector2(margin,                            viewport_size.y - panel_height - margin)
		CORNER_BR: position = Vector2(viewport_size.x - _width - margin, viewport_size.y - panel_height - margin)
	return self


# ── Appearance ────────────────────────────────────────────────────────────────

func with_background(show: bool) -> PixelUI:
	_show_bg = show
	return self


## Draw a full-screen dim overlay behind this panel.
func modal(alpha: float = 0.5) -> PixelUI:
	_modal_dim = alpha
	return self


func set_panel_width(w: float) -> PixelUI:
	_width = w
	return self


## Slide the panel in from an edge. Call after positioning.
func slide_in(edge: int = EDGE_LEFT, duration: float = 0.18) -> PixelUI:
	var viewport_size := style.viewport_size
	var start_pos     := position
	match edge:
		EDGE_LEFT:   start_pos.x = -_width
		EDGE_RIGHT:  start_pos.x = viewport_size.x
		EDGE_TOP:    start_pos.y = -_compute_height()
		EDGE_BOTTOM: start_pos.y = viewport_size.y
	var target_pos := position
	position = start_pos
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return self


## Fade the panel in.
func fade_in(duration: float = 0.15) -> PixelUI:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return self


# ── Panel management ──────────────────────────────────────────────────────────

func clear() -> PixelUI:
	_items.clear()
	_warned.clear()
	return self


## Append a pre-built item to the panel. Useful for tabs and other complex items
## created with make_* factories that need post-construction configuration.
func add_item(item: PixelUIItem) -> PixelUI:
	_items.append(item)
	return self


## Clear and repopulate. fn() is called with no arguments.
func rebuild(fn: Callable) -> PixelUI:
	clear()
	fn.call()
	return self


func enable_keyboard_nav() -> PixelUI:
	_kb_nav = true
	_focus_idx = 0
	return self


# ── Builder — text ────────────────────────────────────────────────────────────

func heading(text: String) -> PixelUI:
	_items.append(make_heading(text))
	return self

func label(text: String, col: Color = Color()) -> PixelUI:
	_items.append(make_label(text, col))
	return self

func label_live(getter: Callable, col: Color = Color()) -> PixelUI:
	_items.append(make_label_live(getter, col))
	return self

func label_colored(text_getter: Callable, color_getter: Callable) -> PixelUI:
	_items.append(make_label_colored(text_getter, color_getter))
	return self

func hint(text: String) -> PixelUI:
	_items.append(make_hint(text))
	return self


# ── Builder — layout ──────────────────────────────────────────────────────────

func separator() -> PixelUI:
	_items.append(PixelUISep.new())
	return self

func spacing(height: float = 4.0) -> PixelUI:
	_items.append(make_spacer(height))
	return self

func row(children: Array) -> PixelUI:
	_items.append(make_row(children))
	return self


# ── Builder — interactive ─────────────────────────────────────────────────────

func button(text: String, on_press: Callable) -> PixelUI:
	_items.append(make_button(text, on_press))
	return self

func button_live(getter: Callable, on_press: Callable) -> PixelUI:
	_items.append(make_button_live(getter, on_press))
	return self

func toggle(text: String, on_change: Callable, initial: bool = false) -> PixelUI:
	_items.append(make_toggle(text, on_change, initial))
	return self

func toggle_ext(text: String, active_getter: Callable, on_press: Callable) -> PixelUI:
	_items.append(make_toggle_ext(text, active_getter, on_press))
	return self

func slider(min_v: float, max_v: float, value: float, on_change: Callable) -> PixelUI:
	_items.append(make_slider(min_v, max_v, value, on_change))
	return self

func bar(value_getter: Callable, color_getter: Callable = Callable()) -> PixelUI:
	_items.append(make_bar(value_getter, color_getter))
	return self


# ── Builder — complex ─────────────────────────────────────────────────────────

func scroll(children: Array, max_h: float) -> PixelUI:
	_items.append(make_scroll(children, max_h))
	return self

func grid(cols: int, rows: int, cell_size: float,
		draw_cell: Callable = Callable(),
		click_fn:  Callable = Callable(),
		hover_fn:  Callable = Callable()) -> PixelUI:
	_items.append(make_grid(cols, rows, cell_size, draw_cell, click_fn, hover_fn))
	return self

func list(count: Callable, item_height: float, draw_fn: Callable,
		click_fn: Callable = Callable(), max_h: float = 80.0) -> PixelUI:
	_items.append(make_list(count, item_height, draw_fn, click_fn, max_h))
	return self

## Add a tab switcher. Use make_tabs() + add_item() if you need a reference
## to configure pages after creation.
func tabs(labels: Array[String], on_change: Callable) -> PixelUI:
	_items.append(make_tabs(labels, on_change))
	return self

func custom(height: float, draw_fn: Callable,
		click_fn: Callable = Callable()) -> PixelUI:
	_items.append(make_custom(height, draw_fn, click_fn))
	return self


# ── Factories ─────────────────────────────────────────────────────────────────

func make_heading(text: String) -> PixelUILabel:
	var item    := PixelUILabel.new()
	item.text    = text
	item.variant = PixelUILabel.Variant.HEADING
	return item

func make_label(text: String, col: Color = Color()) -> PixelUILabel:
	var item := PixelUILabel.new()
	item.text = text
	if col != Color(): item.color = col
	return item

func make_label_live(getter: Callable, col: Color = Color()) -> PixelUILabel:
	var item         := PixelUILabel.new()
	item.text_getter  = getter
	if col != Color(): item.color = col
	return item

func make_label_colored(text_getter: Callable, color_getter: Callable) -> PixelUILabel:
	var item          := PixelUILabel.new()
	item.text_getter   = text_getter
	item.color_getter  = color_getter
	return item

func make_hint(text: String) -> PixelUILabel:
	var item    := PixelUILabel.new()
	item.text    = text
	item.variant = PixelUILabel.Variant.HINT
	return item

func make_spacer(height: float = 4.0) -> PixelUISep:
	var item         := PixelUISep.new()
	item.spacer_height = height
	return item

func make_row(children: Array) -> PixelUIRow:
	var r     := PixelUIRow.new()
	r.children = children
	return r


## Convenience: wrap an item with a fixed pixel width for use in row().
## ui.row([ui.make_fixed(btn, 14.0), label, ui.make_fixed(btn, 14.0)])
func make_fixed(item: PixelUIItem, width: float) -> Dictionary:
	return {item = item, width = width}


## Convenience: wrap an item with a proportional flex weight for use in row().
## Omit weight to get the default flex share of 1.0.
func make_flex(item: PixelUIItem, weight: float = 1.0) -> Dictionary:
	return {item = item, flex = weight}

func make_button(text: String, on_press: Callable) -> PixelUIButton:
	var item     := PixelUIButton.new()
	item.text     = text
	item.on_press = on_press
	return item

func make_button_live(getter: Callable, on_press: Callable) -> PixelUIButton:
	var item         := PixelUIButton.new()
	item.text_getter  = getter
	item.on_press     = on_press
	return item

func make_toggle(text: String, on_change: Callable,
		initial: bool = false) -> PixelUIButton:
	var item      := PixelUIButton.new()
	item.text      = text
	item.on_press  = on_change
	item.is_toggle = true
	item.active    = initial
	return item

func make_toggle_ext(text: String, active_getter: Callable,
		on_press: Callable) -> PixelUIButton:
	var item           := PixelUIButton.new()
	item.text           = text
	item.on_press       = on_press
	item.is_toggle      = true
	item.active_getter  = active_getter
	return item

func make_slider(min_v: float, max_v: float, value: float,
		on_change: Callable) -> PixelUISlider:
	var item     := PixelUISlider.new()
	item.min_val  = min_v
	item.max_val  = max_v
	item.value    = value
	item.on_change = on_change
	return item

func make_bar(value_getter: Callable,
		color_getter: Callable = Callable()) -> PixelUIBar:
	var item        := PixelUIBar.new()
	item.value_getter = value_getter
	item.color_getter = color_getter
	return item

func make_scroll(children: Array, max_h: float) -> PixelUIScroll:
	var item       := PixelUIScroll.new()
	item.children   = children
	item.max_height = max_h
	return item

func make_grid(cols: int, rows: int, cell_size: float,
		draw_cell: Callable = Callable(),
		click_fn:  Callable = Callable(),
		hover_fn:  Callable = Callable()) -> PixelUIGrid:
	var item      := PixelUIGrid.new()
	item.cols      = cols
	item.rows      = rows
	item.cell_size = cell_size
	item.draw_cell = draw_cell
	item.on_click  = click_fn
	item.on_hover  = hover_fn
	return item

func make_list(count: Callable, item_height: float, draw_fn: Callable,
		click_fn: Callable = Callable(), max_h: float = 80.0) -> PixelUIList:
	var item        := PixelUIList.new()
	item.count       = count
	item.item_height = item_height
	item.draw_item   = draw_fn
	item.on_click    = click_fn
	item.max_height  = max_h
	return item

func make_tabs(labels: Array[String], on_change: Callable) -> PixelUITabs:
	var item          := PixelUITabs.new()
	item.tabs          = labels
	item.on_tab_change = on_change
	return item

func make_custom(height: float, draw_fn: Callable,
		click_fn: Callable = Callable()) -> PixelUICustom:
	var item        := PixelUICustom.new()
	item.item_height = height
	item.draw_fn     = draw_fn
	item.click_fn    = click_fn
	return item


# ── Layout report (§10) ───────────────────────────────────────────────────────

## Full text description of the last rendered layout.
## Paste to an AI or log to verify layout correctness.
func layout_report() -> String:
	if _draw_cache.is_empty():
		return "Panel not yet drawn."
	var content_w    := _width - style.padding * 2.0
	var panel_height := _compute_height()
	var report       := "Panel %.0f×%.0fpx at (%.0f,%.0f)\n" % \
		[_width, panel_height, position.x, position.y]
	var warnings: Array[String] = []

	for i: int in _draw_cache.size():
		var entry     := _draw_cache[i] as Dictionary
		var item      := entry["item"] as PixelUIItem
		var rect      := entry["rect"] as Rect2
		var prefix    := "└" if i == _draw_cache.size() - 1 else "├"
		var type_name := _item_type_name(item)
		var content   := _item_content_preview(item)
		var status    := _item_status(item, style, content_w, warnings)
		report += "%s %-18s %-24s (%.0f,%.0f %.0f×%.0f) %s\n" % \
			[prefix, type_name, content,
			 rect.position.x, rect.position.y, rect.size.x, rect.size.y,
			 status]

	if warnings.is_empty():
		report += "\nWARNINGS: none"
	else:
		report += "\nWARNINGS:\n"
		for warning: String in warnings:
			report += "  %s\n" % warning
	return report


## Rough ASCII art panel representation.
func ascii_render() -> String:
	if _draw_cache.is_empty():
		return "(not yet drawn)"
	var cols     := 30
	var inner    := cols - 2
	var top      := "┌" + "─".repeat(cols - 2) + "┐"
	var bot      := "└" + "─".repeat(cols - 2) + "┘"
	var sep_line := "├" + "─".repeat(cols - 2) + "┤"
	var out      := top + "\n"

	for entry: Dictionary in _draw_cache:
		var item := entry["item"] as PixelUIItem
		if item is PixelUISep:
			var sp := item as PixelUISep
			out += (sep_line if sp.spacer_height == 0.0 else \
				"│" + " ".repeat(inner) + "│") + "\n"
		else:
			var preview := _ascii_item_preview(item)
			var padded  := preview.left(inner)
			padded      = padded + " ".repeat(maxi(inner - padded.length(), 0))
			out += "│" + padded + "│\n"

	out += bot
	return out


# ── Static utilities (§11) ────────────────────────────────────────────────────

## Show a temporary toast notification. Fades in, holds, fades out, self-destructs.
static func toast(scene_tree: SceneTree, text: String,
		col: Color = Color(0.85, 0.85, 0.92),
		duration: float = 2.0) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 99
	scene_tree.current_scene.add_child(layer)

	var ui := PixelUI.new(160.0)
	ui.style = PixelUIStyle.minimal()
	layer.add_child(ui)
	ui.label(text, col)
	ui.center()
	ui.position.y = ui.style.viewport_size.y * 0.75

	ui.modulate.a = 0.0
	var tween := ui.create_tween()
	tween.tween_property(ui, "modulate:a", 1.0, 0.15)
	tween.tween_interval(duration)
	tween.tween_property(ui, "modulate:a", 0.0, 0.25)
	tween.tween_callback(layer.queue_free)


## Show a modal confirmation dialog. Returns true if confirmed, false if cancelled.
## Awaitable: var ok := await PixelUI.confirm(get_tree(), "Sure?", "[E] Yes", "[Esc] No")
static func confirm(scene_tree: SceneTree, message: String,
		confirm_label: String = "Yes",
		cancel_label:  String = "No") -> bool:
	var layer := CanvasLayer.new()
	layer.layer = 98
	scene_tree.current_scene.add_child(layer)

	var resolved := false
	var result   := false

	var ui := PixelUI.new(160.0)
	ui.style = PixelUIStyle.dark()
	ui.modal(0.5)
	layer.add_child(ui)
	ui.label(message)
	ui.spacing(3.0)
	ui.row([
		ui.make_button(
			confirm_label, 
			func() -> void: result = true; resolved = true
		),
		ui.make_button(
			cancel_label, 
			func() -> void: result = false; resolved = true
		),
	])
	ui.center()

	while not resolved:
		await scene_tree.process_frame
	layer.queue_free()
	return result


# ── Internal ──────────────────────────────────────────────────────────────────

func _compute_height() -> float:
	var content_w    := _width - style.padding * 2.0
	var total_height := style.padding * 2.0
	var item_count   := 0
	for item: PixelUIItem in _items:
		if not item.is_visible(): continue
		total_height += item.height(style, content_w) + style.item_gap
		item_count += 1
	if item_count > 0:
		total_height -= style.item_gap
	return total_height


func _emit_warnings() -> void:
	var font := style.resolve_font(PixelUILabel.Variant.BODY)
	for entry: Dictionary in _draw_cache:
		var item := entry["item"] as PixelUIItem
		var rect := entry["rect"] as Rect2
		if item is PixelUIButton:
			var button     := item as PixelUIButton
			var label_text := button.text_getter.call() as String \
				if button.text_getter.is_valid() else button.text
			var font_size  := style.fs_body
			var show_dot   := button.is_toggle and rect.size.x >= PixelUIButton.DOT_MIN_W
			var max_text_w := rect.size.x \
				- (PixelUIButton.PAD_LEFT_DOT if show_dot else PixelUIButton.PAD_LEFT) \
				- PixelUIButton.PAD_RIGHT
			if font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_text_w:
				var warning := "PixelUI: button text truncated — \"%s\"" % label_text
				if not _warned.has(warning):
					_warned[warning] = true
					push_warning(warning)


func _item_type_name(item: PixelUIItem) -> String:
	if item is PixelUILabel:
		var label := item as PixelUILabel
		match label.variant:
			PixelUILabel.Variant.HEADING: return "Label[HEADING]"
			PixelUILabel.Variant.HINT:    return "Label[HINT]"
			_: return "Label[LIVE]" if label.text_getter.is_valid() else "Label"
	if item is PixelUIButton:
		return "Toggle" if (item as PixelUIButton).is_toggle else "Button"
	if item is PixelUISep:
		return "Spacer" if (item as PixelUISep).spacer_height > 0.0 else "Sep"
	if item is PixelUIRow:    return "Row"
	if item is PixelUIGrid:   return "Grid"
	if item is PixelUIBar:    return "Bar"
	if item is PixelUISlider: return "Slider"
	if item is PixelUIScroll: return "Scroll"
	if item is PixelUIList:   return "List"
	if item is PixelUITabs:   return "Tabs"
	if item is PixelUICustom: return "Custom"
	return "Item"


func _item_content_preview(item: PixelUIItem) -> String:
	if item is PixelUILabel:
		var label      := item as PixelUILabel
		var label_text := label.text_getter.call() as String \
			if label.text_getter.is_valid() else label.text
		return '"%s"' % label_text.left(20)
	if item is PixelUIButton:
		var button     := item as PixelUIButton
		var label_text := button.text_getter.call() as String \
			if button.text_getter.is_valid() else button.text
		var state_tag  := ""
		if button.is_toggle:
			state_tag = " [on]" if button._active() else " [off]"
		return '"%s"%s' % [label_text.left(18), state_tag]
	return ""


func _item_status(item: PixelUIItem, item_style: PixelUIStyle,
		content_w: float, warnings: Array[String]) -> String:
	if item is PixelUILabel:
		var label      := item as PixelUILabel
		var font       := item_style.resolve_font(label.variant)
		var font_size  := item_style.fs_small \
			if label.variant != PixelUILabel.Variant.BODY else item_style.fs_body
		var label_text := label.text_getter.call() as String \
			if label.text_getter.is_valid() else label.text
		var text_size  := font.get_multiline_string_size(
			label_text, HORIZONTAL_ALIGNMENT_LEFT, content_w, font_size)
		var single_h   := font.get_multiline_string_size(
			"A", HORIZONTAL_ALIGNMENT_LEFT, content_w, font_size).y
		var line_count := int(round(text_size.y / single_h)) if single_h > 0.0 else 1
		if line_count > 1:
			warnings.append("[%s] wrapped to %d lines" % [label_text.left(20), line_count])
			return "WRAPPED %d lines" % line_count
	return "ok"


func _ascii_item_preview(item: PixelUIItem) -> String:
	if item is PixelUILabel:
		var label      := item as PixelUILabel
		var label_text := label.text_getter.call() as String \
			if label.text_getter.is_valid() else label.text
		return " " + (label_text.to_upper() if label.variant == PixelUILabel.Variant.HEADING \
			else label_text)
	if item is PixelUIButton:
		var button     := item as PixelUIButton
		var label_text := button.text_getter.call() as String \
			if button.text_getter.is_valid() else button.text
		if button.is_toggle:
			return " %s %s" % ["●" if button._active() else "○", label_text]
		return " [%s]" % label_text
	if item is PixelUIRow:    return " [row]"
	if item is PixelUIGrid:   return " [grid]"
	if item is PixelUIBar:    return " [===    ]"
	if item is PixelUISlider: return " [──●───]"
	if item is PixelUIScroll: return " [scroll]"
	if item is PixelUIList:   return " [list]"
	if item is PixelUITabs:   return " [tabs]"
	if item is PixelUICustom: return " [custom]"
	return ""
