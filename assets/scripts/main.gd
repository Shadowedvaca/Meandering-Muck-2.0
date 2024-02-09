extends Node

var maze = []
var screen_size = Vector2i(1920, 1080)
var maze_size = Vector2i(10, 10)
var maze_growth = Vector2i(10, 10)
var rng = RandomNumberGenerator.new()
var cell_size = Vector2i(16, 16)
var level_num: int = 0
@onready var wall_tilemap = $WallTileMap
@onready var floor_tilemap = $FloorTileMap
@onready var start_tilemap = $StartTileMap
@onready var end_tilemap = $EndTileMap
@onready var slime = $Slime
@onready var end_tile_id = $EndTileMap.get_instance_id()
@onready var start_tile_id = $StartTileMap.get_instance_id()

#MVP Notes
	# BUG!  The player starting movement is broken.
			# Right now, the player spawns and collides and adjusts and leaves the player out of the map or between walls
			# If Start does not have collision (like before) the player can leave the map through the start cell
		# Ideas
			# Maybe the collision shape disabling/enabling section is to blame
				# Player moves and collides and then it spins them out
				# If collision was off for the player for all this, then there would be no collisions
				# Need to turn player input off as well
				# Yes, do all of this
					# Also, need to combine Start/End again and have no collision on start
			# Outer Rect w/ collision (saw on google)
				# Feels like a last straw kind of thing
		# Then control speed scale as levels increase
	# Then figure out the screen scaling note below
		# Think I need a single scaling that I use for all maze size and scroll the maze as it gets bigger
			# Using a camera functionality?
	# Then improve maze code (see notes there)
	# Then make title screen w/ options menu, start game, quit game options
		# Plus a loading screen
	# Make options screen able to configure screen mode and size
		# Maybe allow user to enter a seed for the rng and select wall and door modes?
	# I think when all this is done, that is my MVP
	# Features
		# Timer per level

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
	generate_maze_section(Vector2i(0, 0), Vector2i(maze_size.x - 1, maze_size.y - 1), 0)
	display_maze()
	
func grow_maze_size():
	maze_size.x += maze_growth.x
	maze_size.y += maze_growth.y
	
func set_maze_defaults():
	maze = []
	for x in maze_size.x:
		maze.append([])
		for y in maze_size.y:
			if x == 0 or x == maze_size.x -1 or y == 0 or y == maze_size.y - 1:
				maze[x].append(1);
			else:
				maze[x].append(0);

# make a function that creates the start and end
	# all styles of it and then I can choose which I use
# make a function that creates 3 doors
	# both the hard coded and the random ones
# make a function that creates walls
# work this in
	#start_vector = maze_array.find(2)
	#end_vector = maze_array.find(3)
# Note from 2/1 - after I get this working, simplify the positioning variable w/ a new object
# Note from 2/5 - need to get the different door options to work (middle doesn't work well w/ a random door)
	# Also, This generate maze section can prolly be cut into pieces
