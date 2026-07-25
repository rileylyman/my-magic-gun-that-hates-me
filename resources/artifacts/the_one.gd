extends Artifact

func hand_submit_callback(state: TickState) -> void:
	state.cards[0].max_value = 1
	state.cards[0].curr = 1
