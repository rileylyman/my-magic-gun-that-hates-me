class_name EnemyDebuffOption
extends Resource

@export var debuff: EnemyDebuff

@export_range(0.0, 100.0, 0.01, "or_greater")
var weight: float = 1.0

@export var possible_counter_indices: Array[int] = []
