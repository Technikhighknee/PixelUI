class_name PixelUIBar
extends PixelUIItem

## Read-only filled progress bar. See REQUIREMENTS.md §5.5.
## No interaction. value_getter returns a float in [0, 1].


## Called every frame. Must return float in [0.0, 1.0].
var value_getter:  Callable
## Optional. Called every frame to override style.col_fill.
var color_getter:  Callable
## When true, draws the percentage value centred on the bar.
var show_label:    bool = false


func height(style: PixelUIStyle, _content_width: float) -> float:
	return style.bar_height


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, _mouse: Vector2) -> void:
	var value := clampf(value_getter.call() as float, 0.0, 1.0) \
		if value_getter.is_valid() else 0.0
	var fill_col := color_getter.call() as Color \
		if color_getter.is_valid() else style.col_fill

	# Track
	canvas.draw_rect(rect, style.col_track)
	# Fill
	if value > 0.0:
		canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x * value, rect.size.y)),
			fill_col)
	# Border
	canvas.draw_rect(rect, style.col_btn_bd, false, 1.0)

	# Optional label
	if show_label:
		var label_text := "%d%%" % int(value * 100.0)
		var font_size  := style.fs_small
		canvas.draw_string(font,
			Vector2(rect.position.x, rect.position.y + font_size + (rect.size.y - font_size) * 0.5 - 1.0),
			label_text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, style.col_text)
