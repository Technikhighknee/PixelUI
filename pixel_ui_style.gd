class_name PixelUIStyle
extends Resource

## Visual theme for all PixelUI panels.
## All sizes are virtual pixels (base resolution coordinates).
## See REQUIREMENTS.md §4 for the full specification.
##
## Usage:
##   ui.style = PixelUIStyle.dark()      # use a preset
##   ui.style = PixelUIStyle.new()       # customise from defaults
##   ui.style.col_bg = Color(0,0,0,0.8) # override individual values


# ── Viewport ──────────────────────────────────────────────────────────────────

## Base resolution. Used by PixelUI.center() and modal dim overlay.
@export var viewport_size: Vector2 = Vector2(480.0, 270.0)


# ── Typography ────────────────────────────────────────────────────────────────

## Body font. null = ThemeDB.fallback_font.
@export var font_body:    Font = null
## Heading font. null = font_body.
@export var font_heading: Font = null
## Hint font. null = font_body.
@export var font_hint:    Font = null

## Body text font size (virtual px).
@export var fs_body:  int = 7
## Heading and hint font size (virtual px).
@export var fs_small: int = 6

## Vertical space allocated per text line (virtual px).
## Should be slightly larger than fs_body to provide leading.
@export var line_height: float = 9.0


# ── Spacing ───────────────────────────────────────────────────────────────────

## Inner padding between panel edge and content (virtual px).
@export var padding:     float = 4.0
## Vertical gap between consecutive items (virtual px).
@export var item_gap:    float = 1.0
## Gap between grid/list cells (virtual px).
@export var grid_gap:    float = 1.0
## Fixed height of buttons and toggle items (virtual px).
@export var btn_height:  float = 11.0
## Height occupied by a separator item (virtual px). Rule drawn at midpoint.
@export var sep_height:  float = 5.0
## Height of bar and slider items (virtual px).
@export var bar_height:  float = 8.0


# ── Transitions ───────────────────────────────────────────────────────────────

## Hover fade-in / fade-out duration in seconds.
@export var hover_duration:       float = 0.08
## Click highlight decay duration in seconds.
@export var click_flash_duration: float = 0.12


# ── Panel colours ─────────────────────────────────────────────────────────────

@export var col_bg:     Color = Color(0.06, 0.06, 0.09, 0.92)
@export var col_border: Color = Color(0.22, 0.22, 0.32, 0.75)
@export var col_sep:    Color = Color(0.22, 0.22, 0.32, 0.55)


# ── Text colours ──────────────────────────────────────────────────────────────

@export var col_text:    Color = Color(0.80, 0.80, 0.88)
@export var col_heading: Color = Color(0.42, 0.42, 0.56)
@export var col_hint:    Color = Color(0.36, 0.36, 0.44)


# ── Button colours ────────────────────────────────────────────────────────────

@export var col_btn_bg:       Color = Color(0.11, 0.11, 0.16)
@export var col_btn_bd:       Color = Color(0.24, 0.24, 0.34)
@export var col_btn_hover:    Color = Color(0.18, 0.18, 0.26)
@export var col_btn_disabled: Color = Color(0.35, 0.35, 0.42)
## Overlay colour drawn on click and decayed over click_flash_duration.
@export var col_btn_flash:    Color = Color(1.00, 1.00, 1.00, 0.25)


# ── Toggle / active colours ───────────────────────────────────────────────────

@export var col_on:    Color = Color(0.32, 0.88, 0.44)
@export var col_on_bg: Color = Color(0.10, 0.28, 0.14)


# ── Grid colours ──────────────────────────────────────────────────────────────

@export var col_cell_bg:    Color = Color(0.10, 0.10, 0.14)
@export var col_cell_bd:    Color = Color(0.22, 0.22, 0.32)
@export var col_cell_hover: Color = Color(0.20, 0.20, 0.28)


# ── Bar / slider colours ──────────────────────────────────────────────────────

@export var col_track: Color = Color(0.10, 0.10, 0.14)
@export var col_fill:  Color = Color(0.32, 0.70, 0.88)


# ── Focus ─────────────────────────────────────────────────────────────────────

## Keyboard navigation focus ring colour.
@export var col_focus: Color = Color(0.60, 0.75, 1.00, 0.80)


# ── Static presets ────────────────────────────────────────────────────────────

## Default dark theme — suitable for most game overlays and dev tools.
static func dark() -> PixelUIStyle:
	return PixelUIStyle.new()   # all defaults are the dark theme


## Light background theme — for overlays on dark game scenes.
static func light() -> PixelUIStyle:
	var new_style             := PixelUIStyle.new()
	new_style.col_bg           = Color(0.92, 0.92, 0.94, 0.95)
	new_style.col_border       = Color(0.55, 0.55, 0.65, 0.80)
	new_style.col_sep          = Color(0.55, 0.55, 0.65, 0.55)
	new_style.col_text         = Color(0.08, 0.08, 0.12)
	new_style.col_heading      = Color(0.35, 0.35, 0.50)
	new_style.col_hint         = Color(0.50, 0.50, 0.60)
	new_style.col_btn_bg       = Color(0.80, 0.80, 0.86)
	new_style.col_btn_bd       = Color(0.55, 0.55, 0.65)
	new_style.col_btn_hover    = Color(0.70, 0.70, 0.80)
	new_style.col_btn_disabled = Color(0.62, 0.62, 0.68)
	return new_style


## Minimal theme — no panel background, text only. Good for HUD labels.
static func minimal() -> PixelUIStyle:
	var new_style             := PixelUIStyle.new()
	new_style.col_bg           = Color(0, 0, 0, 0)
	new_style.col_border       = Color(0, 0, 0, 0)
	new_style.col_btn_bg       = Color(0, 0, 0, 0)
	new_style.col_btn_bd       = Color(0, 0, 0, 0)
	new_style.col_btn_hover    = Color(1, 1, 1, 0.08)
	return new_style


# ── Font resolution helper ────────────────────────────────────────────────────

## Returns the resolved font for a given label variant.
## Handles the null-fallback chain: variant font → font_body → ThemeDB fallback.
func resolve_font(variant: int) -> Font:
	match variant:
		1:  # HEADING
			if font_heading: return font_heading
			if font_body:    return font_body
		2:  # HINT
			if font_hint:  return font_hint
			if font_body:  return font_body
		_:  # BODY
			if font_body:  return font_body
	return ThemeDB.fallback_font
