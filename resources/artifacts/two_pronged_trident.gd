extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value == 2 and c.curr == 0:
			state.score *= 2
