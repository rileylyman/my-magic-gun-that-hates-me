extends Artifact
var round = 0
func post_tick_callback(state: TickState) -> void:
	state.score *= round


func hand_submit_callback(state: TickState) -> void:
	round += 1


func encounter_start_callback() -> void:
	round = 0
