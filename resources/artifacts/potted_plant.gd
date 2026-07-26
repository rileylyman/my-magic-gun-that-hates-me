extends Artifact

var days := 0
func hand_submit_callback(_state: TickState) -> void:
	days=0

func post_tick_callback(state: TickState) -> void:
	if state.should_fire:
		if(days>1):
			state.score *= days
		
		
			await shake("x"+str(days))
			days = 1
	else:
		days += 1
		shake_no_sound()
