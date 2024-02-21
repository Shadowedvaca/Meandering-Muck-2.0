class_name UI
extends CanvasLayer

@onready var level_label = %Level

var level: int = 0:
	set(new_level):
		level = new_level
		_update_level_label()

func _update_level_label() -> void:
	level_label.text = str(level)

func _ready():
	_update_level_label()

func _on_level(level) -> void:
	if level > 0:
		level += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

