extends Artifact
var fires = 0
func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.curr <= 0:
			fires +=1
			if fires >= 50:
				#Code to transform this to some other legendary
				return
