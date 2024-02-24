extends Node2D
class_name Maze

signal maze_ready(world_size: Vector2, start_pos: Vector2)
signal log_ready(filename: String, log_string: String)

# Types of selections
@export_category("Types")
# The UI exposes these as Random, Semi-Random, and Static
@export var maze_types: Array = ['Random', 'Middle-ish', 'Middle']
@export var maze_type: String = 'Random'
@export var start_end_types: Array = ['start', 'end']
@export var tile_types: Dictionary = {
	"floor": 0,
	"wall": 1,
	"start": 2,
	"end": 3
}
@export_category("Maze Configuration")
@export var maze_size: int = 10
@export var maze_growth: int = 5
@export var door_placement: Dictionary = {
	0: {
		"N": ["E","W","E","W"],
		"E": ["S","S","N","N"],
		"S": ["E","W","E","W"],
		"W": ["S","S","N","N"]
	},
	1: {
		"N": ["W","E","N","N"],
		"E": ["E","N","E","S"],
		"S": ["S","S","W","E"],
		"W": ["N","W","S","W"]
	}
}

@onready var maze_size_vector: Vector2 = Vector2(maze_size, maze_size)
@onready var maze_growth_vector: Vector2 = Vector2(maze_growth, maze_growth)
@onready var wall_tilemap: TileMap = %WallTileMap
@onready var map_size: Rect2i = wall_tilemap.get_used_rect()
@onready var tile_size: int = wall_tilemap.rendering_quadrant_size
@onready var tile_size_vector: Vector2 = Vector2(tile_size, tile_size)
@onready var world_size: Vector2 = map_size.size * tile_size
@onready var floor_tilemap: TileMap = %FloorTileMap
@onready var start_tilemap: TileMap = %StartTileMap
@onready var end_tilemap: TileMap = %EndTileMap
@onready var end_tile_id: int = end_tilemap.get_instance_id()
@onready var world_boundary_body: StaticBody2D = %WorldBoundaryBody
@onready var world_boundary: CollisionShape2D = %WorldBoundary
@onready var world_boundary_shape: WorldBoundaryShape2D = world_boundary.get_shape()
@onready var mdc: Resource = load("res://assets/scripts/maze_data.gd")

var maze: Array = []
var level_num: int = 0
var world_boundary_normal: Vector2 = Vector2.ZERO
var world_boundary_pos: Vector2 = Vector2.ZERO
var loops_done: int = 0

# Starting a new game
func new_game(maze_type_id: int = 0) -> void:
	maze_type = maze_types[maze_type_id]
	new_level()

func _on_slime_exited() -> void:
	new_level()

# advancing to a new maze
func new_level() -> void:
	level_num += 1
	make_maze()

func make_maze() -> void:
	grow_maze_size()
	set_maze_defaults()
	generate_maze_section(Vector2.ZERO, ( maze_size_vector + Vector2(-1, -1) ))
	display_maze()

func grow_maze_size() -> void:
	maze_size_vector += maze_growth_vector

func set_maze_defaults() -> void:
	maze = []
	for x: int in maze_size_vector.x:
		maze.append([])
		for y: int in maze_size_vector.y:
			if x == 0 or x == maze_size_vector.x -1 or y == 0 or y == maze_size_vector.y - 1:
				@warning_ignore("unsafe_method_access")
				maze[x].append(1);
			else:
				@warning_ignore("unsafe_method_access")
				maze[x].append(0);

func generate_maze_section(min_points: Vector2, max_points: Vector2, iteration: int = 0, quadrant: int = 0, wall_force: String = "") -> void:
	var subsequent_run: int = 0
	if iteration > 0:
		subsequent_run = 1
		loops_done += 1
	else:
		loops_done = 0
	# Set file name for maze build logging
	var filename: String = str(level_num) + "_" + str(loops_done) + "_" + str(iteration) + "_" + str(quadrant) + ".json"
	# Set up the quadrant object to have all the pertinent points of data
	@warning_ignore("unsafe_method_access")
	var maze_data: MazeData = mdc.new()
	maze_data.set_up_maze_calcs(min_points, max_points)
	# Test if there can be at least 1 row and 1 column
	if maze_data.get_open('max').x > maze_data.get_open('min').x and maze_data.get_open('max').y > maze_data.get_open('min').y:
		var wall_check: bool = make_inner_walls(maze_data)
		# If no inner walls made, skip
		if wall_check:
			var skipped_direction: String = make_doors(maze_data, iteration, wall_force)
			if iteration == 0:
				# Save the skipped direction to both outer doors
				maze_data.set_door_direction('start', -1, skipped_direction)
				# Determine where the start and end are
				make_start_end(maze_data)
			# Check to see if each chamber needs to be broken into more chambers
				# Quadrants 1-4 respectively
			var mip: Vector2 = Vector2.ZERO
			var map: Vector2 = Vector2.ZERO
			for q: int in range(1,5):
				match q:
					1:
						mip = maze_data.get_outer_wall('min')
						map = maze_data.get_inner_wall_vector('position')
					2:
						mip = Vector2(maze_data.get_inner_wall_vector('position').x, maze_data.get_outer_wall('min').y)
						map = Vector2(maze_data.get_outer_wall('max').x, maze_data.get_inner_wall_vector('position').y)
					3:
						mip = Vector2(maze_data.get_outer_wall('min').x, maze_data.get_inner_wall_vector('position').y)
						map = Vector2(maze_data.get_inner_wall_vector('position').x, maze_data.get_outer_wall('max').y)
					4:
						mip = maze_data.get_inner_wall_vector('position')
						map = maze_data.get_outer_wall('max')
				@warning_ignore("unsafe_call_argument")
				generate_maze_section(mip, map, (iteration + 1), q, door_placement[subsequent_run][skipped_direction][(q - 1)])
	# This dumps the config of the section for troubleshooting
	var maze_data_string: String = JSON.stringify(maze_data.export_to_dict(maze_type, iteration, quadrant, wall_force) , "\t", false)
	log_ready.emit(filename, maze_data_string)

