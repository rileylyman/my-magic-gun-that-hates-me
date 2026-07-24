class_name ActiveEnemyDebuff
extends RefCounted

var debuff: EnemyDebuff
var counter_index: int = -1


func applies_to_counter(current_counter_index: int) -> bool:
	if debuff == null:
		return false

	if debuff.scope == EnemyDebuff.Scope.GLOBAL:
		return true

	return counter_index == current_counter_index
