extends RigidBody3D

@export var speed = 50.0
@export var damage = 10.0
var shooter: Node3D

func _ready():
	# Connect timer signal for auto-destruction
	$Timer.timeout.connect(_on_timer_timeout)
	# Connect collision signal for hit detection
	body_entered.connect(_on_body_entered)
	# Make bullets less bouncy for consistent floor behavior
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.3
	physics_material_override.friction = 0.8

func fire(direction: Vector3):
	# Apply impulse in the direction
	apply_impulse(direction * speed)

func _on_body_entered(body):
	# Don't hit the shooter
	if body == shooter:
		print("Bullet ignored shooter: ", body.name)
		return
	
	# Check what we hit
	if body.has_method("take_damage"):
		# Hit an enemy - damage will be handled by the enemy
		print("Bullet hit enemy: ", body.name)
		# Don't destroy here - let enemy handle it
	else:
		# Hit environment (floor, walls, etc.)
		print("Bullet hit environment: ", body.name, " - destroying")
		queue_free()

func _on_timer_timeout():
	# Auto-destroy bullet after timeout
	queue_free()
