class_name MazeDataCalculations
extends Resource

func _calculate_vector(new_vector: Vector2, new_x: int, new_y: int) -> Vector2:
	var new_value: Vector2
	if new_vector != Vector2(-1, -1):
		new_value = new_vector
	else:
		new_value = Vector2(new_x, new_y)
	return new_value
