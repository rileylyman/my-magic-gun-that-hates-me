class_name Card
extends Control

@export var max_value: int = 5
@onready var curr := max_value

var game_mgr: GameManager

func _ready() -> void:
	do_setup()

func do_setup() -> void:
	game_mgr = get_tree().current_scene.find_child("GameManager")

func _process(_delta: float) -> void:
	%TitleLabel.text = str(max_value)
	%ShootLabel.text = str(max_value)
	%CountdownLabel.text = str(curr)

	%ShootLabel.visible = curr == max_value and game_mgr != null and self in game_mgr.chosen and game_mgr.active_counter != null
	if %ShootLabel.visible:
		%CountdownLabel.text = str(0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if game_mgr != null:
			game_mgr.on_card_clicked(self)
		else:
			print("Game manager not found")


func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false
