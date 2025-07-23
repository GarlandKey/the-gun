extends Control

func _ready():
	print("PAUSE MENU _ready() called - pause menu is initialized")
	# Make sure the pause menu is initially hidden
	visible = false

func _input(event):
	print("Pause menu _input called with event: ", event)
	# Handle pause input - toggle pause menu with Enter
	if Input.is_action_just_pressed("pause"):
		print("PAUSE ACTION DETECTED!")
		if visible:
			# Currently showing pause menu - hide it and unpause
			visible = false
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			print("Game unpaused")
		else:
			# Currently not showing pause menu - show it and pause
			visible = true
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("Game paused")
