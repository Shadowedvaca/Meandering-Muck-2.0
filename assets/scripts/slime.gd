extends CharacterBody2D

signal exited

# Due to the player movement using bot move_and_collide (for collision) and position += (for clamping)
	# This is halved
@export var speed:int = 500 # How fast the player will move (pixels/sec).
@onready var screen_size = get_viewport_rect().size

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	var distance = velocity * delta
	position += distance
	var collision_info = move_and_collide(Vector2.ZERO) #distance)
	position = clamp(position, Vector2.ZERO, Vector2(screen_size))
	if collision_info:
		if collision_info.get_collider_id() == get_parent().end_tile_id:
			exit_reached()
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		# See the note below about boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "fly"
		$AnimatedSprite2D.flip_v = velocity.y > 0

func start(pos):
	position = pos
	#$CollisionShape2D.set_deferred("disabled", false)
	show()


func exit_reached():
	hide()
	exited.emit()
	#$CollisionShape2D.set_deferred("disabled", true)

