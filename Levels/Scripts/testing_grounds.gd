extends Node3D

@onready var pause_menu: Control = $PauseMenu

func _ready() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	print("TestingGrounds _ready: paused = ", get_tree().paused)

func _input(_event):
	if Input.is_action_just_pressed("pause"):
		pause_game()

func pause_game():
	pause_menu.visible = true
	get_tree().paused = true
