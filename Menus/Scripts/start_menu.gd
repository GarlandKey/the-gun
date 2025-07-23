extends Control

func _ready():
	# Set mouse mode to visible for menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	# Check for any key press or mouse click
	if event is InputEventKey and event.pressed:
		transition_to_game()
	elif event is InputEventMouseButton and event.pressed:
		transition_to_game()

func transition_to_game():
	# Change to the TestingGrounds scene
	get_tree().change_scene_to_file("res://Enemies/Scenes/TestingGrounds.tscn")
