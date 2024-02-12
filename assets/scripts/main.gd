extends Node

var maze = []
var rng = RandomNumberGenerator.new()
var level_num: int = 0
var world_boundary_normal = Vector2(0, 0)
var world_boundary_pos = Vector2(0, 0)
@export var maze_size: int = 10
@onready var maze_size_vector = Vector2i(maze_size, maze_size)
@export var maze_growth: int = 5
@onready var maze_growth_vector = Vector2i(maze_growth, maze_growth)
@onready var wall_tilemap = $WallTileMap
@onready var floor_tilemap = $FloorTileMap
@onready var start_tilemap = $StartTileMap
@onready var end_tilemap = $EndTileMap
@onready var slime = $Slime
@onready var world_boundary_body = $StaticBody2D
@onready var world_boundary = $StaticBody2D/WorldBoundary
@onready var end_tile_id = $EndTileMap.get_instance_id()
@onready var map_size = wall_tilemap.get_used_rect()
@onready var tile_size = wall_tilemap.rendering_quadrant_size
@onready var tile_size_vector = Vector2(tile_size, tile_size)
@onready var world_size = map_size.size * tile_size


func _ready():
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Starting a new game
	# Move this code to the HUD when that's done
	# Use a signal to communicate this like in the demo
func new_game():
	rng.randomize()
	new_level()

# advancing to a new maze
func new_level():
	level_num += 1
	make_maze()
	

func make_maze():
	grow_maze_size()
	set_maze_defaults()
	generate_maze_section(Vector2i(0, 0), ( maze_size_vector + Vector2i(-1, -1) ), 0)
	display_maze()
	
func grow_maze_size():
	maze_size_vector += maze_growth_vector

	
func set_maze_defaults():
	maze = []
	for x in maze_size_vector.x:
		maze.append([])
		for y in maze_size_vector.y:
			if x == 0 or x == maze_size_vector.x -1 or y == 0 or y == maze_size_vector.y - 1:
				maze[x].append(1);
			else:
				maze[x].append(0);

