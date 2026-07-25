extends Artifact


func hand_submit_callback(state: TickState) -> void:
	if state.cards.size() == 1:
		state.gm.add_to_hand(state.cards[0])
