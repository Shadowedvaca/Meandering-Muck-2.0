class_name MazeData
extends MazeDataCalculations

var mmmc: Resource = load("res://assets/scripts/maze_min_max.gd")
var mpc: Resource = load("res://assets/scripts/maze_piece.gd")
@warning_ignore("unsafe_method_access")
var outer_wall: MazeMinMax = mmmc.new()
@warning_ignore("unsafe_method_access")
var corridor: MazeMinMax = mmmc.new()
@warning_ignore("unsafe_method_access")
var open: MazeMinMax = mmmc.new()
@warning_ignore("unsafe_method_access")
var inner_wall: MazePiece = mpc.new()
@warning_ignore("unsafe_method_access")
var door_0: MazePiece = mpc.new()
@warning_ignore("unsafe_method_access")
var door_1: MazePiece = mpc.new()
@warning_ignore("unsafe_method_access")
var door_2: MazePiece = mpc.new()
@warning_ignore("unsafe_method_access")
var start: MazePiece = mpc.new()
@warning_ignore("unsafe_method_access")
var end: MazePiece = mpc.new()
# if doing Middle-ish walls, do a 25% of size on either side for wall placement
var middle_ish_range: float = .25

func get_middle_ish_range() -> float:
	return middle_ish_range

func get_outer_wall(bound: String) -> Vector2:
	if bound == 'min':
		return outer_wall.get_min()
	elif bound == 'max':
		return outer_wall.get_max()
	else:
		return Vector2(-1, -1)

func get_corridor(bound: String) -> Vector2:
	if bound == 'min':
		return corridor.get_min()
	elif bound == 'max':
		return corridor.get_max()
	else:
		return Vector2(-1, -1)
		
func get_open(bound: String) -> Vector2:
	if bound == 'min':
		return open.get_min()
	elif bound == 'max':
		return open.get_max()
	else:
		return Vector2(-1, -1)

func get_inner_wall_vector(vector_type: String, bound: String = '') -> Vector2:
	var v: Vector2 = Vector2(-1, -1)
	match vector_type:
		'position':
			v = inner_wall.get_position()
		'middle_point':
			v = inner_wall.get_middle_point()
		'middle_ish_adjustment':
			v = inner_wall.get_middle_ish_adjustment()
		'potential_range':
			v = inner_wall.get_potential_range(bound)
	return v

func get_inner_wall_range(range_type: String, axis: String) -> PackedInt32Array:
	var v: PackedInt32Array = []
	match range_type:
		'fill':
			v = inner_wall.get_fill(axis)
		'possible_positions':
			v = inner_wall.get_possible_positions(axis)
	return v

func get_door_direction(door_type: String, door_number: int = -1) -> String:
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	return door.get_direction()

func get_door_distance(door_type: String, door_number: int = -1) -> String:
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	return door.get_distance()

func get_door_vector(vector_type: String, door_type: String, door_number: int = -1, bound: String = '') -> Vector2:
	var v: Vector2 = Vector2(-1, -1)
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	match vector_type:
		'position':
			v = door.get_position()
		'middle_point':
			v = door.get_middle_point()
		'middle_ish_adjustment':
			v = door.get_middle_ish_adjustment()
		'potential_range':
			v = door.get_potential_range(bound)
	return v

func set_up_maze_calcs(outer_wall_min_vector: Vector2, outer_wall_max_vector: Vector2) -> void:
	set_outer_wall('min', outer_wall_min_vector)
	set_outer_wall('max', outer_wall_max_vector)
	# Also set corridor
	set_corridor('min', outer_wall.get_min() + Vector2.ONE)
	set_corridor('max', outer_wall.get_max() - Vector2.ONE)
	# Also set inner wall middle-ish adjustment
	inner_wall.set_middle_ish_adjustment(clamp_vector_to('outer_wall', Vector2(
		int((get_outer_wall('max').x - get_outer_wall('min').x) * middle_ish_range)
		,int((get_outer_wall('max').y - get_outer_wall('min').y) * middle_ish_range)
	)))
	# Also set open
	set_open('min', corridor.get_min() + Vector2.ONE)
	set_open('max', corridor.get_max() - Vector2.ONE)
	# Also set inner wall fill
		# only draw on the corridors and open space
			# Range is not inclusive of the last number, so go to wall
	inner_wall.set_fill('x', range(corridor.get_min().x, outer_wall.get_max().x))
	inner_wall.set_fill('y', range(corridor.get_min().y, outer_wall.get_max().y))
	# Also set inner wall middle point
	inner_wall.set_middle_point(clamp_vector_to('open', Vector2(
		get_open('min').x + int((get_open('max').x - get_open('min').x) * .5)
		,get_open('min').y + int((get_open('max').y - get_open('min').y) * .5)
	)))

