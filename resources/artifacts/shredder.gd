extends Artifact

func post_tick_callback(state: TickState) -> void:
	if state.cards[-1].curr <= 0:
		if(state.score>0):
			state.score *= 3
			await shake("x3")
		
	if state.days == 1:
		GlobalManager.deck.erase(state.cards[-1])
		await shake(" Shredded! ")

	