func make_inner_walls(maze_data: MazeData)-> bool:
	maze_data.set_potential_range('inner_wall', maze_type)
	# Test to see if there is room for walls
	#	Assumption is that every wall must have 1 coridoor next to it
	#	+ 1 on end because range does not include the last number
	for x: int in range(maze_data.get_inner_wall_vector('potential_range', 'min').x, maze_data.get_inner_wall_vector('potential_range', 'max').x + 1 ):
		if maze[x][maze_data.get_outer_wall('min').y] == 1 and maze[x][maze_data.get_outer_wall('max').y] == 1:
			maze_data.append_inner_wall_possible_positions('x', x)
	for y: int in range(maze_data.get_inner_wall_vector('potential_range', 'min').y, maze_data.get_inner_wall_vector('potential_range', 'max').y + 1 ):
		if maze[maze_data.get_outer_wall('min').x][y] == 1 and maze[maze_data.get_outer_wall('max').x][y] == 1:
			maze_data.append_inner_wall_possible_positions('y', y)
	if not(maze_data.get_inner_wall_range('possible_positions', 'x').is_empty()) and not(maze_data.get_inner_wall_range('possible_positions', 'y').is_empty()):		# Pick random avail spots for the wall
		maze_data.set_random_position('inner_wall')
		# set bits to 1 for the walls (build the inner walls)
		for x: int in maze_data.get_inner_wall_range('fill', 'x'):
			maze[x][maze_data.get_inner_wall_vector('position').y] = 1
		for y: int in maze_data.get_inner_wall_range('fill', 'y'):
			maze[maze_data.get_inner_wall_vector('position').x][y] = 1
		# inner walls made, continue
		return true
	else:
		# no wall possible, stop
		return false

