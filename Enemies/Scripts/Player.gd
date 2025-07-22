extends CharacterBody3D

# Movement
@export var speed := 5.0
@export var sprint_speed := 12.0
@export var jump_velocity := 4.5
@export var air_control := 0.4
var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

# Camera
@onready var spring_arm := $SpringArm3D
@onready var weapon_pivot := $WeaponPivot

# Weapon
@export var base_damage := 10
@export var fire_rate := 0.2
var can_shoot := true
var damage_upgrades := 0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Ground movement
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
		velocity.x = direction.x * (sprint_speed if Input.is_action_pressed("sprint") else speed)
		velocity.z = direction.z * (sprint_speed if Input.is_action_pressed("sprint") else speed)
	else:
		# Air control
		velocity.x = lerp(velocity.x, direction.x * speed, air_control)
		velocity.z = lerp(velocity.z, direction.z * speed, air_control)
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	# Shooting
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

func _input(event):
	# Camera look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)
	
	# Mouse capture toggle
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

func shoot():
	can_shoot = false
	$ShootTimer.start(fire_rate)
	
	# Raycast shooting
	var ray = $WeaponPivot/Weapon/RayCast3D
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var target = ray.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(base_damage * (1 + 0.5 * damage_upgrades))
	
	# Visual feedback
	$WeaponPivot/Weapon.position.z = 0.2
	var tween = create_tween()
	tween.tween_property($WeaponPivot/Weapon, "position:z", 0.0, 0.1)

func upgrade_weapon():
	damage_upgrades += 1
	fire_rate = max(0.05, fire_rate - 0.02)  # Faster shooting

func _on_shoot_timer_timeout():
	can_shoot = true
