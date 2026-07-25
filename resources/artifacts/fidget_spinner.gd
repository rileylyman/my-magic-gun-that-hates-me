extends Artifact

func post_tick_callback(state: TickState) -> void:
	var hit = 1
	for i in range(state.cards.size()):
		for j in range(state.cards.size()):
			for k in range(state.cards.size()):
				if i == j or i == k or j == k:
					continue
				if state.cards[i].max_value == state.cards[j].max_value and state.cards[i].max_value == state.cards[k].max_value and state.cards[i].curr <= 0 and state.cards[j].curr <= 0 and state.cards[k].curr <= 0:
					hit = max(hit, state.cards[i].max_value)
	if hit > 1:
		state.score *= hit
		await shake("x"+str(hit))