func generate_maze_section(min_points: Vector2i, max_points: Vector2i, iteration: int, quadrant: int = 0):
	var skip = 0
	var wall_point = Vector2i(0, 0)
	var one_cell = Vector2i(1, 1)
	# These are the walls around the section
	var min_wall: Vector2i = min_points
	var max_wall: Vector2i = max_points
	# These are the mandatory corridors by those walls
	var min_corr: Vector2i = min_wall + one_cell
	var max_corr: Vector2i = max_wall - one_cell
	# This draws out the open space in the maze
	var min_open: Vector2i = min_corr + one_cell
	var max_open: Vector2i = max_corr - one_cell
	# only draw on the corridors and open space
		# Range is not inclusive of the last number, so go to wall
	var wall_fill_x = range(min_corr.x, max_wall.x)
	var wall_fill_y = range(min_corr.y, max_wall.y)
	# used to pick where doors go
	var compass = ['N', 'E', 'S', 'W']
	var direction_id = 0
	var direction = ''
	var door_types = [2, 3]
	# The cooridors are automatically invalid
	var invalid_cols = []
	var invalid_rows = []
	# Types of selections
	var wall_types = ['Random', 'Middle-ish', 'Middle']
	var wall_type = 'Random'
	# Marks the start and end of the random wall placement
	var wall_min = Vector2i(0, 0)
	var wall_max = Vector2i(0, 0)
	# Marks the mid point
	var mid_open = Vector2i(min_open.x + int((max_open.x - min_open.x) * .5), min_open.y + int((max_open.y - min_open.y) * .5))
	# if doing Middle-ish walls, do a 25% of size on either side for wall placement
	var mid_either_side = .25
	var mid_adjust = Vector2i(int((max_wall.x - min_wall.x) * mid_either_side), int((max_wall.y - min_wall.y) * mid_either_side))
	# Test if there can be at least 1 row and 1 column
	if max_open.x > min_open.x and max_open.y > min_open.y:
		# If a type of wall is not selected, pick one of the three
			# shuffle the types and pick the first
		if wall_type == '':
			wall_types.shuffle()
			wall_type = wall_type[0]
		match wall_type:
			'Random':
				wall_min = Vector2i(min_open.x, min_open.y)
				wall_max = Vector2i(max_open.x, max_open.y)
			'Middle':
				wall_min = Vector2i(mid_open.x, mid_open.y)
				wall_max = wall_min
			'Middle-ish':
				wall_min = Vector2i(mid_open.x - mid_adjust.x, mid_open.y - mid_adjust.y)
				wall_max = Vector2i(mid_open.x + mid_adjust.x, mid_open.y + mid_adjust.y)
		# Test to see if there is room for walls
		#	Assumption is that every wall must have 1 coridoor next to it
		for x in range(wall_min.x, (wall_max.x + 1)):
			if maze[x][min_wall.y] != 1 or maze[x][max_wall.y] != 1:
				invalid_rows.append(x)
		for y in range(wall_min.y, (wall_max.y + 1)):
			if maze[min_wall.x][y] != 1 or maze[max_wall.x][y] != 1:
				invalid_cols.append(y)
		# check for corridors that are too small for a wall due to the 1 space on either side limit and door positioning
		if not((wall_max.x - wall_min.x) + 1) <= len(invalid_rows) and not((wall_max.y - wall_min.y) + 1) <= len(invalid_cols):
			# Pick random numbers until a good one is found
			while wall_point.x == 0 or wall_point.x in invalid_rows:
				wall_point.x = rng.randi_range(wall_min.x, wall_max.x)
			while wall_point.y == 0 or wall_point.y in invalid_cols:
				wall_point.y = rng.randi_range(wall_min.y, wall_max.y)
			# set bits to 1 for the walls
			for x in wall_fill_x:
				maze[x][wall_point.y] = 1
			for y in wall_fill_y:
				maze[wall_point.x][y] = 1
			var passes = 1
			while len(compass) > 1:
				direction_id = rng.randi_range(0, len(compass) - 1)
				direction = compass.pop_at(direction_id)
				passes += 1
				match direction:
					'N':
						make_door('x', wall_point.x, min_corr.y, (wall_point.y - 1), 0)
					'E':
						make_door('y', wall_point.y, (wall_point.x + 1), max_corr.x, 0)
					'S':
						make_door('x', wall_point.x, (wall_point.y + 1), max_corr.y, 0)
					'W':
						make_door('y', wall_point.y, min_corr.x, (wall_point.x - 1), 0)
			# Determine where the start and end are
			if iteration == 0:
				door_types.shuffle()
				match compass[0]:
					'N':
						make_door('y', min_wall.y, (wall_point.x + 1), (wall_point.x + 1), door_types[0])
						make_door('y', min_wall.y, (wall_point.x - 1), (wall_point.x - 1), door_types[1])
						world_boundary_normal = Vector2.DOWN
						world_boundary_pos = Vector2(0.0, 0.0)
					'E':
						make_door('x', max_wall.x, (wall_point.y + 1), (wall_point.y + 1), door_types[0])
						make_door('x', max_wall.x, (wall_point.y - 1), (wall_point.y - 1), door_types[1])
						world_boundary_normal = Vector2.LEFT
						world_boundary_pos = Vector2(1.0, 0.0)
					'S':
						make_door('y', max_wall.y, (wall_point.x + 1), (wall_point.x + 1), door_types[0])
						make_door('y', max_wall.y, (wall_point.x - 1), (wall_point.x - 1), door_types[1])
						world_boundary_normal = Vector2.UP
						world_boundary_pos = Vector2(1.0, 1.0)
					'W':
						make_door('x', min_wall.x, (wall_point.y + 1), (wall_point.y + 1), door_types[0])
						make_door('x', min_wall.x, (wall_point.y - 1), (wall_point.y - 1), door_types[1])
						world_boundary_normal = Vector2.RIGHT
						world_boundary_pos = Vector2(0.0, 1.0)
			# Check to see if each chamber needs to be broken into more chambers
				# Quadrants 1-4 respectively
			generate_maze_section(min_wall, wall_point, (iteration + 1), 1)
			generate_maze_section(Vector2i(wall_point.x, min_wall.y), Vector2i(max_wall.x, wall_point.y), (iteration + 1), 2)
			generate_maze_section(Vector2i(min_wall.x, wall_point.y), Vector2i(wall_point.x, max_wall.y), (iteration + 1), 3)
			generate_maze_section(wall_point, max_wall, (iteration + 1), 4)

func make_door(axis: String, wall_point: int, min_d: int, max_d: int, door_type: int):
	var door_point: int = rng.randi_range(min_d, max_d)
	if axis == 'x':
		maze[wall_point][door_point] = door_type
	else:
		maze[door_point][wall_point] = door_type

func display_maze():
	var walls = []
	var floors = []
	var start_pos = Vector2(0, 0)
	# World Boundary Setup
	var world_boundary_shape = world_boundary.get_shape()
	# Clear Tilemaps
	wall_tilemap.clear()
	floor_tilemap.clear()
	start_tilemap.clear()
	end_tilemap.clear()
	for x in maze_size_vector.x:
		for y in maze_size_vector.y:
			match maze[x][y]:
				0:
					floors.append(Vector2i(x,y))
				1:
					walls.append(Vector2i(x,y))
				2:
					floors.append(Vector2i(x,y))
					start_tilemap.set_cell(0, Vector2i(x,y), 0, Vector2i(0,0))
					# Set spawn point for player
					start_pos = Vector2(x,y)
				3:
					floors.append(Vector2i(x,y))
					end_tilemap.set_cell(0, Vector2i(x,y), 0, Vector2i(1,0))
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
	world_boundary.set_position(world_boundary_pos * Vector2(world_size) )
	# Set up camera
	$Slime/FollowCam.set_up_camera()
	# Spawn Player
	start_pos = ( start_pos * tile_size_vector ) + ( tile_size_vector * Vector2(0.5, 0.5) )
	slime.start(start_pos)
