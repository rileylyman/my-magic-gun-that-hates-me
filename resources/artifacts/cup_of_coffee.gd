extends Artifact

func post_tick_callback(state: TickState) -> void:
	var total := 0

	for c in state.cards:
		total += c.curr

	if total >= 10:
		await shake("x"+str(total))
		state.score *= total
