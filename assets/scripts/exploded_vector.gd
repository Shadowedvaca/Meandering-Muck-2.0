class_name ExplodedVector
extends MazeDataCalculations

var x: PackedInt32Array = []
var y: PackedInt32Array = []

func get_x() -> PackedInt32Array:
	return x

func get_y() -> PackedInt32Array:
	return y

func set_x(value_set: PackedInt32Array) -> void:
	x = value_set

func set_y(value_set: PackedInt32Array) -> void:
	y = value_set

func append_x(added_value: int) -> void:
	@warning_ignore("return_value_discarded")
	x.append(added_value)

func append_y(added_value: int) -> void:
	@warning_ignore("return_value_discarded")
	y.append(added_value)
