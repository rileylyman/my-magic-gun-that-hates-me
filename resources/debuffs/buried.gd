class_name Buried
extends EnemyDebuff

var frozen_card: Card


func counter_start_callback(
	_counter: Counter,
	state: TickState
) -> void:
	frozen_card = null

	if state.cards.is_empty():
		return

	var lowest_value: int = state.cards[0].max_value
	var lowest_cards: Array[Card] = []

	for card in state.cards:
		if card.max_value < lowest_value:
			lowest_value = card.max_value
			lowest_cards.clear()
			lowest_cards.append(card)
		elif card.max_value == lowest_value:
			lowest_cards.append(card)

	frozen_card = lowest_cards.pick_random()


func pre_tick_callback(state: TickState) -> void:
	if (
		frozen_card == null
		or not is_instance_valid(frozen_card)
		or frozen_card not in state.cards
	):
		return

	frozen_card.curr += 1
