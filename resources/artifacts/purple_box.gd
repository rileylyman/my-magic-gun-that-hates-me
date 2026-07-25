extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.max_value < 0:
			return
		var root: int = int(sqrt(c.max_value))
		if root * root == c.max_value:
			if(state.score>0):
				state.score *= c.max_value
				await shake("x"+str(c.max_value))
