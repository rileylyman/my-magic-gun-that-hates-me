class_name SprintScore
extends Label

func shake() -> void:
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
