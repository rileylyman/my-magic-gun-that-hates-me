extends Artifact

func pre_tick_callback(state: TickState) -> void:
	state.cards[-1].curr +=  1
