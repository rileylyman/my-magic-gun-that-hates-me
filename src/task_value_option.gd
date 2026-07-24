class_name TaskValueOption
extends Resource

@export var value: int = 0

@export_range(0.0, 100.0, 0.01, "or_greater")
var weight: float = 1.0
