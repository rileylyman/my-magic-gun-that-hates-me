extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.curr > 0:
			return
	state.score
