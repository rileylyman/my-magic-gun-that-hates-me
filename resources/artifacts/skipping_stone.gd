extends Artifact

func pre_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value % 2 == 1:
			c.curr -= 1
