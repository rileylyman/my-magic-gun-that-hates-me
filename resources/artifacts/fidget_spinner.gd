extends Artifact

func post_tick_callback(state: TickState) -> void:
	var dupes = 0
	for c in state.cards:
		for i in state.cards:
			if c.max_value == i.max_value and c.curr == 0:
				dupes += 1
				if dupes == 3:
					state.score *= c.max_value * 3
