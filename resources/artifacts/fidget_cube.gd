extends Artifact

func post_tick_callback(state: TickState) -> void:
	var hits = []
	for c in state.cards:
		for i in state.cards:
			if c == i:
				continue
			if c.max_value == i.max_value and c.curr <= 0 and i.curr <= 0:
				if !hits.has(c.max_value):
					hits.append(c.max_value)

	if hits.is_empty():
		return

	var hit = 1
	for value in hits:
		hit *= value

	state.score *= hit
	await shake("x"+str(hit))
