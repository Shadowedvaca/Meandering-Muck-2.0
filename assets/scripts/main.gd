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
@export var door_placement = {
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
@onready var session_log_dir = "user://sessions/" + Time.get_datetime_string_from_system().replace(":","") + "/"
@export var keep_logs: bool = false
@onready var loops_done: int = 0


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
	set_up_logging()
	new_level()

func set_up_logging():
	var directory = DirAccess.open("user://")
	directory.make_dir_recursive(session_log_dir)


# advancing to a new maze
func new_level():
	level_num += 1
	make_maze()
	

func make_maze():
	grow_maze_size()
	set_maze_defaults()
	set_maze_format()
	generate_maze_section(Vector2i.ZERO, ( maze_size_vector + Vector2i(-1, -1) ))
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
	if maze_type == '':
		maze_type = maze_types.pick_random()

func generate_maze_section(min_points: Vector2i, max_points: Vector2i, iteration: int = 0, quadrant: int = 0, wall_force: String = ""):
	var subsequent_run: int = 0
	if iteration > 0:
		subsequent_run = 1
		loops_done += 1
	else:
		loops_done = 0
	# Set file name for maze build logging
	var filename = str(level_num) + "_" + str(loops_done) + "_" + str(iteration) + "_" + str(quadrant) + ".json"
	# Set up the quadrant object to have all the pertinent points of data
	var section_cfg = {
		"maze_type": maze_type
		,"iteration": iteration
		,"quadrant": quadrant
		,"wall_force": wall_force
		,"outer_wall": { # These are the outer walls (what is passed to generate)
			"min": min_points
			,"max": max_points
		}
	}
	section_cfg.corridor = { # This is the mandatory corridor outside the outer wall
		"min": section_cfg.outer_wall.min + Vector2i.ONE
		,"max": section_cfg.outer_wall.max - Vector2i.ONE
	}
	section_cfg.open = { # This is the area inside the quadrant that is potentially open for wall placement
		"min": section_cfg.corridor.min + Vector2i.ONE
		,"max": section_cfg.corridor.max - Vector2i.ONE
	}
	# only draw on the corridors and open space
		# Range is not inclusive of the last number, so go to wall
	section_cfg.inner_wall = {
		"position": Vector2i.ZERO # This is the chosen inner wall intersection
		,"fill": {
			"x" = range(section_cfg.corridor.min.x, section_cfg.outer_wall.max.x)
			,"y" = range(section_cfg.corridor.min.y, section_cfg.outer_wall.max.y)
		}
		,"potential": { # This where the wall could be placed based on the maze_type
			# These are the possible ranges
			"min": Vector2i.ZERO
			,"max": Vector2i.ZERO
			# These are the possible locations between those ranges
			,"x": []
			,"y": []
		}
	}
	section_cfg.doors = {
		0: {
			"direction": ""
			,"location": ""
			,"potential": { # Same as inner_wall.potential
				"min": Vector2i.ZERO
				,"max": Vector2i.ZERO
			}
			,"position": Vector2i.ZERO
		},
		1: {
			"direction": ""
			,"location": ""
			,"potential": { # Same as inner_wall.potential
				"min": Vector2i.ZERO
				,"max": Vector2i.ZERO
			}
			,"position": Vector2i.ZERO
		},
		2: {
			"direction": ""
			,"location": ""
			,"potential": { # Same as inner_wall.potential
				"min": Vector2i.ZERO
				,"max": Vector2i.ZERO
			}
			,"position": Vector2i.ZERO
		}
	}
	section_cfg.inner_wall.middle_point = Vector2i( # This is used for Middle and is the center
		clamp(section_cfg.open.min.x + int((section_cfg.open.max.x - section_cfg.open.min.x) * .5), section_cfg.open.min.x, section_cfg.open.max.x)
		,clamp(section_cfg.open.min.y + int((section_cfg.open.max.y - section_cfg.open.min.y) * .5), section_cfg.open.min.y, section_cfg.open.max.y)
	)
	for d in section_cfg.doors:
		section_cfg["doors"][d]["middle_point"] = Vector2i.ZERO
	section_cfg.inner_wall.middle_ish_adjustment = Vector2i(
		clamp(int((section_cfg.outer_wall.max.x - section_cfg.outer_wall.min.x) * middle_ish_range), section_cfg.open.min.x, section_cfg.open.max.x)
		,clamp(int((section_cfg.outer_wall.max.y - section_cfg.outer_wall.min.y) * middle_ish_range), section_cfg.open.min.y, section_cfg.open.max.y)
	)
	for d in section_cfg.doors:
		section_cfg["doors"][d]["middle_ish_adjustment"] = Vector2i.ZERO
	if iteration == 0:
		section_cfg.outer_doors = {
			"direction": "",
			"start": {
				"position": Vector2i.ZERO
				,"potential": { # Same as inner_wall.potential
					"min": Vector2i.ZERO
					,"max": Vector2i.ZERO
				}
				,"middle_point": Vector2i.ZERO
				,"middle_ish_adjustment": Vector2i.ZERO
			},
			"end": {
				"position": Vector2i.ZERO
				,"potential": {
					"min": Vector2i.ZERO
					,"max": Vector2i.ZERO
				}
				,"middle_point": Vector2i.ZERO
				,"middle_ish_adjustment": Vector2i.ZERO
			}
		}
	# Test if there can be at least 1 row and 1 column
	if section_cfg.open.max.x > section_cfg.open.min.x and section_cfg.open.max.y > section_cfg.open.min.y:
		var wall_check: bool = make_inner_walls(section_cfg)
		# If no inner walls made, skip
		if wall_check:
			var skipped_direction = make_doors(section_cfg)
			if iteration == 0:
				# Determine where the start and end are
				section_cfg.outer_doors.direction = skipped_direction
				make_start_end(section_cfg)
			# Check to see if each chamber needs to be broken into more chambers
				# Quadrants 1-4 respectively
			var mip = Vector2i.ZERO
			var map = Vector2i.ZERO
			for q in range(1,5):
				match q:
					1:
						mip = section_cfg.outer_wall.min
						map = section_cfg.inner_wall.position
					2:
						mip = Vector2i(section_cfg.inner_wall.position.x, section_cfg.outer_wall.min.y)
						map = Vector2i(section_cfg.outer_wall.max.x, section_cfg.inner_wall.position.y)
					3:
						mip = Vector2i(section_cfg.outer_wall.min.x, section_cfg.inner_wall.position.y)
						map = Vector2i(section_cfg.inner_wall.position.x, section_cfg.outer_wall.max.y)
					4:
						mip = section_cfg.inner_wall.position
						map = section_cfg.outer_wall.max
				generate_maze_section(mip, map, (iteration + 1), q, door_placement[subsequent_run][skipped_direction][(q - 1)])
	# This dumps the config of the section for troubleshooting
	var cfg_json = JSON.stringify(section_cfg, "\t", false)
	var file = FileAccess.open(session_log_dir + filename, FileAccess.WRITE)
	file.store_string(cfg_json)
	file.close()

func make_inner_walls(section_cfg):
	match maze_type:
		'Random':
			section_cfg.inner_wall.potential.min = section_cfg.open.min
			section_cfg.inner_wall.potential.max = section_cfg.open.max
		'Middle':
			section_cfg.inner_wall.potential.min = section_cfg.inner_wall.middle_point
			section_cfg.inner_wall.potential.max = section_cfg.inner_wall.potential.min
		'Middle-ish':
			section_cfg.inner_wall.potential.min = Vector2i(
				clamp(section_cfg.inner_wall.middle_point.x - section_cfg.inner_wall.middle_ish_adjustment.x, section_cfg.open.min.x, section_cfg.open.max.x)
				,clamp(section_cfg.inner_wall.middle_point.y - section_cfg.inner_wall.middle_ish_adjustment.y, section_cfg.open.min.y, section_cfg.open.max.y)
			)
			section_cfg.inner_wall.potential.max = Vector2i(
				clamp(section_cfg.inner_wall.middle_point.x + section_cfg.inner_wall.middle_ish_adjustment.x, section_cfg.open.min.x, section_cfg.open.max.x)
				,clamp(section_cfg.inner_wall.middle_point.y + section_cfg.inner_wall.middle_ish_adjustment.y, section_cfg.open.min.y, section_cfg.open.max.y)
			)
	# Test to see if there is room for walls
	#	Assumption is that every wall must have 1 coridoor next to it
	#	+ 1 on end because range does not include the last number
	for x in range(section_cfg.inner_wall.potential.min.x, (section_cfg.inner_wall.potential.max.x + 1)):
		if maze[x][section_cfg.outer_wall.min.y] == 1 and maze[x][section_cfg.outer_wall.max.y] == 1:
			section_cfg.inner_wall.potential.x.append(x)
	for y in range(section_cfg.inner_wall.potential.min.y, (section_cfg.inner_wall.potential.max.y + 1)):
		if maze[section_cfg.outer_wall.min.x][y] == 1 and maze[section_cfg.outer_wall.max.x][y] == 1:
			section_cfg.inner_wall.potential.y.append(y)
	if not(section_cfg.inner_wall.potential.x.is_empty()) and not(section_cfg.inner_wall.potential.y.is_empty()):
		# Pick random avail spots for the wall
		section_cfg.inner_wall.position.x = section_cfg.inner_wall.potential.x.pick_random()
		section_cfg.inner_wall.position.y = section_cfg.inner_wall.potential.y.pick_random()
		# set bits to 1 for the walls (build the inner walls)
		for x in section_cfg.inner_wall.fill.x:
			maze[x][section_cfg.inner_wall.position.y] = 1
		for y in section_cfg.inner_wall.fill.y:
			maze[section_cfg.inner_wall.position.x][y] = 1
		# inner walls made, continue
		return true
	else:
		# no wall possible, stop
		return false


func make_doors(section_cfg):
	var compass = ['N', 'E', 'S', 'W']
	var skipped_wall: String
	var direction: String
	# For Middle-ish and Middle, force what wall has no door
	if section_cfg.wall_force != "" and maze_type != "Random":
		skipped_wall = section_cfg.wall_force
	# For iteration 0 and Random, pick a random wall to have no door
	else:
		skipped_wall = compass.pick_random()
	compass.erase(skipped_wall)
	# Now set the bounds for the wall
	for c in len(compass):
		section_cfg["doors"][c]["direction"] = compass[c]
		# Calculation varies based on compass direction
		var door_pos: int = 0
		match section_cfg["doors"][c]["direction"]:
			'N':
				#Middle Point
				if ( skipped_wall == 'S' and section_cfg.iteration % 2 == 0 ) or ( ( skipped_wall == 'E' or skipped_wall == 'W' ) and section_cfg.iteration % 2 == 1 ):
					section_cfg["doors"][c]["distance"] = 'far' # far from inner wall
					door_pos = section_cfg.corridor.min.y
				else:
					section_cfg["doors"][c]["distance"] = 'near' # near to inner wall
					door_pos = section_cfg.inner_wall.position.y - 1
				section_cfg["doors"][c]["middle_point"] = Vector2i(
					section_cfg.inner_wall.position.x
					,door_pos
				)
				#Middle-ish Adjustment
				section_cfg["doors"][c]["middle_ish_adjustment"] = Vector2i(
					0
					,int((section_cfg.inner_wall.position.y - section_cfg.outer_wall.min.y) * middle_ish_range)
				)
			'E':
				#Middle Point
				if ( skipped_wall == 'W' and section_cfg.iteration % 2 == 0 ) or ( ( skipped_wall == 'N' or skipped_wall == 'S' ) and section_cfg.iteration % 2 == 1 ):
					section_cfg["doors"][c]["distance"] = 'far' # far from inner wall
					door_pos = section_cfg.corridor.max.x
				else:
					section_cfg["doors"][c]["distance"] = 'near' # near to inner wall
					door_pos = section_cfg.inner_wall.position.x + 1
				section_cfg["doors"][c]["middle_point"] = Vector2i(
					door_pos
					,section_cfg.inner_wall.position.y
				)
				#Middle-ish Adjustment
				section_cfg["doors"][c]["middle_ish_adjustment"] = Vector2i(
					int((section_cfg.outer_wall.max.x - section_cfg.inner_wall.position.x) * middle_ish_range)
					,0
				)
			'S':
				#Middle Point
				if ( skipped_wall == 'N' and section_cfg.iteration % 2 == 0 ) or ( ( skipped_wall == 'E' or skipped_wall == 'W' ) and section_cfg.iteration % 2 == 1 ):
					section_cfg["doors"][c]["distance"] = 'far' # far from inner wall
					door_pos = section_cfg.corridor.max.y
				else:
					section_cfg["doors"][c]["distance"] = 'near' # near to inner wall
					door_pos = section_cfg.inner_wall.position.y + 1
				section_cfg["doors"][c]["middle_point"] = Vector2i(
					section_cfg.inner_wall.position.x
					,door_pos
				)
				#Middle-ish Adjustment
				section_cfg["doors"][c]["middle_ish_adjustment"] = Vector2i(
					0
					,int((section_cfg.outer_wall.max.y - section_cfg.inner_wall.position.y) * middle_ish_range)
				)
			'W':
				#Middle Point
				if ( skipped_wall == 'E' and section_cfg.iteration % 2 == 0 ) or ( ( skipped_wall == 'N' or skipped_wall == 'S' ) and section_cfg.iteration % 2 == 1 ):
					section_cfg["doors"][c]["distance"] = 'far' # far from inner wall
					door_pos = section_cfg.corridor.min.x
				else:
					section_cfg["doors"][c]["distance"] = 'near' # near to inner wall
					door_pos = section_cfg.inner_wall.position.x - 1
				section_cfg["doors"][c]["middle_point"] = Vector2i(
					door_pos
					,section_cfg.inner_wall.position.y
				)
				#Middle-ish Adjustment
				section_cfg["doors"][c]["middle_ish_adjustment"] = Vector2i(
					int((section_cfg.inner_wall.position.x - section_cfg.outer_wall.min.x) * middle_ish_range)
					,0
				)
		match maze_type:
			'Random':
				match section_cfg["doors"][c]["direction"]:
					'N':
						section_cfg["doors"][c]["potential"]["min"] = Vector2i(section_cfg.inner_wall.position.x
																				, section_cfg.corridor.min.y)
						section_cfg["doors"][c]["potential"]["max"] = Vector2i(section_cfg.inner_wall.position.x
																				, section_cfg.inner_wall.position.y - 1)
					'E':
						section_cfg["doors"][c]["potential"]["min"] = Vector2i(section_cfg.inner_wall.position.x + 1
																				, section_cfg.inner_wall.position.y)
						section_cfg["doors"][c]["potential"]["max"] = Vector2i(section_cfg.corridor.max.x
																				, section_cfg.inner_wall.position.y)
					'S':
						section_cfg["doors"][c]["potential"]["min"] = Vector2i(section_cfg.inner_wall.position.x
																				, section_cfg.inner_wall.position.y + 1)
						section_cfg["doors"][c]["potential"]["max"] = Vector2i(section_cfg.inner_wall.position.x
																				, section_cfg.corridor.max.y)
					'W':
						section_cfg["doors"][c]["potential"]["min"] = Vector2i(section_cfg.corridor.min.x
																				, section_cfg.inner_wall.position.y)
						section_cfg["doors"][c]["potential"]["max"] = Vector2i(section_cfg.inner_wall.position.x - 1
																				, section_cfg.inner_wall.position.y)
			'Middle':
				section_cfg["doors"][c]["potential"]["min"] = section_cfg["doors"][c]["middle_point"]
				section_cfg["doors"][c]["potential"]["max"] = section_cfg["doors"][c]["middle_point"]
			'Middle-ish':
				if section_cfg["doors"][c]["distance"] == 'far':
					if section_cfg["doors"][c]["direction"] == 'N' or section_cfg["doors"][c]["direction"] == 'W':
						section_cfg["doors"][c]["potential"]["min"] = section_cfg["doors"][c]["middle_point"]
						section_cfg["doors"][c]["potential"]["max"] = section_cfg["doors"][c]["middle_point"] + section_cfg["doors"][c]["middle_ish_adjustment"]
					else:
						section_cfg["doors"][c]["potential"]["min"] = section_cfg["doors"][c]["middle_point"] - section_cfg["doors"][c]["middle_ish_adjustment"]
						section_cfg["doors"][c]["potential"]["max"] = section_cfg["doors"][c]["middle_point"]
				else:
					if section_cfg["doors"][c]["direction"] == 'N' or section_cfg["doors"][c]["direction"] == 'W':
						section_cfg["doors"][c]["potential"]["min"] = section_cfg["doors"][c]["middle_point"] - section_cfg["doors"][c]["middle_ish_adjustment"]
						section_cfg["doors"][c]["potential"]["max"] = section_cfg["doors"][c]["middle_point"]
					else:
						section_cfg["doors"][c]["potential"]["min"] = section_cfg["doors"][c]["middle_point"]
						section_cfg["doors"][c]["potential"]["max"] = section_cfg["doors"][c]["middle_point"] + section_cfg["doors"][c]["middle_ish_adjustment"]
		section_cfg["doors"][c]["position"] = Vector2i(
			rng.randi_range(section_cfg["doors"][c]["potential"]["min"]["x"], section_cfg["doors"][c]["potential"]["max"]["x"])
			,rng.randi_range(section_cfg["doors"][c]["potential"]["min"]["y"], section_cfg["doors"][c]["potential"]["max"]["y"])
		)
		maze[section_cfg["doors"][c]["position"]["x"]][section_cfg["doors"][c]["position"]["y"]] = tile_types.floor
	return skipped_wall.json_escape()


func make_start_end(section_cfg):
	start_end_types.shuffle()
	for t in len(start_end_types):
		var mid_x: int
		var mid_y: int
		var adj_x: int
		var adj_y: int
		var rnd_min_x: int
		var rnd_min_y: int
		var rnd_max_x: int
		var rnd_max_y: int
		if section_cfg.outer_doors.direction == 'N' or section_cfg.outer_doors.direction == 'S':
			if t == 0:
				mid_x = section_cfg.inner_wall.position.x - 1
				rnd_min_x = section_cfg.corridor.min.x
				rnd_max_x = ( section_cfg.inner_wall.position.x - 1 )
			else:
				mid_x = section_cfg.inner_wall.position.x + 1
				rnd_min_x = ( section_cfg.inner_wall.position.x + 1 )
				rnd_max_x = section_cfg.corridor.max.x
			adj_x = int((section_cfg.outer_wall.max.x - section_cfg.outer_wall.min.x) * middle_ish_range)
			adj_y = 0
			if t == 0:
				if adj_x - mid_x < section_cfg.corridor.min.x:
					adj_x = mid_x - section_cfg.corridor.min.x
			else:
				if adj_x + mid_x > section_cfg.corridor.max.x:
					adj_x = mid_x + section_cfg.corridor.max.x
			match section_cfg.outer_doors.direction:
				'N':
					mid_y = section_cfg.outer_wall.min.y
					rnd_min_y = section_cfg.outer_wall.min.y
					rnd_max_y = section_cfg.outer_wall.min.y
					if t == 0:
						world_boundary_normal = Vector2.DOWN
						world_boundary_pos = Vector2(0.0, 0.0)
				'S':
					mid_y = section_cfg.outer_wall.max.y
					rnd_min_y = section_cfg.outer_wall.max.y
					rnd_max_y = section_cfg.outer_wall.max.y
					if t == 0:
						world_boundary_normal = Vector2.UP
						world_boundary_pos = Vector2(1.0, 1.0)
		elif section_cfg.outer_doors.direction == 'E' or section_cfg.outer_doors.direction == 'W':
			if t == 0:
				mid_y = section_cfg.inner_wall.position.y - 1
				rnd_min_y = section_cfg.corridor.min.y
				rnd_max_y = ( section_cfg.inner_wall.position.y - 1 )
			else:
				mid_y = section_cfg.inner_wall.position.y + 1
				rnd_min_y = ( section_cfg.inner_wall.position.y + 1 )
				rnd_max_y = section_cfg.corridor.max.y
			adj_x = 0
			adj_y = int((section_cfg.outer_wall.max.y - section_cfg.outer_wall.min.y) * middle_ish_range)
			if t == 0:
				if adj_y - mid_y < section_cfg.corridor.min.y:
					adj_y = mid_y - section_cfg.corridor.min.y
			else:
				if adj_y + mid_y > section_cfg.corridor.max.y:
					adj_y = mid_y + section_cfg.corridor.max.y
			match section_cfg.outer_doors.direction:
				'E':
					if maze_type != 'Random':
						mid_x = section_cfg.outer_wall.max.x
					rnd_min_x = section_cfg.outer_wall.max.x
					rnd_max_x = section_cfg.outer_wall.max.x
					if t == 0:
						world_boundary_normal = Vector2.LEFT
						world_boundary_pos = Vector2(1.0, 0.0)
				'W':
					if maze_type != 'Random':
						mid_x = section_cfg.outer_wall.min.x
					rnd_min_x = section_cfg.outer_wall.min.x
					rnd_max_x = section_cfg.outer_wall.min.x
					if t == 0:
						world_boundary_normal = Vector2.RIGHT
						world_boundary_pos = Vector2(0.0, 1.0)
		#Middle Point
		section_cfg["outer_doors"][start_end_types[t]]["middle_point"] = Vector2i(mid_x, mid_y)
		#Middle-ish Adjustment
		section_cfg["outer_doors"][start_end_types[t]]["middle_ish_adjustment"] = Vector2i(adj_x, adj_y)
		match maze_type:
			'Random':
				section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"] = Vector2i(rnd_min_x, rnd_min_y)
				section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"] = Vector2i(rnd_max_x, rnd_max_y)
			'Middle':
				section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"] = section_cfg["outer_doors"][start_end_types[t]]["middle_point"]
				section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"] = section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"]
			'Middle-ish':
				if t == 0:
					section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"] = section_cfg["outer_doors"][start_end_types[t]]["middle_point"] - section_cfg["outer_doors"][start_end_types[t]]["middle_ish_adjustment"]
					section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"] = section_cfg["outer_doors"][start_end_types[t]]["middle_point"]
				else:
					section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"] = section_cfg["outer_doors"][start_end_types[t]]["middle_point"]
					section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"] = section_cfg["outer_doors"][start_end_types[t]]["middle_point"] + section_cfg["outer_doors"][start_end_types[t]]["middle_ish_adjustment"]
		section_cfg["outer_doors"][start_end_types[t]]["position"] = Vector2i(
			rng.randi_range(section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"]["x"], section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"]["x"])
			,rng.randi_range(section_cfg["outer_doors"][start_end_types[t]]["potential"]["min"]["y"], section_cfg["outer_doors"][start_end_types[t]]["potential"]["max"]["y"])
		)
		maze[section_cfg["outer_doors"][start_end_types[t]]["position"]["x"]][section_cfg["outer_doors"][start_end_types[t]]["position"]["y"]] = tile_types[start_end_types[t]]


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


func clean_up_logs():
	if not(keep_logs):
		OS.move_to_trash(ProjectSettings.globalize_path(session_log_dir))
	

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		clean_up_logs()
