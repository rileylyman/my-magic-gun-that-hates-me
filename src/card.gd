class_name Card
extends Control

@export var max_value: int = 5
@onready var curr := max_value

var show_damage := false
var game_mgr: GameManager

var stamp: Stamp
var has_stamp: bool

func _ready() -> void:
	do_setup()

func do_setup() -> void:
	game_mgr = get_tree().current_scene.find_child("GameManager")

func _process(_delta: float) -> void:
	%TitleLabel.text = str(max_value)
	%ShootLabel.text = str(max_value)
	%CountdownLabel.text = str(curr)

	%ShootLabel.visible = show_damage
	if %ShootLabel.visible:
		%CountdownLabel.text = str(0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if game_mgr != null:
			game_mgr.on_card_clicked(self)
		else:
			print("Game manager not found")


func set_stamp(new_stamp: Stamp) -> void:
	if new_stamp == null:
		return

	if stamp != null:
		stamp.queue_free()

	stamp = new_stamp
	has_stamp = true


func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false
