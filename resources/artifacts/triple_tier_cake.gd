extends Artifact

func post_tick_callback(state: TickState) -> void:
	if state.cards.size() < 3:
		return

	var values := []

	for c in state.cards:
		values.append(c.curr)

	values.sort()

	for i in range(values.size() - 2):
		if (values[i + 1] == values[i] + 1 and values[i + 2] == values[i + 1] + 1):
			state.score += (values[i] + values[i + 1] + values[i + 2]) * 2
			await shake("+"+str((values[i] + values[i + 1] + values[i + 2]) * 2))
			return
