class_name Scibbled
extends EnemyDebuff


func counter_start_callback(
	_counter: Counter,
	state: TickState
) -> void:
	if state.cards.is_empty():
		return

	var affected_card: Card = state.cards.pick_random()

	if affected_card == null:
		return

	affected_card.max_value = randi_range(2, 13)
	affected_card.curr = affected_card.max_value
	affected_card.update_number_feature()
	await shake(" Scribbled! ")
