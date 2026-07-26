class_name HotDogged
extends EnemyDebuff


func when_hit_callback(state: TickState) -> void:
	if state.score <= 0:
		return

	for card in state.cards:
		if card in state.today_fired_cards:
			continue

		card.curr = mini(
			card.curr + 1,
			card.max_value
		)
		await shake(" GET DAWG'D! ")
