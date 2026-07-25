extends Artifact
var working = false
func post_tick_callback(state: TickState) -> void:
	if working:
		state.score *= 2
	for c in state.cards:
		if c.curr > 0:
			return
	working = true
