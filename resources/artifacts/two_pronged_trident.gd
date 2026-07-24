extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value == 2:
			state.score_mult *= 2
