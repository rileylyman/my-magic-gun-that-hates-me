extends Node2D

@onready var start_game_button: Button = %StartGame


func _ready() -> void:
	start_game_button.pressed.connect(on_start_game_pressed)


func on_start_game_pressed() -> void:
	GlobalManager.reset_run()
	GlobalManager.enter_current_battle()
