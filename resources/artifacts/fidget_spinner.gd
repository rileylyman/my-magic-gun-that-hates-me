extends Artifact

func post_tick_callback(state: TickState) -> void:
	var hit = 1
	for i in range(state.cards.size()):
		for j in range(state.cards.size()):
			for k in range(state.cards.size()):
				if i == j or i == k or j == k:
					continue
				if state.cards[i].max_value == state.cards[j].max_value and state.cards[i].max_value == state.cards[k].max_value and state.cards[i].curr <= 0 and state.cards[j].curr <= 0 and state.cards[k].curr <= 0:
					hit = max(hit, state.cards[i].max_value)
	if hit > 1:
		state.score *= hit * 3
		await shake("x"+str(hit))

func _post_tick_callback(state: TickState) -> void:
	var x = 0
	var y = 0
	var z = 0
	var hit = 1
	for c in state.cards:
		for i in state.cards:
			for r in state.cards:
				if c.max_value == i.max_value and c.max_value == r.max_value and c.curr <= 0 and r.curr <= 0 and i.curr <= 0 and x != y and x!=z and y!= z:
					hit = c.max_value
				z+=1
			y+=1
		x+=1
	if hit > 1:
		hit *=3
		state.score *= hit
		await shake("x"+str(hit))