func generate_maze_section(min_points: Vector2i, max_points: Vector2i, iteration: int, quadrant: int = 0):
	#print("Iteration = " + str(iteration) + " Quadrant = " + str(quadrant))
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
		#print("invalid rows = " + str(invalid_rows))
		#print("invalid cols = " + str(invalid_cols))
		# check for corridors that are too small for a wall due to the 1 space on either side limit and door positioning
		if not((wall_max.x - wall_min.x) + 1) <= len(invalid_rows) and not((wall_max.y - wall_min.y) + 1) <= len(invalid_cols):
			# Pick random numbers until a good one is found
			#print("wall point x")
			while wall_point.x == 0 or wall_point.x in invalid_rows:
				wall_point.x = rng.randi_range(wall_min.x, wall_max.x)
				#print(wall_point.x)
			#print("wall point y")
			while wall_point.y == 0 or wall_point.y in invalid_cols:
				wall_point.y = rng.randi_range(wall_min.y, wall_max.y)
				#print(wall_point.y)
			# set bits to 1 for the walls
			for x in wall_fill_x:
				maze[x][wall_point.y] = 1
			for y in wall_fill_y:
				maze[wall_point.x][y] = 1
			var passes = 1
			#print('iteration = ' + str(iteration))
			while len(compass) > 1:
				direction_id = rng.randi_range(0, len(compass) - 1)
				direction = compass.pop_at(direction_id)
				#print('pass = ' + str(passes))
				#print(compass)
				passes += 1
				#print("Direction = " + direction)
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
					'E':
						make_door('x', max_wall.x, (wall_point.y + 1), (wall_point.y + 1), door_types[0])
						make_door('x', max_wall.x, (wall_point.y - 1), (wall_point.y - 1), door_types[1])
					'S':
						make_door('y', max_wall.y, (wall_point.x + 1), (wall_point.x + 1), door_types[0])
						make_door('y', max_wall.y, (wall_point.x - 1), (wall_point.x - 1), door_types[1])
					'W':
						make_door('x', min_wall.x, (wall_point.y + 1), (wall_point.y + 1), door_types[0])
						make_door('x', min_wall.x, (wall_point.y - 1), (wall_point.y - 1), door_types[1])
			# Check to see if each chamber needs to be broken into more chambers
				# Quadrants 1-4 respectively
			generate_maze_section(min_wall, wall_point, (iteration + 1), 1)
			generate_maze_section(Vector2i(wall_point.x, min_wall.y), Vector2i(max_wall.x, wall_point.y), (iteration + 1), 2)
			generate_maze_section(Vector2i(min_wall.x, wall_point.y), Vector2i(wall_point.x, max_wall.y), (iteration + 1), 3)
			generate_maze_section(wall_point, max_wall, (iteration + 1), 4)

func make_start_end():
	pass

func make_multi_door():
	pass

func make_door(axis: String, wall_point: int, min_d: int, max_d: int, door_type: int):
	var door_point: int = rng.randi_range(min_d, max_d)
	if axis == 'x':
		#print("door at: (" + str(wall_point) + ", " + str(door_point) + ")")
		maze[wall_point][door_point] = door_type
	else:
		#print("door at: (" + str(door_point) + ", " + str(wall_point) + ")")
		maze[door_point][wall_point] = door_type

func display_maze():
	var walls = []
	var floors = []
	var start_pos = Vector2(0, 0)
	# Clear Tilemaps
	wall_tilemap.clear()
	floor_tilemap.clear()
	start_tilemap.clear()
	end_tilemap.clear()
	for x in maze_size.x:
		for y in maze_size.y:
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
	# this sucks, need to set the scale of the game to a certain size and the center the dungeon...
	var scale_size = Vector2(
		(( screen_size.x * 1.0 ) / ( cell_size.x * 1.0 ) / ( maze_size.x  * 1.0 ) ),
		( ( screen_size.y * 1.0 ) / ( cell_size.y * 1.0 ) / ( maze_size.y  * 1.0 ))
	)
	wall_tilemap.scale = scale_size
	floor_tilemap.scale = scale_size
	start_tilemap.scale = scale_size
	end_tilemap.scale = scale_size
	slime.scale = scale_size * .75
	# Spawn Player
	start_pos = Vector2(
		( start_pos.x * ( cell_size.x * scale_size.x ) ) + ( ( cell_size.x * scale_size.x ) / 2 ),
		( start_pos.y * ( cell_size.y * scale_size.y ) ) + ( ( cell_size.y * scale_size.y ) / 2 )
		#( ( start_pos.x * 1.0 ) * ( cell_size.x * 1.0 ) ) + ( ( cell_size.x * 1.0 ) / 2 ) * ( scale_size.x * 1.0 ),
		#( ( start_pos.y * 1.0 ) * ( cell_size.y * 1.0 ) ) + ( ( cell_size.y * 1.0 ) / 2 ) * ( scale_size.y * 1.0 )
	)
	slime.start(start_pos)


# what functions do I need?
	# _init_
		# Initial values
		# Calls new_maze
	# new maze
		# Grows maze
		# calls generate maze section
	# generate maze section
		# code to add walls and doors, then run in each quadrant
	# get maze
		# just returns the maze itself
	# get start (returns vector)
		# searches array for 2
	# get end (returns vector)
		# searches array for 3
	
