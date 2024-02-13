extends Node

var maze = []
var rng = RandomNumberGenerator.new()
var level_num: int = 0
var world_boundary_normal = Vector2.ZERO
var world_boundary_pos = Vector2.ZERO
# Types of selections
@export var maze_types = ['Random', 'Middle-ish', 'Middle']
@export var maze_type: String = 'Random'
@export var start_end_types = ['start', 'end']
@export var tile_types = {
	"floor": 0,
	"wall": 1,
	"start": 2,
	"end": 3
}
# if doing Middle-ish walls, do a 25% of size on either side for wall placement
@export var middle_ish_range: float = .25
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
@onready var world_boundary_shape = world_boundary.get_shape()


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
	set_maze_format()
	generate_maze_section(Vector2i.ZERO, ( maze_size_vector + Vector2i(-1, -1) ), 0)
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

func set_maze_format():
	# If a type of wall is not selected, pick one of the three
		# shuffle the types and pick the first
	if maze_type == '':
		maze_types.shuffle()
		maze_type = maze_types[0]

func generate_maze_section(min_points: Vector2i, max_points: Vector2i, iteration: int, quadrant: int = 0):
	var skip = 0
	var wall_point = Vector2i.ZERO
	# used to pick where doors go
	var compass = ['N', 'E', 'S', 'W']
	var direction_id = 0
	var direction = ''
	# Set up the quadrant object to have all the pertinent points of data
	var section_cfg = {
		"iteration": iteration
		,"quadrant": quadrant
		,"outer_wall": { # These are the outer walls (what is passed to generate)
			"min": min_points
			,"max": max_points
		}
	}
	section_cfg["corridor"] = { # This is the mandatory corridor outside the outer wall
		"min": section_cfg.outer_wall.min + Vector2i.ONE
		,"max": section_cfg.outer_wall.max - Vector2i.ONE
	}
	section_cfg["open"] = { # This is the area inside the quadrant that is potentially open for wall placement
		"min": section_cfg.corridor.min + Vector2i.ONE
		,"max": section_cfg.corridor.max - Vector2i.ONE
	}
	# only draw on the corridors and open space
		# Range is not inclusive of the last number, so go to wall
	section_cfg["inner_wall_fill"] = {
		"x" = range(section_cfg.corridor.min.x, section_cfg.outer_wall.max.x)
		,"y" = range(section_cfg.corridor.min.y, section_cfg.outer_wall.max.y)
	}
	section_cfg["inner_wall_potential"] = { # This where the wall could be placed based on the maze_type
		# These are the possible ranges
		"min": Vector2i.ZERO
		,"max": Vector2i.ZERO
		# These are the possible locations between those ranges
		,"x": []
		,"y": []
	}
	section_cfg.middle_point = Vector2i( # This is used for Middle and is the center
		section_cfg.open.min.x + int((section_cfg.open.max.x - section_cfg.open.min.x) * .5)
		,section_cfg.open.min.y + int((section_cfg.open.max.y - section_cfg.open.min.y) * .5)
	)
	section_cfg.middle_ish_adjustment = Vector2i(
		int((section_cfg.outer_wall.max.x - section_cfg.outer_wall.min.x) * middle_ish_range)
		,int((section_cfg.outer_wall.max.y - section_cfg.outer_wall.min.y) * middle_ish_range)
	)
	section_cfg.inner_wall = Vector2i.ZERO # This is the chosen inner wall intersection
	# Test if there can be at least 1 row and 1 column
	if section_cfg.open.max.x > section_cfg.open.min.x and section_cfg.open.max.y > section_cfg.open.min.y:
		
		# WALL CODE
		
		match maze_type:
			'Random':
				section_cfg.inner_wall_potential.min = Vector2i(section_cfg.open.min.x
																, section_cfg.open.min.y)
				section_cfg.inner_wall_potential.max = Vector2i(section_cfg.open.max.x
																, section_cfg.open.max.y)
			'Middle':
				section_cfg.inner_wall_potential.min = Vector2i(section_cfg.middle_point.x
																, section_cfg.middle_point.y)
				section_cfg.inner_wall_potential.max = section_cfg.inner_wall.min
			'Middle-ish':
				section_cfg.inner_wall_potential.min = Vector2i(section_cfg.middle_point.x - section_cfg.middle_ish_adjustment.x
																, section_cfg.middle_point.y - section_cfg.middle_ish_adjustment.y)
				section_cfg.inner_wall_potential.max = Vector2i(section_cfg.middle_point.x + section_cfg.middle_ish_adjustment.x
																, section_cfg.middle_point.y + section_cfg.middle_ish_adjustment.y)
		# Test to see if there is room for walls
		#	Assumption is that every wall must have 1 coridoor next to it
		#	+ 1 on end because range does not include the last number
		for x in range(section_cfg.inner_wall_potential.min.x, (section_cfg.inner_wall_potential.max.x + 1)):
			if maze[x][section_cfg.outer_wall.min.y] == 1 and maze[x][section_cfg.outer_wall.max.y] == 1:
				section_cfg.inner_wall_potential.x.append(x)
		for y in range(section_cfg.inner_wall_potential.min.y, (section_cfg.inner_wall_potential.max.y + 1)):
			if maze[section_cfg.outer_wall.min.x][y] == 1 and maze[section_cfg.outer_wall.max.x][y] == 1:
				section_cfg.inner_wall_potential.y.append(y)
		# check for corridors that are too small for a wall due to the 1 space on either side limit and door positioning
		if not(section_cfg.inner_wall_potential.x.is_empty()) and not(section_cfg.inner_wall_potential.y.is_empty()):
			
			# WALL CODE
			
			section_cfg.inner_wall_potential.x.shuffle()
			section_cfg.inner_wall.x = section_cfg.inner_wall_potential.x[0]
			section_cfg.inner_wall_potential.y.shuffle()
			section_cfg.inner_wall.y = section_cfg.inner_wall_potential.y[0]
			# set bits to 1 for the walls
			for x in section_cfg.inner_wall_fill.x:
				maze[x][section_cfg.inner_wall.y] = 1
			for y in section_cfg.inner_wall_fill.y:
				maze[section_cfg.inner_wall.x][y] = 1
			
			# DOOR CODE
			
			var passes = 1
			while len(compass) > 1:
				direction_id = rng.randi_range(0, len(compass) - 1)
				direction = compass.pop_at(direction_id)
				passes += 1
				match direction:
					'N':
						make_door('x', section_cfg.inner_wall.x, section_cfg.corridor.min.y, (section_cfg.inner_wall.y - 1), 0)
					'E':
						make_door('y', section_cfg.inner_wall.y, (section_cfg.inner_wall.x + 1), section_cfg.corridor.max.x, 0)
					'S':
						make_door('x', section_cfg.inner_wall.x, (section_cfg.inner_wall.y + 1), section_cfg.corridor.max.y, 0)
					'W':
						make_door('y', section_cfg.inner_wall.y, section_cfg.corridor.min.x, (section_cfg.inner_wall.x - 1), 0)
			# Determine where the start and end are
			if iteration == 0:
				start_end_types.shuffle()
				match compass[0]:
					'N':
						make_door('y', section_cfg.outer_wall.min.y, (section_cfg.inner_wall.x + 1), (section_cfg.inner_wall.x + 1), tile_types[start_end_types[0]])
						make_door('y', section_cfg.outer_wall.min.y, (section_cfg.inner_wall.x - 1), (section_cfg.inner_wall.x - 1), tile_types[start_end_types[1]])
						world_boundary_normal = Vector2.DOWN
						world_boundary_pos = Vector2(0.0, 0.0)
					'E':
						make_door('x', section_cfg.outer_wall.max.x, (section_cfg.inner_wall.y + 1), (section_cfg.inner_wall.y + 1), tile_types[start_end_types[0]])
						make_door('x', section_cfg.outer_wall.max.x, (section_cfg.inner_wall.y - 1), (section_cfg.inner_wall.y - 1), tile_types[start_end_types[1]])
						world_boundary_normal = Vector2.LEFT
						world_boundary_pos = Vector2(1.0, 0.0)
					'S':
						make_door('y', section_cfg.outer_wall.max.y, (section_cfg.inner_wall.x + 1), (section_cfg.inner_wall.x + 1), tile_types[start_end_types[0]])
						make_door('y', section_cfg.outer_wall.max.y, (section_cfg.inner_wall.x - 1), (section_cfg.inner_wall.x - 1), tile_types[start_end_types[1]])
						world_boundary_normal = Vector2.UP
						world_boundary_pos = Vector2(1.0, 1.0)
					'W':
						make_door('x', section_cfg.outer_wall.min.x, (section_cfg.inner_wall.y + 1), (section_cfg.inner_wall.y + 1), tile_types[start_end_types[0]])
						make_door('x', section_cfg.outer_wall.min.x, (section_cfg.inner_wall.y - 1), (section_cfg.inner_wall.y - 1), tile_types[start_end_types[1]])
						world_boundary_normal = Vector2.RIGHT
						world_boundary_pos = Vector2(0.0, 1.0)
			# Check to see if each chamber needs to be broken into more chambers
				# Quadrants 1-4 respectively
			generate_maze_section(section_cfg.outer_wall.min, section_cfg.inner_wall, (iteration + 1), 1)
			generate_maze_section(Vector2i(section_cfg.inner_wall.x, section_cfg.outer_wall.min.y), Vector2i(section_cfg.outer_wall.max.x, section_cfg.inner_wall.y), (iteration + 1), 2)
			generate_maze_section(Vector2i(section_cfg.outer_wall.min.x, section_cfg.inner_wall.y), Vector2i(section_cfg.inner_wall.x, section_cfg.outer_wall.max.y), (iteration + 1), 3)
			generate_maze_section(section_cfg.inner_wall, section_cfg.outer_wall.max, (iteration + 1), 4)
	print(section_cfg)

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
					start_tilemap.set_cell(0, Vector2i(x,y), 0, Vector2i.ZERO)
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
	# Set up camera
	$Slime/FollowCam.set_up_camera()
	# Spawn Player
	start_pos = ( start_pos * tile_size_vector ) + ( tile_size_vector * .5 )
	slime.start(start_pos)
