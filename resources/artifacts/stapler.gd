extends Artifact

var multiplier := 1.0

func update_description() -> void:
	description = "Multiply all Damage by " + str(multiplier) + ". At the start of a Sprint, if two played Tasks are the same value, improve this multiplier by 0.2 permanently."

func _ready() -> void:
	update_description()


#only triggers once per sprint, which is what the written effect is
func hand_submit_callback(state: TickState) -> void:
	for i in range(state.cards.size()):
		for j in range(i + 1, state.cards.size()):
			if state.cards[i].max_value == state.cards[j].max_value:
				multiplier += 0.2
				update_description()
				return

func post_tick_callback(state: TickState) -> void:
	state.score *= multiplier
