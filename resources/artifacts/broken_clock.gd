extends Artifact

func pre_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value % 2 == 1:
			if state.days % 2 == 1:
				c.curr -= 1
				await shake_no_sound()
			if state.days % 2 == 0:
				c.curr += 1
		if c.max_value % 2 == 0:
			if state.days % 2 == 0:
				c.curr -= 1
				await shake_no_sound()
			if state.days % 2 == 1:
				c.curr += 1
