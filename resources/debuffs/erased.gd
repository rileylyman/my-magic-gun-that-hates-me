class_name Erased
extends EnemyDebuff


func counter_start_callback(
	_counter: Counter,
	state: TickState
) -> void:
	var candidates: Array[Card] = []

	for card in state.cards:
		if card != null and card.max_value > 1:
			candidates.append(card)

	if candidates.is_empty():
		return

	var affected_card: Card = candidates.pick_random()

	affected_card.max_value -= 1
	affected_card.curr = affected_card.max_value
	affected_card.update_number_feature()
