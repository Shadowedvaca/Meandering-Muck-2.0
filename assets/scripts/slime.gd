extends CharacterBody2D
class_name Slime

signal exited

@export var speed:int = 75 # How fast the player will move (pixels/sec).

@onready var camera: Camera2D = %FollowCam

# Called when the node enters the scene tree for the first time.
@warning_ignore("untyped_declaration")
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("untyped_declaration")
func _process(delta):
	var slime_velocity: Vector2 = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		slime_velocity.x += 1
	if Input.is_action_pressed("move_left"):
		slime_velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		slime_velocity.y += 1
	if Input.is_action_pressed("move_up"):
		slime_velocity.y -= 1
	if slime_velocity.length() > 0:
		slime_velocity = slime_velocity.normalized() * speed
		@warning_ignore("unsafe_method_access")
		$AnimatedSprite2D.play()
	else:
		@warning_ignore("unsafe_method_access")
		$AnimatedSprite2D.stop()
	var distance: Vector2 = slime_velocity * delta
	var collision_info = move_and_collide(distance)
	#if collision_info:
		# This may need tweaking with the recent changes
		#if collision_info.get_collider_id() == get_parent().end_tile_id:
		#	exit_reached()
	if slime_velocity.x != 0:
		@warning_ignore("unsafe_property_access")
		$AnimatedSprite2D.animation = "walk"
		@warning_ignore("unsafe_property_access")
		$AnimatedSprite2D.flip_v = false
		# See the note below about boolean assignment.
		@warning_ignore("unsafe_property_access")
		$AnimatedSprite2D.flip_h = slime_velocity.x < 0
	elif slime_velocity.y != 0:
		@warning_ignore("unsafe_property_access")
		$AnimatedSprite2D.animation = "fly"
		@warning_ignore("unsafe_property_access")
		$AnimatedSprite2D.flip_v = slime_velocity.y > 0

func start(pos: Vector2) -> void:
	position = pos
	show()
	@warning_ignore("unsafe_method_access")
	camera.set_up_camera()


func exit_reached() -> void:
	hide()
	exited.emit()

