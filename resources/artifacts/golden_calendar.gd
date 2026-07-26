extends Artifact
var i = 0
var cd = 0
func post_tick_callback(state: TickState) -> void:
	i = 0
	for c in state.cards:
		if c.curr <= 0:
			i = i +1
	if i == 1:
		cd += 1
	if cd == 2:
		state.gm.active_counter.value +=1
		await shake("+1 Tick")
		cd = 0

func hand_submit_callback(_state: TickState) -> void:
	cd = 0
