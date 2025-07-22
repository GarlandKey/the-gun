extends CharacterBody3D

@export var max_health := 50
var current_health := max_health

@export var move_radius := 3.0
@export var move_speed := 1.5
@export var gravity := 9.8

var angle := 0.0
var center_position: Vector3

@onready var mesh := $MeshInstance3D

func _ready():
	current_health = max_health
	center_position = global_transform.origin  # Save the original spawn point

func _physics_process(delta):
	# Circular horizontal movement
	angle += move_speed * delta
	var x = sin(angle) * move_radius
	var z = cos(angle) * move_radius

	var target_pos = center_position + Vector3(x, 0, z)
	var move_direction = (target_pos - global_transform.origin).normalized()

	# Horizontal movement
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()

func take_damage(amount: float) -> void:
	current_health -= amount
	print("Enemy took ", amount, " damage. Remaining HP: ", current_health)

	flash_red()

	if current_health <= 0:
		die()

func flash_red():
	if mesh:
		var material: StandardMaterial3D = mesh.get_active_material(0)
		if material:
			var original_color = material.albedo_color
			material.albedo_color = Color(1, 0, 0)
			await get_tree().create_timer(0.1).timeout
			material.albedo_color = original_color

func die():
	queue_free()
