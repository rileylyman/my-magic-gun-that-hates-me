class_name RewardScreen
extends Control

@onready var left_shaker: TextureRect = %LeftEnemyShaker
@onready var right_shaker: TextureRect = %RightEnemyShaker


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shake_shakers()


func _process(delta: float) -> void:
	pass

func shake_shakers() -> void:
	var dir = 1
	var left_orig_scale := left_shaker.scale
	var right_orig_scale := right_shaker.scale

	while true:
		await get_tree().create_timer(1.0).timeout
		left_shaker.rotation = dir * PI / 8
		right_shaker.rotation = - dir * PI / 8

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale * 1.25
		right_shaker.scale = right_orig_scale * 1.25

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale
		right_shaker.scale = right_orig_scale
		left_shaker.rotation = 0
		right_shaker.rotation = 0

		dir *= -1
