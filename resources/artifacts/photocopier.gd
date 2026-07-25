extends Artifact


func hand_submit_callback(state: TickState) -> void:
	if state.cards.size() == 1:
		state.gm.add_to_hand(state.cards[0])
		#state.gm.hand.append(state.cards[0])
		#state.gm.%HandPos.add_child(state.cards[0])
