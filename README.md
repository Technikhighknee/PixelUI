# PixelUI

A pixel-exact UI library for Godot 4, written in GDScript.

I built this for my own game and am sharing it as-is. It is not a polished, general-purpose framework — it is the tool I actually needed, extracted from my project. It works well for what it does. Whether it works well for yours is something you will have to find out.

---

## Expectations

This is developed alongside a game in active development. That means it changes frequently and will likely introduce breaking changes without warning. If you build something with it today, it may need migration tomorrow. That is not a bug — it is the nature of the project.

Features that might appear over time, as the game needs them: accessibility and screen reader support, extensive controller and gamepad navigation, localization infrastructure, performance improvements for complex scenes. None of these are promised. They will exist if the game needs them. They might never exist if it doesn't.

If you find it useful, you are welcome to watch the repo. But I would not build anything production-critical on top of it unless you are prepared to maintain your own fork. Which brings me to the next point.

There are no branches, no pull requests, no review process. Everything goes directly to main. If you are watching the repo, main is always the current state of what I am using in my game — no more, no less.

It is released under the Unlicense — public domain, no strings attached. Fork it, change it, strip out everything you don't need, call it something else entirely. I am not building a following here. I am building a game.

---

## What it does

Draws all UI via `_draw()` in virtual pixel coordinates. No Control nodes, no Godot theme system, no sizing surprises. If your project uses `canvas_items` stretch mode with a fixed base resolution, everything will be exactly the size you specify.

**Key behaviour:**
- Panel height is always computed from content — you never set it manually
- Text wraps automatically — labels never truncate or overflow
- Truncation with `…` only applies to buttons, where fixed height makes wrapping impossible
- Every interactive element has smooth hover and click feedback out of the box
- The layout is always describable as text via `layout_report()` — useful for debugging without a screen

---

## Requirements

- Godot 4.x (tested on 4.6+)
- GDScript only
- `canvas_items` stretch mode (other modes will produce wrong sizes unless you adjust `PixelUIStyle.viewport_size`)

---

## Installation

Copy the `pixel_ui/` directory into your project. All files use `class_name`, so Godot will pick them up automatically. No autoloads, no plugins, no configuration required.

---

## Quick start

```gdscript
# Create a CanvasLayer to hold the panel
var layer := CanvasLayer.new()
layer.layer = 20
add_child(layer)

# Create a panel — 80 virtual pixels wide
var ui := PixelUI.new(80.0)
layer.add_child(ui)

ui.heading("MY PANEL")
ui.separator()
ui.button("Click me", func(): print("clicked"))
ui.toggle("Option", func(on: bool): my_option = on)
ui.label_live(func() -> String: return "Value: %d" % my_value)
ui.center()  # call AFTER adding all items
```

For dev tools where the structure changes every frame, use the immediate mode API:

```gdscript
func _process(_delta: float) -> void:
    PixelUIIM.begin("debug", Vector2(4, 4), 80.0, get_tree())
    PixelUIIM.text("FPS: %d" % Engine.get_frames_per_second())
    if PixelUIIM.button("Reset"):
        reset()
    PixelUIIM.end()
```

---

## Item types

| Builder method | Description |
|---|---|
| `heading(text)` | Small dim uppercase section label |
| `label(text, color?)` | Body text. Wraps automatically. |
| `label_live(getter, color?)` | Label updated every frame from a `() -> String` Callable |
| `label_colored(text_getter, color_getter)` | Both text and color updated every frame |
| `hint(text)` | Very dim small text — keyboard shortcuts, secondary info |
| `separator()` | Horizontal rule |
| `spacing(height?)` | Blank vertical space |
| `button(text, callback)` | Clickable button. Invalid Callable = disabled. Supports keyboard hotkeys — set `hotkey: Key` on the item returned by `make_button()`. |
| `toggle(text, callback, initial?)` | Stateful toggle. Callback receives new bool. |
| `toggle_ext(text, active_getter, callback)` | Toggle whose state is read externally — for radio groups |
| `slider(min, max, value, callback)` | Draggable value control |
| `bar(value_getter, color_getter?)` | Read-only filled bar, value 0..1 |
| `row(children)` | Horizontal layout. Children are items, `make_fixed(item, px)`, or `make_flex(item, weight)` dicts. |
| `grid(cols, rows, cell_size, ...)` | 2D clickable cell grid with per-cell draw callback |
| `scroll(children, max_height)` | Scrollable item container |
| `list(count, item_height, draw_fn, ...)` | Virtual list — only renders visible items |
| `tabs(labels, callback)` | Tab/page switcher |
| `custom(height, draw_fn, click_fn?)` | Arbitrary `_draw()` content |

---

## Theming

All visual constants live in `PixelUIStyle`, which is a `Resource`. Swap it on any panel:

```gdscript
ui.style = PixelUIStyle.light()   # built-in light theme
ui.style = PixelUIStyle.minimal() # no backgrounds, text only
```

Or create your own:

```gdscript
var my_style := PixelUIStyle.new()
my_style.col_bg = Color(0.0, 0.0, 0.0, 0.85)
my_style.fs_body = 8
ui.style = my_style
```

---

## Rows with mixed widths

```gdscript
ui.row([
    ui.make_fixed(ui.make_button("−", on_minus), 12.0),
    ui.make_label_live(func() -> String: return str(depth)),
    ui.make_fixed(ui.make_button("+", on_plus),  12.0),
])
```

`make_fixed(item, width)` pins a child to an exact pixel width. `make_flex(item, weight)` gives a child a proportional share of remaining space (default weight 1.0). Fixed children are allocated first; remaining space is divided among flex children by weight. Plain items (no wrapper) are treated as flex with weight 1.0.

---

## Layout report

```gdscript
print(ui.layout_report())   # text description of every item's rect and status
print(ui.ascii_render())    # rough ASCII art of the panel
```

Useful when you cannot see the screen or want to verify layout programmatically.

---

## Static utilities

```gdscript
# Temporary notification that fades in, holds, and self-destructs
PixelUI.toast(get_tree(), "Saved!", Color.GREEN, 2.0)

# Awaitable confirmation dialog
var confirmed := await PixelUI.confirm(get_tree(), "Are you sure?", "Yes", "No")
```

---

## Caveats

- Tested on `canvas_items` stretch mode only. Other modes may need `PixelUIStyle.viewport_size` adjusted.
- Scrollbars are decorative indicators, not draggable.
- Grid drag-and-drop has the API scaffolded (`can_drag`, `on_drop`) but the ghost overlay is not implemented.
- No text input fields.
- No accessibility/screen reader support.
- `layout_report()` line-count detection uses `get_multiline_string_size("A")` as the single-line baseline — accurate for most fonts, may be off for unusual ones.

---

## License

Public domain — see `UNLICENSE`.
