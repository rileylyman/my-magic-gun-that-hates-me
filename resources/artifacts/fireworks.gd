extends Artifact

func post_tick_callback(state: TickState) -> void:
	if  state.days == 1:
			state.score *= 4
