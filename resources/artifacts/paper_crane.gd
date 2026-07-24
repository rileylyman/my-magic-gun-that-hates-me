class_name PaperCrane
extends Artifact

func post_tick_callback(state: TickState) -> void:
	var firing_cards = state.cards.filter(func(c): return c.curr <= 0)
	if firing_cards.size() == 1:
		firing_cards[0].max_value += 1
