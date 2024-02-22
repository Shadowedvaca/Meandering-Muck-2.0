class_name MazeMinMax
extends MazeDataCalculations

var _min: Vector2 = Vector2.ZERO
var _max: Vector2 = Vector2.ZERO

func get_min() -> Vector2:
	return _min

func get_max() -> Vector2:
	return _max

func set_min(new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	_min = _calculate_vector(new_vector, new_x, new_y)

func set_max(new_vector: Vector2 = Vector2(-1, -1), new_x: int = -1, new_y: int = -1 ) -> void:
	_max = _calculate_vector(new_vector, new_x, new_y)
