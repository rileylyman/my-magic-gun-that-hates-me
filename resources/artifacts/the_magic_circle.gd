extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.curr <= 0:
			return

	if(state.score>0):
		state.score *= state.score
		await shake("x" + str(state.score))
