extends Artifact


#maybe resets each new sprint?

var stacks := 0
func hand_submit_callback(state: TickState) -> void:
	stacks = 0




func post_tick_callback(state: TickState) -> void:
	var fired := 0

	for c in state.cards:
		if c.curr <= 0:
			fired += 1

	if fired == 1:
		if stacks > 0:
			state.score *= pow(2, stacks)
		stacks += 1

	elif fired >= 2:
		stacks = 0
