class_name PixelUISlider
extends PixelUIItem

## Draggable value control. See REQUIREMENTS.md §5.6.
## Drag is handled by PixelUI tracking _drag_item. See §7.4.


var value:        float    = 0.0
var min_val:      float    = 0.0
var max_val:      float    = 1.0
## 0.0 = continuous. >0 = snap to multiples of step.
var step:         float    = 0.0
## Fires on every value change during drag and on release.
var on_change:    Callable
## When false (via enabled_when), renders disabled and ignores interaction.
var enabled_when: Callable
## When true, draws formatted value text on the right side.
var show_value:   bool     = true
## Printf format string for the value display.
var format:       String   = "%.2f"


func height(style: PixelUIStyle, _content_width: float) -> float:
	return style.bar_height


func _hit(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> bool:
	return not _disabled() and rect.has_point(mouse)


func _is_draggable() -> bool:
	return not _disabled()


func _drag(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> void:
	if _disabled():
		return
	var drag_ratio := clampf((mouse.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	var new_val    := min_val + drag_ratio * (max_val - min_val)
	if step > 0.0:
		new_val = roundf(new_val / step) * step
	new_val = clampf(new_val, min_val, max_val)
	if new_val != value:
		value = new_val
		if on_change.is_valid(): on_change.call(value)


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var disabled := _disabled()
	var hovered  := not disabled and rect.has_point(mouse)
	var fill_w   := rect.size.x * _normalised()

	# Track
	canvas.draw_rect(rect, style.col_track)
	# Fill
	if fill_w > 0.0:
		var fill_color := style.col_fill if not disabled else style.col_btn_disabled
		canvas.draw_rect(Rect2(rect.position, Vector2(fill_w, rect.size.y)), fill_color)
	var border_color := style.col_btn_hover if hovered else style.col_cell_bd
	canvas.draw_rect(rect, border_color, false, 1.0)

	if show_value:
		var label_text := format % value
		var font_size  := style.fs_small
		var text_color := style.col_btn_disabled if disabled else style.col_text
		canvas.draw_string(font,
			Vector2(rect.position.x, rect.position.y + font_size + (rect.size.y - font_size) * 0.5 - 1.0),
			label_text, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 2.0, font_size, text_color)


func _normalised() -> float:
	var range := max_val - min_val
	return (value - min_val) / range if range > 0.0 else 0.0


func _disabled() -> bool:
	return enabled_when.is_valid() and not (enabled_when.call() as bool)
