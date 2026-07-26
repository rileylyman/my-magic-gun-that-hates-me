extends Artifact

func post_tick_callback(state: TickState) -> void:
	var sorted_array: Array[int] = []
	for card in state.cards:
		sorted_array.append(card.max_value)
	sorted_array.sort()

	for i in range(sorted_array.size() - 1):
		if abs(sorted_array[i+1] - sorted_array[i]) < 2:
			return
			
	if(state.score > 0):
		state.score *= 4
		await shake("x4")
