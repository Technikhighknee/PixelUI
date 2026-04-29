class_name PixelUIIM

## Immediate mode API for PixelUI.
##
## Every frame, describe the panel you want. The library diffs against the
## previous frame and updates. No clear(), no rebuild(), no live getters.
## Structure is just code — conditionals are if statements, loops are for loops.
##
## Usage (call every frame from _process):
##
##   func _process(_delta: float) -> void:
##       PixelUIIM.begin("debug", Vector2(4, 4), 80.0, get_tree())
##       PixelUIIM.text("FPS: %d" % Engine.get_frames_per_second())
##       PixelUIIM.text("HP: %d / %d" % [player.hp, player.max_hp])
##       if player.in_combat:
##           PixelUIIM.text("Enemies: %d" % enemy_count, Color.RED)
##       if PixelUIIM.button("Respawn"):
##           player.reset()
##       PixelUIIM.end()
##
## PixelUIIM.button() returns true on the frame the button was clicked.
## One-frame delay is acceptable for dev tools at 60 fps.


## Retained PixelUI panels keyed by id. Panels are created on first use
## and reused every frame — begin() clears and rebuilds each call.
static var _panels:  Dictionary = {}

## The panel currently being built (between begin() and end()).
static var _active:  PixelUI    = null

## Label of the button clicked last frame. Consumed (cleared) by button().
static var _clicked: StringName = ""


## Begin an immediate-mode frame. Creates or retrieves the panel for this id.
## scene_tree must be provided on the first call for the panel to be added to
## the scene. On subsequent calls it is ignored — the panel persists.
static func begin(id: StringName, pos: Vector2, width: float,
		scene_tree: SceneTree = null) -> void:
	var panel: PixelUI
	if _panels.has(id):
		panel = _panels[id] as PixelUI
	else:
		panel = PixelUI.new(width)
		if scene_tree:
			var layer := CanvasLayer.new()
			layer.layer = 21
			scene_tree.current_scene.add_child(layer)
			layer.add_child(panel)
		_panels[id] = panel
	panel.set_panel_width(width)
	panel.position = pos
	panel.clear()
	_active = panel


## Add a static or coloured text label to the current panel.
static func text(content: String, col: Color = PixelUI.NO_COLOR) -> void:
	if _active: _active.label(content, col)


## Add a clickable button. Returns true on the frame it was clicked.
static func button(label: String) -> bool:
	if _active == null: return false
	var clicked := StringName(label) == _clicked
	if clicked: _clicked = ""
	_active.button(label, func() -> void: _clicked = StringName(label))
	return clicked


## Add a horizontal separator.
static func sep() -> void:
	if _active: _active.separator()


## Finalise the current panel. Call at the end of every begin() block.
static func end() -> void:
	_active = null


## Remove a panel by id. Call when a dev panel is no longer needed.
static func destroy(id: StringName) -> void:
	if not _panels.has(id): return
	var panel := _panels[id] as PixelUI
	if is_instance_valid(panel) and panel.get_parent():
		panel.get_parent().queue_free()  # free the CanvasLayer it lives in
	_panels.erase(id)
