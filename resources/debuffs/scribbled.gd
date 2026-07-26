class_name Scribbled
extends EnemyDebuff

var number_of_jammed: int = 0

func counter_start_callback(
	counter: Counter
) -> void:
	pass

func battle_start_callback(
	_manager: GameManager
) -> void:
	number_of_jammed = 0


func when_hit_callback(
	state: TickState
) -> void:
	if number_of_jammed >= 3:
		return

	number_of_jammed += 1
	state.score *= 0
	state.bonus_score *= 0
