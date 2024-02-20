class_name MazeDataCalculations
extends Resource

func _get_one_axis(axis: String, vector_list: PackedVector2Array) -> PackedInt32Array:
	var a: PackedInt32Array = []
	for v: Vector2 in vector_list:
		if v[axis] > -1:
			@warning_ignore("return_value_discarded", "narrowing_conversion")
			a.append(v[axis])
	return a

func _set_one_axis(axis: String, value_set: PackedInt32Array = [], single_value: int = -1) -> PackedVector2Array:
	var x: int = -1
	var y: int = -1
	var return_set: PackedVector2Array = []
	if single_value > -1:
		if axis == 'x':
			x = single_value
		elif axis == 'y':
			y = single_value
		@warning_ignore("return_value_discarded")
		return_set.append(Vector2(x, y))
	else:
		for v: int in value_set:
			if axis == 'x':
				x = v
			elif axis == 'y':
				y = v
			@warning_ignore("return_value_discarded")
			return_set.append(Vector2(x, y))
	return return_set

func _calculate_vector(new_vector: Vector2, new_x: int, new_y: int) -> Vector2:
	var new_value: Vector2
	if new_vector != Vector2(-1, -1):
		new_value = new_vector
	else:
		new_value = Vector2(new_x, new_y)
	return new_value
