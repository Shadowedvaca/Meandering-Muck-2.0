class_name Logging
extends Node

@onready var session_log_dir: String = "user://sessions/" + Time.get_datetime_string_from_system().replace(":","") + "/"

var keep_logs_saved: bool

# Called when the node enters the scene tree for the first time.
@warning_ignore("untyped_declaration")
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("untyped_declaration", "unused_parameter")
func _process(delta):
	pass

func set_up_logging(keep_logs: bool = false) -> void:
	keep_logs_saved = keep_logs
	var directory: DirAccess = DirAccess.open("user://")
	var err: Error = directory.make_dir_recursive(session_log_dir)
	# Put this out to logs if populated
	print(err)

func clean_up_logs() -> void:
	if not(keep_logs_saved):
		var err: Error = OS.move_to_trash(ProjectSettings.globalize_path(session_log_dir))
		# Put this out to logs if populated
		print(err)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		clean_up_logs()

func log_maze_data(filename: String, maze_data_string: String) -> void:
	var file: FileAccess = FileAccess.open(session_log_dir + filename, FileAccess.WRITE)
	file.store_string(maze_data_string)
	file.close()
