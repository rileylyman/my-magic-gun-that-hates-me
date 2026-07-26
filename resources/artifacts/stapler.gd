extends Artifact

var multiplier := 1.0

func update_description() -> void:
	description = "Multiply all Damage by " + str(multiplier) + ". At the start of a Round, if two played Cards have the same Max Value, increase this multiplier by 0.2 permanently."

func _ready() -> void:
	update_description()


#only triggers once per sprint, which is what the written effect is
func hand_submit_callback(state: TickState) -> void:
	for i in range(state.cards.size()):
		for j in range(i + 1, state.cards.size()):
			if state.cards[i].max_value == state.cards[j].max_value:
				multiplier += 0.2
				multiplier = snappedf(multiplier, 0.1)
				update_description()
				await shake("+0.2 Mult")
				return

func post_tick_callback(state: TickState) -> void:
	if(state.score>0&&multiplier!=1.0):
		state.score *= multiplier
		await shake("x"+str(multiplier))
	
