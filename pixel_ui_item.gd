class_name PixelUIItem
extends RefCounted

## Base class for all PixelUI items.
## Items are pure data objects — NOT Nodes. See REQUIREMENTS.md §3.3.
##
## Subclass contract:
##   override height(), render(), and optionally _hit() / _click() / _drag().
##   _hit() and _click() use underscore prefix to avoid colliding with public
##   Callable variables (on_click, on_hover, etc.) that subclasses expose.
##   Shared static utilities (fit_text, etc.) are defined here — once.


## When valid and returning false, this item contributes zero height and is not
## rendered. The panel reflows automatically. See REQUIREMENTS.md §5.1.
var visible_when: Callable


# ── Item interface ─────────────────────────────────────────────────────────────

## Height in virtual pixels.
## content_width is provided so wrapping labels can compute multi-line height.
## Fixed-height items (button, sep, bar, etc.) ignore content_width.
func height(_style: PixelUIStyle, _content_width: float) -> float:
	return 0.0


## Render this item. Called only during _draw() on the parent CanvasItem.
## canvas — the PixelUI Node2D. Call draw_* methods on it.
## rect   — exact allocated area in virtual pixels (local to canvas).
## mouse  — current mouse position in virtual pixels.
func render(
		_canvas: CanvasItem,
		_style:  PixelUIStyle,
		_font:   Font,
		_rect:   Rect2,
		_mouse:  Vector2) -> void:
	pass


## Returns true if the mouse is within this item's interactive area.
func _hit(_rect: Rect2, _mouse: Vector2, _style: PixelUIStyle) -> bool:
	return false


## Called when the user left-clicks within this item's hit area.
func _click(_rect: Rect2, _mouse: Vector2, _style: PixelUIStyle) -> void:
	pass


## Called every frame while the user is dragging this item.
## Only items that support drag (PixelUISlider) need to override this.
func _drag(_rect: Rect2, _mouse: Vector2, _style: PixelUIStyle) -> void:
	pass


## Returns true if this item supports mouse drag interaction.
func _is_draggable() -> bool:
	return false


# ── Shared static utilities ───────────────────────────────────────────────────

## Truncate text to fit max_w virtual pixels, appending "…" if it overflows.
## Used by fixed-height items (buttons) where vertical expansion is impossible.
## Labels must NEVER use this — they wrap instead. See REQUIREMENTS.md §6.3/6.4.
static func fit_text(font: Font, text: String, font_size: int, max_w: float) -> String:
	if max_w <= 0.0:
		return ""
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_w:
		return text
	var truncated := text
	while truncated.length() > 0:
		var candidate := truncated + "…"
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_w:
			return candidate
		truncated = truncated.left(truncated.length() - 1)
	return "…"


## True if this item should be included in layout (visible_when passes or is unset).
func is_visible() -> bool:
	if visible_when.is_valid():
		return visible_when.call() as bool
	return true
