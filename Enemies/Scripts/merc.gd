extends CharacterBody3D

const SPEED = 6.0
const STALK_DISTANCE = 15.0  # How close to get to player
const SHOOT_RANGE = 25.0     # Maximum shooting range
const SHOTS_PER_BURST = 10
const SHOT_DELAY = 0.1       # Time between shots in burst
const BULLET_SCENE = preload("res://Bullets/Scenes/bullet.tscn")

# References
var player: Node3D
@onready var nav_agent = $NavigationAgent3D
@onready var line_of_sight = $LineOfSightRay
@onready var area_3d = $Area3D

# Shooting state
var is_shooting = false
var shots_fired = 0
var shot_timer = 0.0
var next_burst_timer = 0.0

# Tracking state for logging
var last_had_line_of_sight = false
var last_was_in_range = false

# Health
@export var max_health = 100.0
var current_health: float

func _ready():
	print("PillPopper: Starting fresh stalker AI")
	current_health = max_health
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERROR: PillPopper could not find player!")
		return
	
	print("PillPopper: Found player at ", player.global_position)
	
	# Connect damage detection
	area_3d.body_entered.connect(_on_bullet_hit)
	
	# Set initial random burst delay
	next_burst_timer = randf_range(1.0, 3.0)

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
	
	# Handle shooting
	handle_shooting(delta, distance_to_player)
	
	# Debug movement
	var old_pos = global_position
	move_and_slide()
	
	# Log actual movement every 2 seconds
	if Engine.get_process_frames() % 120 == 0:
		var movement = global_position - old_pos
		if movement.length() > 0.01:
			print("PillPopper moved: ", movement.length(), " units. New position: ", global_position)
		else:
			print("PillPopper not moving. Position: ", global_position, " Velocity: ", velocity)

func stalk_player(distance_to_player: float):
	# Always move towards player, but maintain stalk distance
	if distance_to_player > STALK_DISTANCE:
		# Too far - move closer
		nav_agent.target_position = player.global_position
		
		var next_position = nav_agent.get_next_path_position()
		var distance_to_next = global_position.distance_to(next_position)
		
		# Check if NavigationAgent is working (next position should be different from current)
		if distance_to_next < 1.0 or nav_agent.is_navigation_finished():
			# NavigationAgent not working properly, use direct movement
			if Engine.get_process_frames() % 120 == 0:
				print("Navigation not working - using direct movement to player")
			var direction_to_player = (player.global_position - global_position).normalized()
			velocity.x = direction_to_player.x * SPEED
			velocity.z = direction_to_player.z * SPEED
		else:
			# Use NavigationAgent pathfinding
			var direction = (next_position - global_position).normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			
			# Debug every 2 seconds
			if Engine.get_process_frames() % 120 == 0:
				print("Using NavigationAgent: Moving towards ", next_position)
	else:
		# Close enough - stop moving
		velocity.x = 0
		velocity.z = 0
		if Engine.get_process_frames() % 120 == 0:
			print("PillPopper close enough to player (", distance_to_player, "m) - stopped")
	
	# Always face the player
	var direction_to_player = (player.global_position - global_position).normalized()
	var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, 3.0 * get_physics_process_delta_time())

func handle_shooting(delta: float, distance_to_player: float):
	# Check if player is in shooting range
	var is_in_range = distance_to_player <= SHOOT_RANGE
	
	# Log when entering/leaving range
	if is_in_range and not last_was_in_range:
		print("PillPopper IN RANGE to fire at position: ", global_position, " (distance: ", distance_to_player, "m)")
	elif not is_in_range and last_was_in_range:
		print("PillPopper OUT OF RANGE at position: ", global_position, " (distance: ", distance_to_player, "m)")
	last_was_in_range = is_in_range
	
	if not is_in_range:
		return
	
	# Check line of sight
	line_of_sight.target_position = to_local(player.global_position)  # Aim at player center
	line_of_sight.force_raycast_update()
	
	var has_line_of_sight = false
	if line_of_sight.is_colliding():
		var collider = line_of_sight.get_collider()
		# We have line of sight if we hit the player directly
		has_line_of_sight = (collider == player)
		
		# Debug line of sight every 2 seconds when in range
		if Engine.get_process_frames() % 120 == 0:
			print("Line of sight check: Hit ", collider.name, " | Has sight: ", has_line_of_sight)
	else:
		# Debug when raycast doesn't hit anything
		if Engine.get_process_frames() % 120 == 0:
			print("Line of sight raycast hit nothing - no obstacles")
		has_line_of_sight = true  # If nothing blocked it, we can see the player
	
	# Log when gaining/losing line of sight
	if has_line_of_sight and not last_had_line_of_sight:
		print("PillPopper CAN SEE PLAYER at position: ", global_position, " -> Player at: ", player.global_position)
	elif not has_line_of_sight and last_had_line_of_sight:
		print("PillPopper LOST SIGHT of player at position: ", global_position)
		if line_of_sight.is_colliding():
			print("   Blocked by: ", line_of_sight.get_collider().name)
	last_had_line_of_sight = has_line_of_sight
	
	if not has_line_of_sight:
		return
	
	# Shooting logic
	if is_shooting:
		# Currently in burst
		shot_timer -= delta
		if shot_timer <= 0 and shots_fired < SHOTS_PER_BURST:
			fire_bullet()
			shots_fired += 1
			shot_timer = SHOT_DELAY
			
		# Check if burst is complete
		if shots_fired >= SHOTS_PER_BURST:
			var wait_time = randf_range(2.0, 5.0)
			print("PillPopper: Burst complete at position: ", global_position, " | Waiting ", wait_time, " seconds")
			is_shooting = false
			next_burst_timer = wait_time
	else:
		# Waiting for next burst
		next_burst_timer -= delta
		if next_burst_timer <= 0:
			print("PillPopper: Starting new burst from position: ", global_position)
			start_burst()
		else:
			# Debug waiting state every 2 seconds
			if Engine.get_process_frames() % 120 == 0:
				print("PillPopper: Waiting to shoot - ", next_burst_timer, " seconds remaining")

func start_burst():
	is_shooting = true
	shots_fired = 0
	shot_timer = 0.0

func fire_bullet():
	print("PillPopper FIRING shot ", shots_fired + 1, "/", SHOTS_PER_BURST, " from position: ", global_position, " at player: ", player.global_position)
	
	# Create bullet
	var bullet = BULLET_SCENE.instantiate()
	bullet.shooter = self
	bullet.collision_mask = 5  # Hit environment and player
	
	get_tree().current_scene.add_child(bullet)
	
	# Position from center of PillPopper
	bullet.global_position = global_position + Vector3.UP * 1.5
	
	# Aim at player center
	var direction = (player.global_position - bullet.global_position).normalized()
	bullet.fire(direction)

func take_damage(amount: float):
	current_health -= amount
	print("PillPopper health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		print("PillPopper destroyed!")
		queue_free()

func _on_bullet_hit(body):
	if body.has_method("fire") and body.shooter != self:
		print("PillPopper hit by bullet for ", body.damage, " damage")
		take_damage(body.damage)
		body.queue_free()
