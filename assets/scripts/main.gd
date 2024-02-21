extends Node2D
class_name Main

@export_category("Core Scenes")
@export var SlimeScene: PackedScene
@export var MazeScene: PackedScene
@export_category("Logging")
@export var keep_logs: bool = false

@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var main_menu: Control = %MainMenu
@onready var logging: Node = %Logging

var start_pos: Vector2 = Vector2.ZERO
var slime: Slime
var maze: Maze
var world_size: Vector2
var end_tile_id: int

func _on_main_menu_start_game() -> void:
	# Setup Logging
	@warning_ignore("unsafe_method_access")
	logging.set_up_logging(keep_logs)
	# Instantiate world
	maze = MazeScene.instantiate()
	add_child(maze)
	move_child(maze, 0)
	# Set up links
	end_tile_id = maze.end_tile_id
	@warning_ignore("unsafe_property_access", "unsafe_call_argument", "return_value_discarded")
	maze.log_ready.connect(logging._on_maze_log_ready)
	# Build the first maze
	maze.new_game()
	#Instantiate Player
	slime = SlimeScene.instantiate()
	maze.add_child(slime)
	slime.setup_slime(end_tile_id)
	# Set up links
	@warning_ignore("unsafe_property_access", "unsafe_call_argument", "return_value_discarded")
	slime.exited.connect(maze._on_slime_exited)
	@warning_ignore("unsafe_property_access", "unsafe_call_argument", "return_value_discarded")
	maze.maze_ready.connect(slime._on_maze_maze_ready)
