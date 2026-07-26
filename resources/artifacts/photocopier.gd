extends Artifact


func hand_submit_callback(state: TickState) -> void:
	if state.cards.size() == 1:
		await shake(" Copied! ")
		var card = state.cards[0].duplicate()
		state.gm.add_to_hand(card)
