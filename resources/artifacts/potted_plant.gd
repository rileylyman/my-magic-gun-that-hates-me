extends Artifact

var days := 1

func post_tick_callback(state: TickState) -> void:
	if state.should_fire:
		state.score *= days
		
		await shake("x"+str(days))
		days = 1
	else:
		days += 1
