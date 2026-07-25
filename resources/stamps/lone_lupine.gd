extends Stamp
var i = 0

func when_hit_callback(state: TickState) -> void:
	i = 0
	for c in state.cards:
		if c.curr <= 0:
			i = i +1
	if i == 1:
		state.score_mult *= 3
