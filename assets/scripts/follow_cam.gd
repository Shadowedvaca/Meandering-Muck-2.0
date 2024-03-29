extends Camera2D

@export var camera_speed: float
# This sets the zoom each level is reset to (as long the maze is at least as big as the screen)
@export var default_zoom: float
@onready var default_zoom_vector: Vector2 = Vector2(default_zoom, default_zoom)
# This sets the min and max zoom allowed to the user
@export var min_zoom: float
@onready var min_zoom_vector: Vector2 = Vector2(min_zoom, min_zoom)
@export var max_zoom: float
@onready var max_zoom_vector: Vector2 = Vector2(max_zoom, max_zoom)
# For each level, there may be a higher value for the minimum zoom (so they can't zoom to see borders)
var min_zoom_override: float
var min_zoom_override_vector: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
@warning_ignore("untyped_declaration")
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("untyped_declaration", "unused_parameter")
func _process(delta):
	var velocity: Vector2 = Vector2.ZERO
	var new_zoom: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("zoom_in"):
		velocity.x += camera_speed
		velocity.y += camera_speed
	if Input.is_action_pressed("zoom_out"):
		velocity.x -= camera_speed
		velocity.y -= camera_speed
	new_zoom = zoom + velocity
	zoom = clamp(new_zoom, min_zoom_override_vector, max_zoom_vector)

func set_up_camera(world_size: Vector2) -> void:
	# Anchor the limits to the edges of the maze
	var screen_size: Vector2 = get_viewport_rect().size
	@warning_ignore("narrowing_conversion")
	limit_right = world_size.x
	@warning_ignore("narrowing_conversion")
	limit_bottom = world_size.y
	# Set the starting zoom based on screen and maze size
	var screen_maze_x: float = 0.0
	var screen_maze_y: float = 0.0
	var screen_maze_max_scale: float = 0.0
	screen_maze_x = ( screen_size.x * 1.0 ) / ( world_size.x * 1.0 )
	screen_maze_y = ( screen_size.y * 1.0 ) / ( world_size.y * 1.0 )
	if screen_maze_x >= screen_maze_y:
		screen_maze_max_scale = screen_maze_x
	else:
		screen_maze_max_scale = screen_maze_y
	if screen_maze_max_scale > default_zoom:
		default_zoom_vector = Vector2(screen_maze_max_scale, screen_maze_max_scale)
	else:
		default_zoom_vector = Vector2(default_zoom, default_zoom)
	if screen_maze_max_scale > min_zoom:
		min_zoom_override_vector = Vector2(screen_maze_max_scale, screen_maze_max_scale)
	else:
		min_zoom_override_vector = min_zoom_vector
