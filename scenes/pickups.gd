extends TileMapLayer

signal reset_pickups

const RESET_TIME := 2.5
const PICKUP_COORDS := [Vector2i(0, 1), Vector2i(1, 1)]

var times := []
var spent_pickups := []
# [coords, atlas_coords.x]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in range(times.size()):
		times[i] += delta
	while times.size() > 0 and times[0] >= RESET_TIME:
		reset_pickup(spent_pickups[0][0], spent_pickups[0][1])
		times.pop_front()
		spent_pickups.pop_front()

func reset_pickup(coords: Vector2i, atlas_x: int) -> void:
	set_cell(coords, 2, Vector2i(atlas_x, 1))

func queue_pickup(pos: Vector2) -> void:
	var map_pos := local_to_map(pos)
	var atlas_coords := get_cell_atlas_coords(map_pos)
	set_cell(map_pos, 2, Vector2i(atlas_coords.x, 0))
	times.push_back(0.0)
	spent_pickups.push_back([map_pos, atlas_coords.x])

func is_pickup(pos: Vector2) -> bool:
	return get_cell_source_id(local_to_map(pos)) == 2 and get_cell_atlas_coords(local_to_map(pos)) in PICKUP_COORDS

func _on_reset_pickups() -> void:
	for pickup in spent_pickups:
		reset_pickup(pickup[0], pickup[1])
