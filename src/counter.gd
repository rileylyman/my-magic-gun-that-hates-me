class_name Counter
extends Control

@export var value: int = 0
@export var active: bool = false

@onready var original_size = size

func _process(_delta: float) -> void:
	%Label.text = str(value)
	if not active:
		size = original_size * 0.75
	else:
		size = original_size
