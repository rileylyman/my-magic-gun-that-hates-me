extends Artifact

func post_tick_callback(state: TickState) -> void:
	var x = 0
	var y = 0
	var hits = []
	var hit = 0
	for c in state.cards:
		
		for i in state.cards:
			if c.max_value == i.max_value and c.curr <= 0 and x != y and i.curr <= 0:
				if !hits.has(c.max_value):
					hits.append(c.max_value)

			y +=1
		x+=1
	for c in hits:
			hit += 2
	if hit > 0:
		state.score *= hit
		await shake("x"+str(hit))
