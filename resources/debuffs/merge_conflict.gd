class_name MergeConflicted
extends EnemyDebuff

func when_hit_callback(state: TickState) -> void:
	var blocked_cards: Array[Card] = []

	for card in state.today_fired_cards:
		if card.max_value % 3 == 0:
			blocked_cards.append(card)

	if blocked_cards.is_empty():
		return

	if blocked_cards.size() == state.today_fired_cards.size():
		state.score = 0
		await shake(" Conflicted! ")
		return

	for card in blocked_cards:
		if card.max_value == 0:
			state.score = 0
			await shake(" Conflicted! ")
			return

		state.score = roundi(
			float(state.score)
			/ float(card.max_value)
		)
