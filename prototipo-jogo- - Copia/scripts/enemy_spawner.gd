extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://entities/enemy.tscn")
const MIN_PLATFORM_WIDTH := 4
const MAX_PATROL_DISTANCE := 110.0
const MAX_PLATFORM_ENEMIES := 8

var _qualified_row_index := 0
var _platform_enemy_count := 0

@onready var decoration: TileMapLayer = $tiles/Decoration

func _ready() -> void:
	_spawn_platform_enemies()

func _spawn_platform_enemies() -> void:
	var cells_by_row: Dictionary = {}
	for cell in decoration.get_used_cells():
		if not _is_platform_top(cell):
			continue
		if not cells_by_row.has(cell.y):
			cells_by_row[cell.y] = []
		cells_by_row[cell.y].append(cell.x)

	var rows: Array = cells_by_row.keys()
	rows.sort()
	for row in rows:
		var columns: Array = cells_by_row[row]
		columns.sort()
		_spawn_for_row_segments(row, columns)

func _is_platform_top(cell: Vector2i) -> bool:
	var source_id := decoration.get_cell_source_id(cell)
	if source_id < 0:
		return false
	var atlas_coords := decoration.get_cell_atlas_coords(cell)
	if atlas_coords.x < 18 or atlas_coords.x > 23 or atlas_coords.y not in [1, 3, 5]:
		return false
	var tile_data := decoration.get_cell_tile_data(cell)
	if tile_data == null:
		return false
	for polygon in range(tile_data.get_collision_polygons_count(0)):
		if tile_data.is_collision_polygon_one_way(0, polygon):
			return true
	return false

func _spawn_for_row_segments(row: int, columns: Array) -> void:
	if columns.is_empty():
		return
	var segment_start: int = columns[0]
	var previous: int = columns[0]
	var best_start := -1
	var best_end := -1
	var best_width := 0
	for index in range(1, columns.size() + 1):
		var current: int = columns[index] if index < columns.size() else previous + 2
		if current != previous + 1:
			var width := previous - segment_start + 1
			if width > best_width:
				best_width = width
				best_start = segment_start
				best_end = previous
			segment_start = current
		previous = current

	if best_width < MIN_PLATFORM_WIDTH:
		return
	# Spawn on the widest platform on every other platform row to keep a
	# challenging route upward without filling every landing with an enemy.
	if _qualified_row_index % 2 == 0 and _platform_enemy_count < MAX_PLATFORM_ENEMIES:
		_spawn_on_segment(row, best_start, best_end)
		_platform_enemy_count += 1
	_qualified_row_index += 1

func _spawn_on_segment(row: int, first_column: int, last_column: int) -> void:
	var width_in_cells := last_column - first_column + 1
	if width_in_cells < MIN_PLATFORM_WIDTH:
		return

	var middle := int(floor((first_column + last_column) / 2.0))
	var local_position := decoration.map_to_local(Vector2i(middle, row))
	var platform_center := decoration.to_global(local_position)
	var enemy := ENEMY_SCENE.instantiate()
	var safe_patrol_distance := width_in_cells * decoration.tile_set.tile_size.x * 0.5 - 20.0
	enemy.set("patrol_distance", minf(MAX_PATROL_DISTANCE, safe_patrol_distance))
	add_child(enemy)
	enemy.global_position = platform_center + Vector2(0, -20)
