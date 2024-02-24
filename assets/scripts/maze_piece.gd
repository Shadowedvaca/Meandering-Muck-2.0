class_name MazePiece
extends MazeDataCalculations

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var mmmc: Resource = load("res://assets/scripts/maze_min_max.gd")
var evc: Resource = load("res://assets/scripts/exploded_vector.gd")
var position: Vector2 = Vector2(-1, -1)
@warning_ignore("unsafe_method_access")
var fill: ExplodedVector = evc.new() # Only for inner wall
@warning_ignore("unsafe_method_access")
var potential_range: MazeMinMax = mmmc.new()
@warning_ignore("unsafe_method_access")
var possible_positions: ExplodedVector = evc.new()
var middle_point: Vector2 = Vector2(-1, -1)
var middle_ish_adjustment: Vector2 = Vector2(-1, -1)
var direction: String = "" # Only for doors
var distance: String = "" # Only for doors

func _ready() -> void:
	rng.randomize()

func get_position() -> Vector2:
	return position

func get_fill(axis: String) -> PackedInt32Array:
	match axis:
		'x':
			return fill.x
		'y':
			return fill.y
		_:
			return []

func get_potential_range(bound: String) -> Vector2:
	if bound == 'min':
		return potential_range.get_min()
	elif bound == 'max':
		return potential_range.get_max()
	else:
		return Vector2(-1, -1)

func get_possible_positions(axis: String) -> PackedInt32Array:
	match axis:
		'x':
			return possible_positions.x
		'y':
			return possible_positions.y
		_:
			return []

func get_middle_point() -> Vector2:
	return middle_point

func get_middle_ish_adjustment() -> Vector2:
	return middle_ish_adjustment

func get_direction() -> String:
	return direction

func get_distance() -> String:
	return distance

func set_position(new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	position = _calculate_vector(new_vector, new_x, new_y)

func set_fill(axis: String, value_set: PackedInt32Array) -> void:
	match axis:
		'x':
			fill.set_x(value_set)
		'y':
			fill.set_y(value_set)

func append_fill(axis: String, added_value: int) -> void:
	match axis:
		'x':
			fill.append_x(added_value)
		'y':
			fill.append_y(added_value)

func set_potential_range(bound: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	if bound == 'min':
		potential_range.set_min(new_vector, new_x, new_y)
	elif bound == 'max':
		potential_range.set_max(new_vector, new_x, new_y)

func set_possible_positions(axis: String, value_set: PackedInt32Array) -> void:
	match axis:
		'x':
			possible_positions.set_x(value_set)
		'y':
			possible_positions.set_y(value_set)

func append_possible_positions(axis: String, added_value: int) -> void:
	match axis:
		'x':
			possible_positions.append_x(added_value)
		'y':
			possible_positions.append_y(added_value)

func set_middle_point(new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	middle_point = _calculate_vector(new_vector, new_x, new_y)

func set_middle_ish_adjustment(new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	middle_ish_adjustment = _calculate_vector(new_vector, new_x, new_y)

func set_direction(new_value: String) -> void:
	direction = new_value

func set_distance(new_value: String) -> void:
	distance = new_value

func set_random_position_by_possible_positions() -> void:
	var _x: Array = possible_positions.get_x()
	var _y: Array = possible_positions.get_y()
	position.x = _x.pick_random()
	position.y = _y.pick_random()

func set_random_position_by_potential_range() -> void:
	@warning_ignore("narrowing_conversion")
	position.x = rng.randi_range(potential_range.get_min().x, potential_range.get_max().x)
	@warning_ignore("narrowing_conversion")
	position.y = rng.randi_range(potential_range.get_min().y, potential_range.get_max().y)
