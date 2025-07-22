extends CharacterBody3D

const SPEED = 4.0
const SPRINT_SPEED = 20.0
const AGRO_RANGE = 20.0

# References
var player: Node3D
@onready var nav_agent = $NavigationAgent3D
@onready var line_of_sight = $LineOfSightRay
@onready var area_3d = $Area3D

# Tracking state for logging
var last_had_line_of_sight = false
var last_was_in_range = false

# Health
@export var max_health = 500.0
var current_health: float

func _ready():
	print("Tank: Starting fresh stalker AI")
	current_health = max_health
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERROR: Tank could not find player!")
		return
	
	print("Tank: Found player at ", player.global_position)
	
	# Connect damage detection
	area_3d.body_entered.connect(_on_bullet_hit)
	print("Tank Area3D connected to body_entered signal")
	
func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if not player:
		move_and_slide()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Always stalk the player
	stalk_player(distance_to_player)

	# Debug movement
	var old_pos = global_position
	move_and_slide()

	# Log actual movement every 2 seconds
	if Engine.get_process_frames() % 120 == 0:
		var movement = global_position - old_pos
		if movement.length() > 0.01:
			print("Tank moved: ", movement.length(), " units. New position: ", global_position)
		else:
			print("Tank not moving. Position: ", global_position, " Velocity: ", velocity)

func stalk_player(distance_to_player: float):
	# Sprint towards player when within agro range, otherwise move at normal speed
	if distance_to_player <= AGRO_RANGE:
		# Within agro range - sprint directly at player until collision
		if Engine.get_process_frames() % 120 == 0:
			print("Tank SPRINTING at player! Distance: ", distance_to_player, "m Speed: ", SPRINT_SPEED)
		
		# Direct movement towards player using sprint speed
		var direction_to_player = (player.global_position - global_position).normalized()
		velocity.x = direction_to_player.x * SPRINT_SPEED
		velocity.z = direction_to_player.z * SPRINT_SPEED
	else:
		# Outside agro range - move at normal speed towards player
		if Engine.get_process_frames() % 120 == 0:
			print("Tank moving at normal speed towards player. Distance: ", distance_to_player, "m Speed: ", SPEED)
		
		# Normal movement towards player
		var direction_to_player = (player.global_position - global_position).normalized()
		velocity.x = direction_to_player.x * SPEED
		velocity.z = direction_to_player.z * SPEED
	
	# Always face the player
	var direction_to_player = (player.global_position - global_position).normalized()
	var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, 3.0 * get_physics_process_delta_time())

func take_damage(amount: float):
	print("Tank taking ", amount, " damage! Health before: ", current_health, "/", max_health)
	current_health -= amount
	print("Tank health after damage: ", current_health, "/", max_health)
	
	if current_health <= 0:
		print("Tank destroyed!")
		queue_free()

func _on_bullet_hit(body):
	print("Tank Area3D detected body: ", body.name, " - Type: ", body.get_class())
	if body.has_method("fire"):
		print("Body has fire method - it's a bullet")
		print("Tank hit by bullet for ", body.damage, " damage")
		take_damage(body.damage)
		body.queue_free()
	else:
		print("Body does not have fire method - not a bullet")
