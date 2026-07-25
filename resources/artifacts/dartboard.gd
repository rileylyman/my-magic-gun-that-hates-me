extends Artifact
var hightar = 15
var lowtar = 5
var target = randi_range(lowtar, hightar)
var hits = 0
var hashit = false
func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.curr <= 0:
			hits +=1
	if  hits >= target and !hashit:
			state.score *= target
			await shake("x" + target)
			hashit = true
	
	if state.days == 1:
		target = randi_range(lowtar, hightar)
		await shake()
		await shake(" Tagret: " + target + " ")

func hand_submit_callback(_state: TickState) -> void:
	hits = 0
	hashit = false
