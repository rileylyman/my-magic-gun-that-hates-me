extends Artifact
var round = 0
func post_tick_callback(state: TickState) -> void:
	if(state.score>0&&round!=1):
		state.score *= round
		await shake("x"+str(round))


func hand_submit_callback(state: TickState) -> void:
	round += 1


func encounter_start_callback() -> void:
	round = 0
