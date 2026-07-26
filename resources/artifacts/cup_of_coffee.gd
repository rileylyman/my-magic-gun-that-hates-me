extends Artifact

func post_tick_callback(state: TickState) -> void:
	var total := 0

	for c in state.cards:
		total += c.curr

	if total >= 10 and state.score > 0:
		state.score *= total
		await shake("x"+str(total))
