extends Artifact

func post_tick_callback(state: TickState) -> void:
	if state.gm.active_counter_index == state.gm.counters.size() - 1:
		if(state.score>0):
			
			state.score *= 3
			await shake("x3")
