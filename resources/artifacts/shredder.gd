extends Artifact

func post_tick_callback(state: TickState) -> void:
	if state.cards[-1].curr <= 0:
		state.score *= 3
	if state.days == 1:
		GlobalManager.deck.erase(state.cards[-1])

	
