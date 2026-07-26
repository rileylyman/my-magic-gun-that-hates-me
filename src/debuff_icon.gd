class_name DebuffIcon
extends Control

var debuff: EnemyDebuff = EnemyDebuff.new()
var gm: GameManager


func _ready() -> void:
	%Title.text = debuff.title
	%Desc.text = debuff.description
	$Tooltip.visible = false
	$TextureRect.texture = debuff.icon
	%ShakeTextContainer.top_level = true

func _process(_delta: float) -> void:
	%Title.text = debuff.title
	%Desc.text = debuff.description

func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false

func shake(show_text: String = "") -> void:

	var curr_rot := rotation
	var curr_scale := scale

	var new_rotation := curr_rot + PI / 16
	var new_scale := scale * 1.25

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"rotation",
		new_rotation,
		0.15
	)

	tween.tween_property(
		self,
		"scale",
		new_scale,
		0.15
	)

	await tween.finished
	if show_text != "":
		gm.play_artifact_trigger_sound()
		%ShakeText.text = show_text
		%ShakeTextContainer.visible = true
		%ShakeTextContainer.global_position = global_position + Vector2(0, 48)

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"rotation",
		curr_rot,
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		curr_scale,
		0.1
	)

	await tween.finished

	rotation = curr_rot
	scale = curr_scale

	var f = func():
		await get_tree().create_timer(0.5).timeout
		%ShakeTextContainer.visible = false
	f.call()
