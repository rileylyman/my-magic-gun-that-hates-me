extends Artifact

func hand_submit_callback(state: TickState) -> void:
	
	state.gm.active_counter.value +=5
	await shake("+5 Days")
