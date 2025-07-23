extends Node
@onready var pause_menu: Control = $"../PauseMenu"

func _input(_event):
	
	if Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			pause_menu.visible = false
			get_tree().paused = false
