class_name Rotted
extends EnemyDebuff


func when_hit_callback(state: TickState) -> void:
	if GlobalManager.enemy == null:
		return

	var total_damage: int = (
		state.score
		+ state.bonus_score
	)

	var minimum_damage: float = (
		float(GlobalManager.enemy.health)
		* 0.1
	)

	if float(total_damage) < minimum_damage:
		state.score = 0
		state.bonus_score = 0
