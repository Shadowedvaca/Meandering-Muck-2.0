class_name MazePiece
extends MazeDataCalculations

var position: Vector2i = Vector2i(-1, -1)
var fill: PackedVector2Array = [] # Only for inner wall
var potential_range: PackedVector2Array = [] # Only for inner wall
var possible_positions: PackedVector2Array = []
var middle_point: Vector2i = Vector2i(-1, -1)
var middle_ish_adjustment: Vector2i = Vector2i(-1, -1)
var direction: String = "" # Only for doors
var distance: String = "" # Only for doors

func get_position() -> Vector2i:
	return position

func get_fill(axis: String) -> PackedInt32Array:
	return _get_one_axis(axis, fill)

func get_potential_range(bound: String) -> Vector2i:
	if bound == 'min':
		return potential_range[0]
	elif bound == 'max':
		return potential_range[1]
	else:
		return Vector2i(-1, -1)

func get_possible_positions(axis: String) -> PackedInt32Array:
	return _get_one_axis(axis, possible_positions)

func get_middle_point() -> Vector2i:
	return middle_point

func get_middle_ish_adjustment() -> Vector2i:
	return middle_ish_adjustment

func get_direction() -> String:
	return direction

func get_distance() -> String:
	return distance

func set_position(new_vector: Vector2i = Vector2i(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	position = _calculate_vector(new_vector, new_x, new_y)

func set_fill(axis: String, value_set: PackedInt32Array, reset: bool = true) -> void:
	if reset:
		fill = []
	for v: Vector2 in _set_one_axis(axis, value_set):
		@warning_ignore("return_value_discarded")
		fill.append(v)

func set_potential_range(bound: String, new_vector: Vector2i = Vector2i(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	if bound == 'min':
		potential_range[0] = _calculate_vector(new_vector, new_x, new_y)
	elif bound == 'max':
		potential_range[1] = _calculate_vector(new_vector, new_x, new_y)

func set_possible_positions(axis: String, value_set: PackedInt32Array, reset: bool = true) -> void:
	if reset:
		possible_positions = []
	for v: Vector2 in _set_one_axis(axis, value_set):
		@warning_ignore("return_value_discarded")
		possible_positions.append(v)

func append_possible_positions(axis: String, added_value: int) -> void:
	for v: Vector2 in _set_one_axis(axis, [], added_value):
		@warning_ignore("return_value_discarded")
		possible_positions.append(v)

func set_middle_point(new_vector: Vector2i = Vector2i(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	middle_point = _calculate_vector(new_vector, new_x, new_y)

func set_middle_ish_adjustment(new_vector: Vector2i = Vector2i(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	middle_ish_adjustment = _calculate_vector(new_vector, new_x, new_y)

func set_direction(new_value: String) -> void:
	direction = new_value

func set_distance(new_value: String) -> void:
	distance = new_value

func set_random_position() -> void:
	var x: Array = _get_one_axis('x', possible_positions)
	var y: Array = _get_one_axis('x', possible_positions)
	position.x = x.pick_random()
	position.y = y.pick_random()
