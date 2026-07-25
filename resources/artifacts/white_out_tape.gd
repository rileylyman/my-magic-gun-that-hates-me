extends Artifact
func post_tick_callback(state: TickState) -> void:
	if state.cards[0].curr <= 0:
		for c in state.cards:
			c.curr = c.max_value
			await shake(" White out! ")
