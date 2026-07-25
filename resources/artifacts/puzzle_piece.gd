extends Artifact

func hand_submit_callback(state: TickState) -> void:
	for i in range(state.cards.size()):
		for j in range(i + 1, state.cards.size()):
			var target = state.cards[i].max_value + state.cards[j].max_value
			for k in range(state.cards.size()):
				if k == i or k == j:
					continue
				if  state.cards[k].max_value == target:
					state.cards[j].max_value = target
					state.cards[i].max_value = target
					state.cards[i].curr = target
					state.cards[j].curr = target
				
