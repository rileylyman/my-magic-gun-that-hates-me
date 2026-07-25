extends Artifact

func hand_submit_callback(state: TickState) -> void:
	state.score += 100
