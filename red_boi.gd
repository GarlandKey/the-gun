extends Node3D

@export var amplitude: float = 1.0      # how far up/down RedBoi moves
@export var speed: float = 2.0          # how fast the sine wave oscillates
@export var return_speed: float = 5.0   # how fast others snap back

@onready var red_boi: MeshInstance3D = $RedBoi

var originals: = {}                     # name -> original Y
var time_passed: float = 0.0

func _ready():
	# cache each child’s original Y
	for child in get_children():
		if child is Node3D:
			originals[ child ] = child.translation.y

func _process(delta: float) -> void:
	time_passed += delta * speed

	# 1. animate RedBoi on sine
	var base_y = originals[ red_boi ]
	red_boi.translation.y = base_y + sin(time_passed) * amplitude

	# 2. lerp everyone else back to their original Y
	for child in originals.keys():
		if child == red_boi:
			continue
		var orig_y = originals[ child ]
		var cur_t = child.translation
		cur_t.y = lerp(cur_t.y, orig_y, delta * return_speed)
		child.translation = cur_t
