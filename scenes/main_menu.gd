extends Control

@onready var start_game_button: TextureButton = %StartGame
@onready var start_challenge_button: TextureButton = %StartChallengeGame

func _ready() -> void:
	start_game_button.pressed.connect(on_start_game_pressed)
	start_challenge_button.pressed.connect(on_start_challenge_game_pressed)


func on_start_game_pressed() -> void:
	GlobalManager._normal_mode()
	GlobalManager.reset_run()
	GlobalManager.enter_current_battle()
	
func on_start_challenge_game_pressed() -> void:
	GlobalManager._challenge_mode()
	GlobalManager.reset_run()
	GlobalManager.enter_current_battle()
