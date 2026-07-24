extends Artifact

func post_tick_callback(state: TickState) -> void:
	for f in state.cards:
		if f.curr == 5:
			state.score *= 5
