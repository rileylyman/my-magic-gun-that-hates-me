
extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		for other in state.cards:
			if c.max_value == other.max_value * other.max_value:
				if(state.score>0):
					state.score *= 2
					await shake("x2")