func make_doors(maze_data: MazeData, iteration: int, wall_force: String = '') -> String:
	var compass: Array = ['N', 'E', 'S', 'W']
	var skipped_wall: String
	var distance: String
	# For Middle-ish and Middle, force what wall has no door
	if wall_force != '' and maze_type != 'Random':
		skipped_wall = wall_force
	# For iteration 0 and Random, pick a random wall to have no door
	else:
		skipped_wall = compass.pick_random()
	compass.erase(skipped_wall)
	# Now set the bounds for the wall
	for c: int in len(compass):
		@warning_ignore("unsafe_call_argument")
		maze_data.set_door_direction('door', c, compass[c])
		# Calculation varies based on compass direction
		var door_pos: int = 0
		match compass[c]:
			'N':
				#Middle Point
				if ( skipped_wall == 'S' and iteration % 2 == 0 ) or ( ( skipped_wall == 'E' or skipped_wall == 'W' ) and iteration % 2 == 1 ):
					distance = 'far' # far from inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_corridor('min').y
				else:
					distance = 'near' # near to inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_inner_wall_vector('position').y - 1
				maze_data.set_door_vector('middle_point', 'door', c, Vector2(
					maze_data.get_inner_wall_vector('position').x
					,door_pos
				))
				#Middle-ish Adjustment
				maze_data.set_door_vector('middle_ish_adjustment', 'door', c, Vector2(
					0
					,int((maze_data.get_inner_wall_vector('position').y - maze_data.get_outer_wall('min').y) * maze_data.get_middle_ish_range())
				))
			'E':
				#Middle Point
				if ( skipped_wall == 'W' and iteration % 2 == 0 ) or ( ( skipped_wall == 'N' or skipped_wall == 'S' ) and iteration % 2 == 1 ):
					distance = 'far' # far from inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_corridor('max').x
				else:
					distance = 'near' # near to inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_inner_wall_vector('position').x + 1
				maze_data.set_door_vector('middle_point', 'door', c, Vector2(
					door_pos
					,maze_data.get_inner_wall_vector('position').y
				))
				#Middle-ish Adjustment
				maze_data.set_door_vector('middle_ish_adjustment', 'door', c, Vector2(
					int((maze_data.get_outer_wall('max').x - maze_data.get_inner_wall_vector('position').x) * maze_data.get_middle_ish_range())
					,0
				))
			'S':
				#Middle Point
				if ( skipped_wall == 'N' and iteration % 2 == 0 ) or ( ( skipped_wall == 'E' or skipped_wall == 'W' ) and iteration % 2 == 1 ):
					distance = 'far' # far from inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_corridor('max').y
				else:
					distance = 'near' # near to inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_inner_wall_vector('position').y + 1
				maze_data.set_door_vector('middle_point', 'door', c, Vector2(
					maze_data.get_inner_wall_vector('position').x
					,door_pos
				))
				#Middle-ish Adjustment
				maze_data.set_door_vector('middle_ish_adjustment', 'door', c, Vector2(
					0
					,int((maze_data.get_outer_wall('max').y - maze_data.get_inner_wall_vector('position').y) * maze_data.get_middle_ish_range())
				))
			'W':
				#Middle Point
				if ( skipped_wall == 'E' and iteration % 2 == 0 ) or ( ( skipped_wall == 'N' or skipped_wall == 'S' ) and iteration % 2 == 1 ):
					distance = 'far' # far from inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_corridor('min').x
				else:
					distance = 'near' # near to inner wall
					@warning_ignore("narrowing_conversion")
					door_pos = maze_data.get_inner_wall_vector('position').y - 1
				maze_data.set_door_vector('middle_point', 'door', c, Vector2(
					door_pos
					,maze_data.get_inner_wall_vector('position').y
				))
				#Middle-ish Adjustment
				maze_data.set_door_vector('middle_ish_adjustment', 'door', c, Vector2(
					int((maze_data.get_inner_wall_vector('position').x - maze_data.get_outer_wall('max').x) * maze_data.get_middle_ish_range())
					,0
				))
		maze_data.set_door_distance('door', c, distance)
		maze_data.set_potential_range('door', maze_type, 'door', c)
		maze_data.set_random_position('door', 'door', c)
		maze[maze_data.get_door_vector('position', 'door', c).x][maze_data.get_door_vector('position', 'door', c).y] = tile_types.floor
	return skipped_wall

