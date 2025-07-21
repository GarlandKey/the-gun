extends CharacterBody3D

const SPEED = 3.0
const ROTATION_SPEED = 2.0
const BURST_INTERVAL = 10.0
const SHOTS_PER_BURST = 3
const SHOT_DELAY = 0.2
const BULLET_SCENE = preload("res://Bullets/Scenes/bullet.tscn")

@onready var barrel1 = $MeshInstance3D/barrel
@onready var barrel2 = $MeshInstance3D/barrel2  
@onready var barrel3 = $MeshInstance3D/barrel3
@onready var area_3d = $Area3D
@onready var animation_player = $AnimationPlayer

var is_animating = false

var player: Node3D
var burst_timer = 0.0
var shots_fired = 0
var is_firing_burst = false
var shot_timer = 0.0

# Health system
@export var max_health = 100.0
var current_health: float

func _ready():
	# Initialize health
	current_health = max_health
	
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	print("Boomba found player: ", player)
	
	# Connect Area3D signals for damage detection
	area_3d.body_entered.connect(_on_bullet_hit)
	
	# Connect animation signals
	animation_player.animation_started.connect(_on_animation_started)
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	# Only apply gravity when not animating
	if not is_animating and not is_on_floor():
		velocity += get_gravity() * delta
	elif is_animating:
		# Clear velocity during animation to let animation control position
		velocity = Vector3.ZERO
	
	if player:
		# Rotate to face player
		var direction_to_player = (player.global_position - global_position).normalized()
		var target_rotation = atan2(direction_to_player.x, direction_to_player.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
		
		# Burst shooting logic
		if is_firing_burst:
			shot_timer -= delta
			if shot_timer <= 0 and shots_fired < SHOTS_PER_BURST:
				print("Boomba firing shot ", shots_fired + 1)
				shoot_at_player()
				shots_fired += 1
				shot_timer = SHOT_DELAY
				
				if shots_fired >= SHOTS_PER_BURST:
					print("Burst complete, waiting ", BURST_INTERVAL, " seconds")
					is_firing_burst = false
					shots_fired = 0
					burst_timer = BURST_INTERVAL
		else:
			burst_timer -= delta
			if burst_timer <= 0:
				print("Starting burst fire!")
				is_firing_burst = true
				shot_timer = 0.0
	
	move_and_slide()

func shoot_at_player():
	if not player:
		print("No player found for shooting")
		return
	
	# Fire from all three barrels
	var barrels = [barrel1, barrel2, barrel3]
	
	for barrel in barrels:
		# Create bullet
		var bullet = BULLET_SCENE.instantiate()
		
		# Set shooter reference so bullet ignores this boomba
		bullet.shooter = self
		
		# Enemy bullets should only collide with environment and player, not other enemies
		bullet.collision_mask = 5  # Layer 1 (environment) + Layer 4 (player)
		
		get_tree().current_scene.add_child(bullet)
		
		# Position bullet at barrel center
		bullet.global_position = barrel.global_position + Vector3.UP * 1.0
		
		# Calculate direction to player from this barrel
		var direction_to_player = (player.global_position - barrel.global_position).normalized()
		
		# Fire bullet
		bullet.fire(direction_to_player)

func _on_bullet_hit(body):
	# Check if it's a bullet
	if body.has_method("fire"):  # Bullets have fire method
		# Don't take damage from our own bullets
		if body.shooter == self:
			print("Boomba ignoring own bullet")
			return
			
		print("Boomba hit by bullet for ", body.damage, " damage")
		take_damage(body.damage)
		# Destroy the bullet
		body.queue_free()

func take_damage(amount: float):
	current_health -= amount
	print("Boomba health: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func die():
	print("Boomba destroyed!")
	queue_free()

func _on_animation_started(anim_name):
	print("Animation started: ", anim_name)
	is_animating = true

func _on_animation_finished(anim_name):
	print("Animation finished: ", anim_name)  
	is_animating = false
