extends Artifact

func pre_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value > 9:
			shake_no_sound()
			c.curr -= 2
