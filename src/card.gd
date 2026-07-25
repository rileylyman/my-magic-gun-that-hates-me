class_name Card
extends Control

@export var max_value: int = 5
@onready var curr := max_value

var show_damage := false
var is_shaking := false
var game_mgr: GameManager

var stamp: Stamp
var has_stamp: bool

var show_zero_on_damage := true

signal shake_done

func _ready() -> void:
	do_setup()

func do_setup() -> void:
	game_mgr = get_tree().current_scene.find_child("GameManager")

func _process(_delta: float) -> void:
	%TitleLabel.text = str(max_value)
	%ShootLabel.text = str(max_value)
	%CountdownLabel.text = str(curr)

	%ShootLabel.visible = false # show_damage
	if show_damage:
		%CountdownLabel.text = str(0) if show_zero_on_damage else str(max_value)

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


func shake() -> void:
	is_shaking = true

	var curr_rot := rotation
	var curr_scale := scale

	var new_rotation = curr_rot + PI / 32
	var new_scale = scale * 1.05 

	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "rotation", new_rotation, 0.1)
	t.tween_property(self, "scale", new_scale, 0.1)
	await t.finished
	t = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "rotation", curr_rot, 0.1)
	t.tween_property(self, "scale", curr_scale, 0.1)
	await t.finished

	rotation = curr_rot
	scale = curr_scale

	is_shaking = false
	shake_done.emit()

func bump() -> void:
	is_shaking = true

	var curr_pos = global_position
	var curr_scale = scale

	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "global_position", curr_pos + Vector2(0, -16), 0.1)
	t.tween_property(self, "scale", Vector2(0, scale.y), 0.1)
	await t.finished

	show_zero_on_damage = false

	t = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "global_position", curr_pos, 0.1)
	t.tween_property(self, "scale", curr_scale, 0.1)
	await t.finished

	is_shaking = false
	shake_done.emit()