func make_start_end(maze_data: MazeData) -> void:
	start_end_types.shuffle()
	for t: int in len(start_end_types):
		var mid_x: int
		var mid_y: int
		var adj_x: int
		var adj_y: int
		var rnd_min_x: int
		var rnd_min_y: int
		var rnd_max_x: int
		var rnd_max_y: int
		var min_max: String
		var start_end: String = start_end_types[t]
		if maze_data.get_door_direction(start_end) in ['N', 'S']:
			if t == 0:
				@warning_ignore("narrowing_conversion")
				mid_x = maze_data.get_inner_wall_vector('position').x - 1
				@warning_ignore("narrowing_conversion")
				rnd_min_x = maze_data.get_corridor('min').x
				@warning_ignore("narrowing_conversion")
				rnd_max_x = maze_data.get_inner_wall_vector('position').x - 1
			else:
				@warning_ignore("narrowing_conversion")
				mid_x = maze_data.get_inner_wall_vector('position').x + 1
				@warning_ignore("narrowing_conversion")
				rnd_min_x = maze_data.get_inner_wall_vector('position').x + 1
				@warning_ignore("narrowing_conversion")
				rnd_max_x = maze_data.get_corridor('max').x
			adj_x = int((maze_data.get_outer_wall('max').x - maze_data.get_outer_wall('min').x) * maze_data.get_middle_ish_range())
			adj_y = 0
			if t == 0:
				if mid_x - adj_x < maze_data.get_corridor('min').x:
					@warning_ignore("narrowing_conversion")
					adj_x = mid_x - maze_data.get_corridor('min').x
			else:
				if mid_x + adj_x > maze_data.get_corridor('max').x:
					@warning_ignore("narrowing_conversion")
					adj_x = mid_x + maze_data.get_corridor('max').x
			match maze_data.get_door_direction(start_end):
				'N':
					min_max = 'min'
					if t == 0:
						world_boundary_normal = Vector2.DOWN
						world_boundary_pos = Vector2(0.0, 0.0)
				'S':
					min_max = 'max'
					if t == 0:
						world_boundary_normal = Vector2.UP
						world_boundary_pos = Vector2(1.0, 1.0)
			@warning_ignore("narrowing_conversion")
			mid_y = maze_data.get_outer_wall(min_max).y
			@warning_ignore("narrowing_conversion")
			rnd_min_y = maze_data.get_outer_wall(min_max).y
			@warning_ignore("narrowing_conversion")
			rnd_max_y = maze_data.get_outer_wall(min_max).y
		elif maze_data.get_door_direction(start_end) in ['E', 'W']:
			if t == 0:
				@warning_ignore("narrowing_conversion")
				mid_y = maze_data.get_inner_wall_vector('position').y - 1
				@warning_ignore("narrowing_conversion")
				rnd_min_y = maze_data.get_corridor('min').y
				@warning_ignore("narrowing_conversion")
				rnd_max_y = maze_data.get_inner_wall_vector('position').y - 1
			else:
				@warning_ignore("narrowing_conversion")
				mid_y = maze_data.get_inner_wall_vector('position').y + 1
				@warning_ignore("narrowing_conversion")
				rnd_min_y = maze_data.get_inner_wall_vector('position').y + 1
				@warning_ignore("narrowing_conversion")
				rnd_max_y = maze_data.get_corridor('max').y
			adj_x = 0
			adj_y = int((maze_data.get_outer_wall('max').y - maze_data.get_outer_wall('min').y) * maze_data.get_middle_ish_range())
			if t == 0:
				if mid_y - adj_y < maze_data.get_corridor('min').y:
					@warning_ignore("narrowing_conversion")
					adj_y = mid_y - maze_data.get_corridor('min').y
			else:
				if mid_y + adj_y > maze_data.get_corridor('max').y:
					@warning_ignore("narrowing_conversion")
					adj_y = mid_y + maze_data.get_corridor('max').y
			match maze_data.get_door_direction(start_end):
				'E':
					min_max = 'max'
					if t == 0:
						world_boundary_normal = Vector2.LEFT
						world_boundary_pos = Vector2(1.0, 0.0)
				'W':
					min_max = 'min'
					if t == 0:
						world_boundary_normal = Vector2.RIGHT
						world_boundary_pos = Vector2(0.0, 1.0)
			@warning_ignore("narrowing_conversion")
			mid_x = maze_data.get_outer_wall(min_max).x
			@warning_ignore("narrowing_conversion")
			rnd_min_x = maze_data.get_outer_wall(min_max).x
			@warning_ignore("narrowing_conversion")
			rnd_max_x = maze_data.get_outer_wall(min_max).x
		#Middle Point
		maze_data.set_door_vector('middle_point', start_end, -1, Vector2(mid_x, mid_y))
		#Middle-ish Adjustment
		maze_data.set_door_vector('middle_ish_adjustment', start_end, -1, Vector2(adj_x, adj_y))
		if maze_type == 'Random':
			maze_data.set_door_vector('potential_range', start_end, -1, Vector2(rnd_min_x, rnd_min_y), -1, -1, 'min')
			maze_data.set_door_vector('potential_range', start_end, -1, Vector2(rnd_max_x, rnd_max_y), -1, -1, 'max')
		else:
			maze_data.set_potential_range(start_end, maze_type, '', -1, t)
		maze_data.set_random_position(start_end)
		maze[maze_data.get_door_vector('position', start_end).x][maze_data.get_door_vector('position', start_end).y] = tile_types[start_end]

func display_maze() -> void:
	var walls: Array = []
	var floors: Array = []
	var start_pos: Vector2 = Vector2.ZERO
	# Clear Tilemaps
	wall_tilemap.clear()
	floor_tilemap.clear()
	start_tilemap.clear()
	end_tilemap.clear()
	for x: int in maze_size_vector.x:
		for y: int in maze_size_vector.y:
			match maze[x][y]:
				0:
					floors.append(Vector2(x,y))
				1:
					walls.append(Vector2(x,y))
				2:
					floors.append(Vector2(x,y))
					start_tilemap.set_cell(0, Vector2(x,y), 0, Vector2.ZERO)
					# Set spawn point for player
					start_pos = ( Vector2(x,y) * tile_size_vector ) + ( tile_size_vector * .5 )
				3:
					floors.append(Vector2(x,y))
					end_tilemap.set_cell(0, Vector2(x,y), 0, Vector2(1,0))
	# This seems to work well for mazes of less than 200 height / width
		# May need to deal w/ this later, I am unsure what takes so long, my maze code or this line...
	wall_tilemap.set_cells_terrain_connect(0, walls, 0, 0)
	floor_tilemap.set_cells_terrain_connect(0, floors, 0, 0)
	# Reset sizing variables
	map_size = wall_tilemap.get_used_rect()
	world_size = map_size.size * tile_size
	# Set World Boundary to block open start so player can't leave the maze
	world_boundary_shape.set_normal(world_boundary_normal)
	world_boundary_body.set_position(world_boundary_pos * Vector2(world_size) )
	maze_ready.emit(world_size, start_pos)
