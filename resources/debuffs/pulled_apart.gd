class_name PulledApart
extends EnemyDebuff

var number_of_jammed: int = 0


func battle_start_callback(
	_manager: GameManager
) -> void:
	number_of_jammed = 0


func when_hit_callback(
	state: TickState
) -> void:
	if number_of_jammed >= 3:
		return
	if state.today_fired_cards.size() == 2:
		number_of_jammed += 1
		state.score *= 0
		state.bonus_score *= 0
