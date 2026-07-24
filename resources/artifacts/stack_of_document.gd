extends Artifact

func hand_submit_callback(state: TickState) -> void:
	state.bonus_score += 100
