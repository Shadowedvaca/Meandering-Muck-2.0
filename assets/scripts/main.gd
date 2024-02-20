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
var world_size: Vector2i
var end_tile_id: int

@warning_ignore("untyped_declaration")
# This is temporary - remove once menu testing starts
func _ready():
	# Setup Logging
	@warning_ignore("unsafe_method_access")
	logging.set_up_logging(keep_logs)
	# Instantiate world
	maze = MazeScene.instantiate()
	add_child(maze)
	move_child(maze, 0)
	# Set up links
	end_tile_id = maze.end_tile_id
	maze.log_ready.connect(logging.log_maze_data)
	# Build the first maze
	maze.new_level()
	#Instantiate Player
	slime = SlimeScene.instantiate()
	maze.add_child(slime)
	slime.setup_slime(end_tile_id)
	# Set up links
	slime.exited.connect(maze.new_level)
	maze.maze_ready.connect(slime.start)
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("untyped_declaration", "unused_parameter")
func _process(delta):
	pass

# Starting a new game
	# Move this code to the HUD when that's done
	# Use a signal to communicate this like in the demo
func new_game() -> void:
	# Setup Logging
	@warning_ignore("unsafe_method_access")
	logging.set_up_logging(keep_logs)
	# Instantiate world
	maze = MazeScene.instantiate()
	add_child(maze)
	move_child(maze, 0)
	# Set up links
	end_tile_id = maze.end_tile_id
	maze.log_ready.connect(logging.log_maze_data)
	# Build the first maze
	maze.new_level()
	#Instantiate Player
	slime = SlimeScene.instantiate()
	maze.add_child(slime)
	slime.setup_slime(end_tile_id)
	# Set up links
	slime.exited.connect(maze.new_level)
	maze.maze_ready.connect(slime.start)

#func display_maze():
	#var walls = []
	#var floors = []
	# Clear Tilemaps
	#wall_tilemap.clear()
	#floor_tilemap.clear()
	#start_tilemap.clear()
	#end_tilemap.clear()
	#for x in maze_size_vector.x:
		#for y in maze_size_vector.y:
			#match maze[x][y]:
				#0:
					#floors.append(Vector2i(x,y))
				#1:
					#walls.append(Vector2i(x,y))
				#2:
					#floors.append(Vector2i(x,y))
					#start_tilemap.set_cell(0, Vector2i(x,y), 0, Vector2i.ZERO)
					# Set spawn point for player
					#start_pos = Vector2(x,y) <-- This is key, how do I do this?
				#3:
					#floors.append(Vector2i(x,y))
					#end_tilemap.set_cell(0, Vector2i(x,y), 0, Vector2i(1,0))
	# This seems to work well for mazes of less than 200 height / width
		# May need to deal w/ this later, I am unsure what takes so long, my maze code or this line...
	#wall_tilemap.set_cells_terrain_connect(0, walls, 0, 0)
	#floor_tilemap.set_cells_terrain_connect(0, floors, 0, 0)
	# Reset sizing variables
	#map_size = wall_tilemap.get_used_rect()
	#world_size = map_size.size * tile_size
	# Set World Boundary to block open start so player can't leave the maze
	#world_boundary_shape.set_normal(world_boundary_normal)
	#world_boundary_body.set_position(world_boundary_pos * Vector2(world_size) )
	# Set up camera
	#$Slime/FollowCam.set_up_camera() <-- This is key, how do I do this?
	# Spawn Player
	#start_pos = ( start_pos * tile_size_vector ) + ( tile_size_vector * .5 ) <-- This is key, how do I do this?
	#slime.start(start_pos) <-- This is key, how do I do this?