func set_outer_wall(bound: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	_set_maze_section_type('outer_wall', bound, new_vector, new_x, new_y)

func set_corridor(bound: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	_set_maze_section_type('corridor', bound, new_vector, new_x, new_y)

func set_open(bound: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	_set_maze_section_type('open', bound, new_vector, new_x, new_y)

func _set_maze_section_type(section_type: String, bound: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	var maze_section: MazeMinMax
	match section_type:
		'outer_wall':
			maze_section = outer_wall
		'corridor':
			maze_section = corridor
		'open':
			maze_section = open
	if bound == 'min':
		maze_section.set_min(_calculate_vector(new_vector, new_x, new_y))
	elif bound == 'max':
		maze_section.set_max(_calculate_vector(new_vector, new_x, new_y))
	

func set_inner_wall_vector(vector_type: String, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1, bound: String = '') -> void:
	match vector_type:
		'position':
			inner_wall.set_position(new_vector, new_x, new_y)
		'middle_point':
			inner_wall.set_middle_point(new_vector, new_x, new_y)
		'middle_ish_adjustment':
			inner_wall.set_middle_ish_adjustment(new_vector, new_x, new_y)
		'potential_range':
			inner_wall.set_potential_range(bound, new_vector, new_x, new_y)

func set_inner_wall_range(range_type: String, axis: String, value_set: PackedInt32Array) -> void:
	match range_type:
		'fill':
			inner_wall.set_fill(axis, value_set)
		'possible_positions':
			inner_wall.set_possible_positions(axis, value_set)

func append_inner_wall_possible_positions(axis: String, added_value: int) -> void:
	inner_wall.append_possible_positions(axis, added_value)

func set_door_direction(door_type: String, door_number: int = -1, new_value: String = '') -> void:
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	door.set_direction(new_value)
	# When the start direction is set, copy it to the end direction
	if door_type == 'start':
		end.set_direction(new_value)

func set_door_distance(door_type: String, door_number: int = -1, new_value: String = '') -> void:
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	door.set_distance(new_value)

func set_door_vector(vector_type: String, door_type: String, door_number: int = -1, new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1, bound: String = '') -> void:
	var door: MazePiece = _get_maze_piece('door', door_type, door_number)
	match vector_type:
		'position':
			door.set_position(new_vector, new_x, new_y)
		'middle_point':
			door.set_middle_point(new_vector, new_x, new_y)
		'middle_ish_adjustment':
			door.set_middle_ish_adjustment(new_vector, new_x, new_y)
		'potential_range':
			door.set_potential_range(bound, new_vector, new_x, new_y)

func _get_maze_piece(maze_piece: String, door_type: String = '', door_number: int = -1) -> MazePiece:
	var mp: MazePiece
	match maze_piece:
		'inner_wall':
			mp = inner_wall
		'start':
			mp = start
		'end':
			mp = end
		_:
			match door_type:
				'start':
					mp = start
				'end':
					mp = end
				_:
					match door_number:
							0:
								mp = door_0
							1:
								mp = door_1
							2:
								mp = door_2
	return mp

func set_potential_range(maze_piece: String, maze_type: String, door_type: String = '', door_number: int = -1, first_last: int = -1) -> void:
	var mp: MazePiece = _get_maze_piece(maze_piece, door_type, door_number)
	var clamp_to: String = 'corridor'
	match maze_type:
		'Random':
			match maze_piece:
				'door':
					match mp.get_direction():
						'N':
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('min', Vector2(-1, -1), inner_wall.get_position().x, get_corridor('min').y)
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('max', Vector2(-1, -1), inner_wall.get_position().x, inner_wall.get_position().y - 1)
						'E':
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('min', Vector2(-1, -1), inner_wall.get_position().x + 1, inner_wall.get_position().y)
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('max', Vector2(-1, -1), get_corridor('max').x, inner_wall.get_position().y)
						'S':
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('min', Vector2(-1, -1), inner_wall.get_position().x, inner_wall.get_position().y + 1)
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('max', Vector2(-1, -1), inner_wall.get_position().x, get_corridor('max').y)
						'W':
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('min', Vector2(-1, -1), get_corridor('min').x, inner_wall.get_position().y)
							@warning_ignore("narrowing_conversion")
							mp.set_potential_range('max', Vector2(-1, -1), inner_wall.get_position().x - 1, inner_wall.get_position().y)
				_:
					mp.set_potential_range('min', get_open('min'))
					mp.set_potential_range('max', get_open('max'))
		'Middle':
			mp.set_potential_range('min', mp.get_middle_point())
			mp.set_potential_range('max', mp.get_middle_point())
		'Middle-ish':
			if maze_piece == 'inner_wall':
				mp.set_potential_range('min', clamp_vector_to('open', mp.get_middle_point() - mp.get_middle_ish_adjustment()))
				mp.set_potential_range('max', clamp_vector_to('open', mp.get_middle_point() + mp.get_middle_ish_adjustment()))
			else:
				if maze_piece in ['start','end']:
					clamp_to = 'outer_wall'
				if first_last == 1 or ( mp.get_distance() == 'far' and ( mp.get_direction() in ['N', 'W'] ) ) or ( mp.get_distance() == 'near' and ( mp.get_direction() in ['S', 'E'] ) ):
					mp.set_potential_range('min', mp.get_middle_point())
					mp.set_potential_range('max', clamp_vector_to(clamp_to, mp.get_middle_point() + mp.get_middle_ish_adjustment()))
				else:
					mp.set_potential_range('min', clamp_vector_to(clamp_to, mp.get_middle_point() - mp.get_middle_ish_adjustment()))
					mp.set_potential_range('max', mp.get_middle_point())

func set_random_position(maze_piece: String, rng: RandomNumberGenerator, door_type: String = '', door_number: int = -1) -> void:
	var mp: MazePiece = _get_maze_piece(maze_piece, door_type, door_number)
	# inner wall has potential places in a range where a wall can not be placed
	if maze_piece == 'inner_wall':
		mp.set_random_position_by_possible_positions()
	# doors / start / end are placed along a range
	else:
		mp.set_random_position_by_potential_range(rng)

func clamp_vector_to(maze_part: String, vector_pos: Vector2) -> Vector2:
	var min_vector: Vector2
	var max_vector: Vector2
	match maze_part:
		'outer_wall':
			min_vector = get_outer_wall('min')
			max_vector = get_outer_wall('max')
		'corridor':
			min_vector = get_corridor('min')
			max_vector = get_corridor('max')
		'open':
			min_vector = get_open('min')
			max_vector = get_open('max')
	@warning_ignore("unsafe_call_argument")
	return Vector2(
		clamp(vector_pos.x, min_vector.x, max_vector.x)
		,clamp(vector_pos.y, min_vector.y, max_vector.y)
	)

func export_to_dict(maze_type: String, iteration: int, quadrant: int, wall_force: String) -> Dictionary:
	var return_text: Dictionary = {
		'maze_type': maze_type
		,'iteration': iteration
		,'quadrant': quadrant
		,'wall_force': wall_force
	}
	return_text.outer_walls = {
		'min': outer_wall.get_min()
		,'max': outer_wall.get_max()
	}
	return_text.corridor = {
		'min': corridor.get_min()
		,'max': corridor.get_max()
	}
	return_text.open = {
		'min': open.get_min()
		,'max': open.get_max()
	}
	return_text.inner_wall = {
		'position': inner_wall.get_position()
		,'fill': {
			'x': inner_wall.get_fill('x')
			,'y': inner_wall.get_fill('y')
		}
		,'potential_range': {
			'min': inner_wall.get_potential_range('min')
			,'max': inner_wall.get_potential_range('max')
		}
		,'possible_positions': {
			'x': inner_wall.get_possible_positions('x')
			,'y': inner_wall.get_possible_positions('y')
		}
		,'middle_point': inner_wall.get_middle_point()
		,'middle_ish_adjustment': inner_wall.get_middle_ish_adjustment()
	}
	return_text.doors = {
		'0': {
			'position': door_0.get_position()
			,'potential_range': {
				'min': door_0.get_potential_range('min')
				,'max': door_0.get_potential_range('max')
			}
			,'middle_point': door_0.get_middle_point()
			,'middle_ish_adjustment': door_0.get_middle_ish_adjustment()
			,'direction': door_0.get_direction()
			,'distance': door_0.get_distance()
		}
		,'1': {
			'position': door_1.get_position()
			,'potential_range': {
				'min': door_1.get_potential_range('min')
				,'max': door_1.get_potential_range('max')
			}
			,'middle_point': door_1.get_middle_point()
			,'middle_ish_adjustment': door_1.get_middle_ish_adjustment()
			,'direction': door_1.get_direction()
			,'distance': door_1.get_distance()
		}
		,'2': {
			'position': door_2.get_position()
			,'potential_range': {
				'min': door_2.get_potential_range('min')
				,'max': door_2.get_potential_range('max')
			}
			,'middle_point': door_2.get_middle_point()
			,'middle_ish_adjustment': door_2.get_middle_ish_adjustment()
			,'direction': door_2.get_direction()
			,'distance': door_2.get_distance()
		}
	}
	if iteration == 0:
		return_text.outer_doors = {
			'start': {
				'position': start.get_position()
				,'potential_range': {
					'min': start.get_potential_range('min')
					,'max': start.get_potential_range('max')
				}
				,'middle_point': start.get_middle_point()
				,'middle_ish_adjustment': start.get_middle_ish_adjustment()
				,'direction': start.get_direction()
			}
			,'end': {
				'position': end.get_position()
				,'potential_range': {
					'min': end.get_potential_range('min')
					,'max': end.get_potential_range('max')
				}
				,'middle_point': end.get_middle_point()
				,'middle_ish_adjustment': end.get_middle_ish_adjustment()
				,'direction': end.get_direction()
			}
		}
	return return_text
