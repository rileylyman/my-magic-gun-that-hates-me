extends Artifact

func post_tick_callback(state: TickState) -> void:
	for f in state.cards:
		if f.curr == 5:
			if(state.score>0):
				state.score *= 5
				await shake("x5")
