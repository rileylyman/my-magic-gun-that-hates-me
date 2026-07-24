class_name Counter
extends Control

@export var value: int = 0
@export var active: bool = false

func _process(_delta: float) -> void:
	$Label.text = str(value)
	if not active:
		scale = Vector2.ONE
	else:
		scale = Vector2.ONE * 1.25
