class_name Counter
extends Control

@export var value: int = 0
@export var active: bool = false

var seq: int = 0

var _was_ever_active := false

func _process(_delta: float) -> void:
	$SprintLabel.text = "Sprint " + str(seq)
	$Label.text = str(value)
	if not active:
		scale = Vector2.ONE
	else:
		scale = Vector2.ONE * 1.25
		_was_ever_active = true

	if active:
		$TextureRect.modulate = Color(0x9f4a1cff)
	elif _was_ever_active:
		$TextureRect.modulate = Color(0x5f77bfff)
	else:
		$TextureRect.modulate = Color(0xe9b12eff)
