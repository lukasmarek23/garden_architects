
### Create visuals for procedural paths

Option B — Directional tile sprites (looks like a real garden path, needs art)
For each cell, we look at which of its 4 directions connect to a neighbour and pick the matching tile sprite:

Connections	Tile needed
left + right	straight horizontal
up + down	straight vertical
right + down	corner NE→S
right + up	corner SE→N
left + down	corner NW→S
left + up	corner SW→N
3-way (T)	4 variants
4-way (cross)	1
dead end (1 direction)	4 variants (cap)
That's roughly 13 tile images, each fitting in one grid cell (e.g. 128×128 or 256×256 px). For a garden path, each tile would be a top-down gravel/stone texture with transparent edges.