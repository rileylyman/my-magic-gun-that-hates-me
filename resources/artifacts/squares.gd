
extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		for other in state.cards:
			if c.max_value == other.max_value * other.max_value:
				state.score *= 2
