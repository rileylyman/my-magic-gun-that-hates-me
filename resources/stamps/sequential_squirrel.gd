extends Stamp

func when_hit_callback(state: TickState) -> void:
	if state.current_card == null:
		return

	for previous_card in state.previous_day_fired_cards:
		if previous_card != state.current_card:
			state.score *= 3
			return
