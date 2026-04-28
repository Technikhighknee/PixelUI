class_name PixelUIButton
extends PixelUIItem

## Clickable button or stateful toggle. See REQUIREMENTS.md §5.4.
##
## Disabled state: on_press invalid AND not a toggle → greyed out, no interaction.
## enabled_when:   Callable returning false → same disabled appearance and behaviour,
##                 but the item still occupies space in the layout.
##
## Toggle (internal state): on_press receives new bool.
## Toggle (external state): active_getter read each frame; on_press called with no arg.
##
## Smooth transitions via timestamp arithmetic — no Tweens, no Nodes required.
## Hover fades over style.hover_duration. Click flash decays over style.click_flash_duration.


## Minimum button width (virtual px) to show the toggle dot indicator.
## Below this threshold, active background communicates state instead.
const DOT_MIN_W:    float = 24.0
## Left text margin when the dot indicator is shown.
const PAD_LEFT_DOT: float = 12.0
## Left text margin when there is no dot indicator.
const PAD_LEFT:     float = 4.0
## Right text margin (both cases).
const PAD_RIGHT:    float = 4.0

var text:          String   = ""
var text_getter:   Callable             # () -> String. Overrides text.
var on_press:      Callable             # Invalid = disabled.
var is_toggle:     bool     = false
var active:        bool     = false     # Internal toggle state.
var active_getter: Callable             # () -> bool. External state for radio groups.
var enabled_when:  Callable             # () -> bool. False = disabled but still visible.
var hotkey:        Key      = KEY_NONE

# Transition state — timestamps in milliseconds, -1 = inactive
var _hover_enter_ms: int  = -1
var _hover_exit_ms:  int  = -1
var _was_hovered:    bool = false
var _click_ms:       int  = -1


func height(style: PixelUIStyle, _content_width: float) -> float:
	return style.btn_height


func _hit(rect: Rect2, mouse: Vector2, _style: PixelUIStyle) -> bool:
	return not _disabled() and rect.has_point(mouse)


func _click(_rect: Rect2, _mouse: Vector2, _style: PixelUIStyle) -> void:
	if _disabled():
		return
	_click_ms = Time.get_ticks_msec()
	if is_toggle:
		if active_getter.is_valid():
			if on_press.is_valid(): on_press.call()
		else:
			active = not active
			if on_press.is_valid(): on_press.call(active)
	else:
		if on_press.is_valid(): on_press.call()


func render(canvas: CanvasItem, style: PixelUIStyle, font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var disabled   := _disabled()
	var hovered    := not disabled and rect.has_point(mouse)
	var is_active  := _resolve_active()
	var label_text := text_getter.call() as String if text_getter.is_valid() else text
	var now_ms     := Time.get_ticks_msec()
	var btn_height := rect.size.y

	# ── Hover transition ──────────────────────────────────────────────────────
	if hovered and not _was_hovered:
		_hover_enter_ms = now_ms
		_hover_exit_ms  = -1
		_was_hovered    = true
	elif not hovered and _was_hovered:
		_hover_exit_ms  = now_ms
		_hover_enter_ms = -1
		_was_hovered    = false

	var hover_blend: float = 0.0
	var duration_ms := int(style.hover_duration * 1000.0)
	if duration_ms > 0:
		if hovered and _hover_enter_ms >= 0:
			hover_blend = minf(float(now_ms - _hover_enter_ms) / float(duration_ms), 1.0)
		elif not hovered and _hover_exit_ms >= 0:
			hover_blend = maxf(1.0 - float(now_ms - _hover_exit_ms) / float(duration_ms), 0.0)
	else:
		hover_blend = 1.0 if hovered else 0.0

	# ── Background ────────────────────────────────────────────────────────────
	var bg_color := style.col_on_bg if (is_toggle and is_active) else style.col_btn_bg
	if not disabled:
		bg_color = bg_color.lerp(style.col_btn_hover, hover_blend)
	canvas.draw_rect(rect, bg_color)
	canvas.draw_rect(rect, style.col_btn_bd, false, 1.0)

	# ── Click flash ───────────────────────────────────────────────────────────
	if _click_ms >= 0:
		var flash_duration_ms := int(style.click_flash_duration * 1000.0)
		var elapsed_ms        := now_ms - _click_ms
		if elapsed_ms < flash_duration_ms:
			var flash_alpha := 1.0 - float(elapsed_ms) / float(flash_duration_ms)
			canvas.draw_rect(rect, Color(style.col_btn_flash, style.col_btn_flash.a * flash_alpha))
		else:
			_click_ms = -1

	# ── Toggle dot indicator ──────────────────────────────────────────────────
	var show_dot := is_toggle and rect.size.x >= DOT_MIN_W
	if show_dot:
		var dot_center := Vector2(rect.position.x + 5.0, rect.position.y + btn_height * 0.5)
		if is_active:
			canvas.draw_circle(dot_center, 2.0, style.col_on)
		else:
			canvas.draw_arc(dot_center, 2.0, 0.0, TAU, 8, style.col_on, 1.0)

	# ── Label ─────────────────────────────────────────────────────────────────
	var text_color: Color
	if disabled:                      text_color = style.col_btn_disabled
	elif is_toggle and is_active:     text_color = style.col_on
	else:                             text_color = style.col_text

	var font_size  := style.fs_body
	var text_y     := rect.position.y + font_size + (btn_height - font_size) * 0.5 - 1.0
	var text_x     := rect.position.x + (PAD_LEFT_DOT if show_dot else PAD_LEFT)
	var text_w     := rect.size.x - (text_x - rect.position.x) - PAD_RIGHT
	var alignment  := HORIZONTAL_ALIGNMENT_LEFT if show_dot else HORIZONTAL_ALIGNMENT_CENTER
	canvas.draw_string(font, Vector2(text_x, text_y),
		fit_text(font, label_text, font_size, text_w), alignment, text_w, font_size, text_color)


func _disabled() -> bool:
	if enabled_when.is_valid() and not (enabled_when.call() as bool):
		return true
	return not on_press.is_valid() and not is_toggle


func _resolve_active() -> bool:
	if active_getter.is_valid():
		return active_getter.call() as bool
	return active
