extends Control

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		visible = !visible

func _on_kill_current_enemy_pressed() -> void:
	var game_mgr = get_tree().current_scene.find_child("GameManager")
	if game_mgr != null:
		game_mgr.score_bar.curr_score = game_mgr.score_bar.max_score
