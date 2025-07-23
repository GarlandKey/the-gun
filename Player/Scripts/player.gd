extends CharacterBody3D

@export var mouse_sensitivity := 0.001
@export var camera_distance := 5.0
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var aim_raycast: RayCast3D = $CameraPivot/SpringArm3D/Camera3D/AimRayCast

# Bullet scene to spawn
const BULLET_SCENE = preload("res://Bullets/Scenes/bullet.tscn")
const CROSSHAIR_SCENE = preload("res://UI/crosshair.tscn")
const PAUSE_MENU_SCENE = preload("res://Menus/Scenes/pause_menu.tscn")

var pause_menu: Control

const SPEED = 10.0
const RUN_SPEED = 20.0
const JUMP_VELOCITY = 4.5
const DASH_DISTANCE = 5.0
const DASH_DURATION = 0.2

var dash_velocity = Vector3.ZERO
var dash_timer = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	
	# Add crosshair to the UI
	var crosshair = CROSSHAIR_SCENE.instantiate()
	get_tree().current_scene.add_child(crosshair)
	
	# Add pause menu to the UI with CanvasLayer for proper input handling
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to ensure it's on top
	get_tree().current_scene.add_child(canvas_layer)
	
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	canvas_layer.add_child(pause_menu)

func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_just_pressed("dash"):
		dash()
	
	if event is InputEventMouseMotion:
		# Horizontal rotation (Y-axis)
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation (X-axis)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Limit vertical look - allow looking up 90 degrees, down only 30 degrees
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	# Handle dash timer
	if dash_timer > 0:
		dash_timer -= delta
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
	else:
		dash_velocity = Vector3.ZERO
		
		# Normal movement when not dashing
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var direction: Vector3 = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# Check if running
		var current_speed = RUN_SPEED if Input.is_action_pressed("run") else SPEED
		
		if direction != Vector3.ZERO:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()

func shoot():
	# Create bullet instance
	var bullet = BULLET_SCENE.instantiate()
	
	# Add bullet to the scene tree
	get_tree().current_scene.add_child(bullet)
	
	# Set the shooter reference to prevent self-hits (after adding to scene)
	bullet.shooter = self
	
	# Spawn bullet from center of player capsule (height is 3, so center is 1.5 up)
	bullet.global_position = global_position + Vector3.UP * 1.5
	
	# Calculate direction from bullet position to where camera is aiming
	var camera_forward = -camera.global_transform.basis.z
	var target_point = camera.global_position + camera_forward * 100.0
	var shoot_direction = (target_point - bullet.global_position).normalized()
	
	# Fire the bullet
	bullet.fire(shoot_direction)

func dash():
	# Only dash if not already dashing and on ground
	if dash_timer > 0 or not is_on_floor():
		return
		
	# Get current movement direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# If no input, dash forward relative to player
	if direction == Vector3.ZERO:
		direction = -global_transform.basis.z
	
	# Set dash velocity and timer
	dash_velocity = direction * (DASH_DISTANCE / DASH_DURATION)
	dash_timer = DASH_DURATION
