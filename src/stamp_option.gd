class_name StampOption
extends Resource

@export var stamp_scene: PackedScene

@export_range(0.0, 100.0, 0.01, "or_greater")
var weight: float = 1.0
