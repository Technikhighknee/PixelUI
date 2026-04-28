class_name PixelUIGrid
extends PixelUIItem

## 2D cell grid. See REQUIREMENTS.md §5.9.
##
## draw_cell: Callable(canvas, col, row, rect, is_hovered, is_selected) → void
##   Omit to use the default dark-box style.
##
## on_hover fires only when the hovered cell changes — not every frame.
## on_hover receives (-1, -1) when the mouse leaves the grid.
##
## Drag-and-drop: set both can_drag and on_drop to enable.


var cols:      int   = 4
var rows:      int   = 4
var cell_size: float = 32.0

var draw_cell: Callable   # (canvas, col, row, rect: Rect2, is_hovered: bool, is_selected: bool)
var on_click:  Callable   # (col, row)
var on_hover:  Callable   # (col, row) — fires on change only; (-1,-1) = no cell
var selected:  Vector2i   = Vector2i(-1, -1)

var can_drag:  Callable   # (col, row) -> bool
var on_drop:   Callable   # (from_col, from_row, to_col, to_row)

var _hovered: Vector2i = Vector2i(-1, -1)


func height(style: PixelUIStyle, _content_width: float) -> float:
	return rows * cell_size + maxf(rows - 1, 0) * style.grid_gap


func _hit(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> bool:
	return Rect2(rect.position, _grid_size(style)).has_point(mouse)


func _click(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> void:
	var cell := _cell_at(rect, mouse, style)
	if cell.x >= 0 and on_click.is_valid():
		on_click.call(cell.x, cell.y)


func render(canvas: CanvasItem, style: PixelUIStyle, _font: Font,
		rect: Rect2, mouse: Vector2) -> void:
	var cell_step   := cell_size + style.grid_gap
	var new_hovered := _cell_at(rect, mouse, style)

	if new_hovered != _hovered:
		_hovered = new_hovered
		if on_hover.is_valid():
			on_hover.call(_hovered.x, _hovered.y)

	for row: int in rows:
		for col: int in cols:
			var cell_rect := Rect2(
				rect.position.x + col * cell_step,
				rect.position.y + row * cell_step,
				cell_size, cell_size
			)
			var is_hovered  := Vector2i(col, row) == _hovered
			var is_selected := Vector2i(col, row) == selected
			if draw_cell.is_valid():
				draw_cell.call(canvas, col, row, cell_rect, is_hovered, is_selected)
			else:
				_draw_default_cell(canvas, style, cell_rect, is_hovered, is_selected)


func _grid_size(style: PixelUIStyle) -> Vector2:
	var cell_step := cell_size + style.grid_gap
	return Vector2(cols * cell_step - style.grid_gap, rows * cell_step - style.grid_gap)


func _cell_at(rect: Rect2, mouse: Vector2, style: PixelUIStyle) -> Vector2i:
	var local_pos := mouse - rect.position
	var cell_step := cell_size + style.grid_gap
	var column := int(local_pos.x / cell_step)
	var row    := int(local_pos.y / cell_step)
	if column < 0 or column >= cols or row < 0 or row >= rows:
		return Vector2i(-1, -1)
	if local_pos.x - column * cell_step >= cell_size or local_pos.y - row * cell_step >= cell_size:
		return Vector2i(-1, -1)
	return Vector2i(column, row)


func _draw_default_cell(canvas: CanvasItem, style: PixelUIStyle,
		cell_rect: Rect2, is_hovered: bool, is_selected: bool) -> void:
	var bg_color := style.col_cell_bg
	if is_selected:   bg_color = style.col_on_bg
	elif is_hovered:  bg_color = style.col_cell_hover
	canvas.draw_rect(cell_rect, bg_color)
	var border_color := style.col_on if is_selected else style.col_cell_bd
	canvas.draw_rect(cell_rect, border_color, false, 1.0)
