extends Artifact
var tickcounts = []
func pre_tick_callback(state: TickState) -> void:
	var index = 0
	var index2 = 0
	for c in state.cards:
		for i in tickcounts:
			if i and index != index2:
				c.curr -= 1
			index2 += 1
		index +=1
	#print(tickcounts)
	tickcounts.clear()
	for c in state.cards:
		if c.curr <= 1:
			tickcounts.append(true)
		else:
			tickcounts.append(false)
