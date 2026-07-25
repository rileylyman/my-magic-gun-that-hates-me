extends Artifact

func pre_tick_callback(state: TickState) -> void:
	state.cards[-1].curr =  state.cards[-1].max_value+1
	shake()
