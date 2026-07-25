extends Stamp

func pre_tick_callback(state: TickState) -> void:
	if state.current_card == null:
		return
	state.score = state.score + 5
