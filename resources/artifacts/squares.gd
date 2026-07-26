
extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		for other in state.cards:
			if c == other:
				continue
			if c.max_value == other.max_value * other.max_value:
				if(state.score>0 and c.curr <= 0 and other.curr <= 0):
					state.score *= 3
					await shake("x3")
