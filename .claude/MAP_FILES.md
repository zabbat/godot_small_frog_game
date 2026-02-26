# Map File Format

A map file uses named layers — each layer is a separate grid with its own legend.

## Sections

### [size]

Grid dimensions shared by all layers.

```
[size]
<cols>,<rows>
```

### [layer:<name>]

A grid for a specific layer. Each layer has its own `[legend:<name>]`.

Built-in layers:
- `ground` — flat ground texture (rendered via shader on the ground plane)
- `decoration` — 3D decorations on top of ground (e.g. grass blades)
- `objects` — 3D models with optional collision

`0` is always "empty/none" in any layer.

### [legend:<name>]

Maps characters to types for the corresponding layer.

**Ground legend values:**
- `none` — bare ground (dark brown)
- `grass` — procedural grass texture

**Decoration legend values:**
- `none` — no decoration
- `grass_3d` — 3D grass blades with wind sway

**Objects legend values:**
- `<model_id>` or `<model_id>, <rotation_degrees>`
- With portal: `<model_id>, <rotation>, (<action>, <map_path>, <spawn_x>, <spawn_z>, <spawn_rotation>)`
- Model ID must exist in `assets/asset_registry.cfg`
- Portal actions: `TOUCH` — triggers map transition when player collides with the object
- Portal `map_path` is relative to `res://` (e.g. `maps/test_house_1.map`)
- `spawn_col`, `spawn_row` — player grid position in the target map (column, row)
- `spawn_rotation` — player facing direction in degrees

### [confined]

Optional section that adds walls around the map edges for indoor/enclosed areas.

```
[confined]
L = c:80808080, []
R = c:80808080, []
B = c:80808080, [3]
F = c:0D808080, []
```

- Keys: `L` (left/−X), `R` (right/+X), `B` (back/−Z), `F` (front/+Z, camera-facing)
- `c:AARRGGBB` — hex color with alpha first (e.g. `80808080` = grey at 50% opacity)
- `[3]` — cutout indices (grid cells where the wall has a door-sized gap); `[]` for no cutouts
- L/R cutout indices refer to row numbers; B/F cutout indices refer to column numbers
- Omit a side to leave it open (no wall)

### [items]

Items placed at exact world positions (not grid-snapped).

```
[items]
<name>, (<x>, <y>, <z>), <model id>
```

---

## Full Example

```
[size]
10,10

[layer:ground]
1111000000
1110000000
1100000000
1000000100
1000000000
1100000011
1100000011
1110000111
1111111111
1111111111

[layer:decoration]
1111000000
1110000000
1100000000
1000000000
1000000000
1100000011
1100000011
1110000111
1111111111
1111111111

[layer:objects]
0000000000
0000000000
0000000000
0000000H00
0000000000
000H000000
0000000000
0000000000
0T00000000
0000000000

[legend:ground]
0 = none
1 = grass

[legend:decoration]
0 = none
1 = grass_3d

[legend:objects]
H = house_001, 180, (TOUCH, maps/test_house_1.map, 3, 0, 180)
T = tree_001, 90

[items]
Sword, (-3, 0.5, 2), sword_1handed
```
