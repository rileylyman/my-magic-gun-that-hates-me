extends Artifact
var min = 0
func post_tick_callback(state: TickState) -> void:
	min =  100000000000000000
	for c in state.hand:
		if c.max_value < min:
			min = c.max_value
	state.score_mult *= min
